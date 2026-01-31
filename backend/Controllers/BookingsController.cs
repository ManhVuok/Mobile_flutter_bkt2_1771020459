using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PCM.Backend.Data;
using PCM.Backend.Models;
using PCM.Backend.Models.DTOs;
using Microsoft.AspNetCore.SignalR;
using PCM.Backend.Hubs;
using System.Security.Claims;

namespace PCM.Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class BookingsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<Member> _userManager;
    private readonly IHubContext<PcmHub> _hubContext;

    public BookingsController(ApplicationDbContext context, UserManager<Member> userManager, IHubContext<PcmHub> hubContext)
    {
        _context = context;
        _userManager = userManager;
        _hubContext = hubContext;
    }

    [HttpGet("calendar")]
    public async Task<ActionResult<IEnumerable<Booking>>> GetCalendar([FromQuery] DateTime from, [FromQuery] DateTime to)
    {
        return await _context.Bookings
            .Include(b => b.Member)
            .Include(b => b.Court)
            .Where(b => b.StartTime >= from && b.EndTime <= to && b.Status != BookingStatus.Cancelled)
            .ToListAsync();
    }

    [HttpPost]
    public async Task<IActionResult> CreateBooking([FromBody] BookingRequestDto model, [FromQuery] bool isHold = false)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var user = await _userManager.FindByIdAsync(userId!);
        if (user == null) return Unauthorized();

        var court = await _context.Courts.FindAsync(model.CourtId);
        if (court == null) return NotFound("Sân không tồn tại.");

        DateTime startTime = model.Date.Date.AddHours(model.StartHour);
        DateTime endTime = startTime.AddHours(model.DurationHours);

        // 1. Check Availability (Including Holding status)
        bool isBusy = await _context.Bookings.AnyAsync(b => 
            b.CourtId == model.CourtId && 
            b.Status != BookingStatus.Cancelled &&
            ((b.StartTime < endTime && b.StartTime >= startTime) || 
             (b.EndTime > startTime && b.EndTime <= endTime) ||
             (b.StartTime <= startTime && b.EndTime >= endTime)));

        if (isBusy) return BadRequest("Khung giờ này đã có người đặt hoặc đang giữ chỗ.");

        decimal totalPrice = court.PricePerHour * model.DurationHours;
        
        // 2. Validate user (even for hold, should have balance?) -> Requirement says just Hold.
        // Let's allow Hold without balance check for now, or check minimal.

        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            if (isHold)
            {
                 // Hold Logic: Create Booking with PendingPayment/Holding status
                 var bookingHold = new Booking
                 {
                    CourtId = model.CourtId,
                    MemberId = userId!,
                    StartTime = startTime,
                    EndTime = endTime,
                    TotalPrice = totalPrice,
                    Status = BookingStatus.PendingPayment, // Treated as Hold
                    CreatedDate = DateTime.UtcNow, // Cleanup service will delete after 5m
                    IsRecurring = false
                 };
                 _context.Bookings.Add(bookingHold);
                 await _context.SaveChangesAsync();
                 await transaction.CommitAsync();
                 await _hubContext.Clients.All.SendAsync("UpdateCalendar");
                 return Ok(new { Status = "Success", Message = "Đang giữ chỗ (5 phút). Vui lòng thanh toán ngay.", BookingId = bookingHold.Id });
            }

            // Normal Setup: Check Balance & Deduct
            if (user.WalletBalance < totalPrice)
                 return BadRequest($"Số dư không đủ. Cần {totalPrice}, hiện có {user.WalletBalance}.");

            // Trừ tiền
            user.WalletBalance -= totalPrice;
            user.TotalSpent += totalPrice;

            // Update Tier Logic
            if (user.TotalSpent >= 50000000 && user.Tier < MemberTier.Diamond) user.Tier = MemberTier.Diamond;
            else if (user.TotalSpent >= 10000000 && user.Tier < MemberTier.Gold) user.Tier = MemberTier.Gold;
            else if (user.TotalSpent >= 5000000 && user.Tier < MemberTier.Silver) user.Tier = MemberTier.Silver;

            // Tạo Transaction Record
            var walletTx = new WalletTransaction
            {
                MemberId = userId!,
                Amount = -totalPrice,
                Type = WalletTransactionType.Payment,
                Status = TransactionStatus.Completed,
                Description = $"Thanh toán đặt sân {court.Name} ({startTime:dd/MM HH:mm})",
                CreatedDate = DateTime.UtcNow
            };
            _context.WalletTransactions.Add(walletTx);
            await _context.SaveChangesAsync();

            // Tạo Booking
            var booking = new Booking
            {
                CourtId = model.CourtId,
                MemberId = userId!,
                StartTime = startTime,
                EndTime = endTime,
                TotalPrice = totalPrice,
                Status = BookingStatus.Confirmed,
                TransactionId = walletTx.Id,
                IsRecurring = false
            };
            _context.Bookings.Add(booking);
            await _context.SaveChangesAsync();

            walletTx.RelatedId = booking.Id.ToString();
            await _context.SaveChangesAsync();

            await transaction.CommitAsync();
            await _hubContext.Clients.All.SendAsync("UpdateCalendar");

            return Ok(new { Status = "Success", Message = "Đặt sân thành công!", BookingId = booking.Id });
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            return StatusCode(500, "Lỗi xử lý: " + ex.Message);
        }
    }

    [HttpPost("cancel/{id}")]
    public async Task<IActionResult> CancelBooking(int id)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        // User can only cancel their own, Admin can cancel any (add Admin check if needed)
        var booking = await _context.Bookings.Include(b => b.Member).Include(b => b.Court).FirstOrDefaultAsync(b => b.Id == id);
        
        if (booking == null) return NotFound();
        if (booking.MemberId != userId && !User.IsInRole("Admin")) return Forbid();
        if (booking.Status == BookingStatus.Cancelled) return BadRequest("Đơn này đã hủy rồi.");

        // Refund Policy: > 24h = 100%, < 24h = 0% (or configurable)
        var hoursBefore = (booking.StartTime - DateTime.UtcNow).TotalHours;
        decimal refundAmount = 0;
        
        if (hoursBefore >= 24) refundAmount = booking.TotalPrice;

        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            booking.Status = BookingStatus.Cancelled;

            if (refundAmount > 0)
            {
                var user = booking.Member!;
                user.WalletBalance += refundAmount;
                user.TotalSpent -= refundAmount; // Reduce total spent if refunded

                var refundTx = new WalletTransaction
                {
                    MemberId = user.Id,
                    Amount = refundAmount,
                    Type = WalletTransactionType.Refund,
                    Status = TransactionStatus.Completed,
                    Description = $"Hoàn tiền hủy sân {booking.Court?.Name} ({booking.StartTime:dd/MM})",
                    RelatedId = booking.Id.ToString(),
                    CreatedDate = DateTime.UtcNow
                };
                _context.WalletTransactions.Add(refundTx);
            }

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            await _hubContext.Clients.All.SendAsync("UpdateCalendar");

            return Ok(new { Status = "Success", Message = $"Đã hủy sân. Hoàn tiền: {refundAmount:N0}đ" });
        }
        catch(Exception ex) 
        {
            await transaction.RollbackAsync();
            return StatusCode(500, ex.Message);
        }
    }

    [HttpGet("my-history")]
    public async Task<ActionResult<IEnumerable<Booking>>> GetMyHistory()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return await _context.Bookings
            .Include(b => b.Court)
            .Where(b => b.MemberId == userId)
            .OrderByDescending(b => b.CreatedDate)
            .ToListAsync();
    }

    [HttpPost("recurring")]
    [Authorize(Roles = "VIP,Admin,Treasurer,Member")] // Allow Member with High Tier? For now VIP. Let's assume VIP role exists.
    public async Task<IActionResult> CreateRecurringBooking([FromBody] RecurringBookingRequestDto model)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var user = await _userManager.FindByIdAsync(userId!);
        if (user == null) return Unauthorized();

        // Validate Tier? 
        if (user.Tier < MemberTier.Gold && !User.IsInRole("Admin")) 
             return BadRequest("Chỉ thành viên Gold/Diamond mới được đặt lịch định kỳ.");

        var court = await _context.Courts.FindAsync(model.CourtId);
        if (court == null) return NotFound("Sân không tồn tại.");

        List<DateTime> targetDates = new List<DateTime>();
        DateTime current = model.Date.Date;
        
        // Parse DaysOfWeek (e.g. "Tue,Thu")
        // Mapping: Sunday=0, Monday=1...
        var targetDays = new List<DayOfWeek>();
        if (!string.IsNullOrEmpty(model.DaysOfWeek))
        {
            var parts = model.DaysOfWeek.Split(',');
            foreach (var p in parts)
            {
                if (Enum.TryParse<DayOfWeek>(p.Trim(), true, out var dow)) targetDays.Add(dow);
            }
        }

        // Generate Dates for N weeks
        for (int i = 0; i < model.Weeks * 7; i++)
        {
            DateTime d = current.AddDays(i);
            if (targetDays.Contains(d.DayOfWeek))
            {
                // Ensure StartTime on that day
                targetDates.Add(d.AddHours(model.StartHour));
            }
        }

        if (targetDates.Count == 0) return BadRequest("Không tìm thấy ngày nào phù hợp.");

        decimal pricePerSlot = court.PricePerHour * model.DurationHours;
        decimal totalPrice = pricePerSlot * targetDates.Count;

        if (user.WalletBalance < totalPrice)
            return BadRequest($"Số dư không đủ. Cần {totalPrice:N0}đ cho {targetDates.Count} buổi.");

        // Transactional Process
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
             // 1. Check Collision for ALL slots
             foreach (var start in targetDates)
             {
                 var end = start.AddHours(model.DurationHours);
                 bool isBusy = await _context.Bookings.AnyAsync(b => 
                    b.CourtId == model.CourtId && 
                    b.Status != BookingStatus.Cancelled &&
                    ((b.StartTime < end && b.StartTime >= start) || 
                     (b.EndTime > start && b.EndTime <= end) ||
                     (b.StartTime <= start && b.EndTime >= end)));
                 
                 if (isBusy) return BadRequest($"Trùng lịch vào ngày {start:dd/MM/yyyy HH:mm}. Vui lòng kiểm tra lại.");
             }

             // 2. Deduct Money
             user.WalletBalance -= totalPrice;
             user.TotalSpent += totalPrice;

             // 3. Create Transaction
             var walletTx = new WalletTransaction
            {
                MemberId = userId!,
                Amount = -totalPrice,
                Type = WalletTransactionType.Payment,
                Status = TransactionStatus.Completed,
                Description = $"Đặt lịch định kỳ {model.Weeks} tuần ({targetDates.Count} buổi) sận {court.Name}",
                CreatedDate = DateTime.UtcNow
            };
            _context.WalletTransactions.Add(walletTx);
            await _context.SaveChangesAsync();

             // 4. Create Parent Booking (First one)
             Booking? parentBooking = null;
             
             foreach(var start in targetDates)
             {
                 var booking = new Booking
                 {
                    CourtId = model.CourtId,
                    MemberId = userId!,
                    StartTime = start,
                    EndTime = start.AddHours(model.DurationHours),
                    TotalPrice = pricePerSlot,
                    Status = BookingStatus.Confirmed,
                    TransactionId = walletTx.Id,
                    IsRecurring = true,
                    RecurrenceRule = $"{model.Weeks} Weeks; {model.DaysOfWeek}",
                    ParentBookingId = parentBooking?.Id 
                 };
                 _context.Bookings.Add(booking);
                 await _context.SaveChangesAsync(); // Need ID for Parent
                 
                 if (parentBooking == null) parentBooking = booking; // Set First as Parent
             }

             walletTx.RelatedId = parentBooking!.Id.ToString();
             await _context.SaveChangesAsync();

             await transaction.CommitAsync();
             await _hubContext.Clients.All.SendAsync("UpdateCalendar");

             return Ok(new { Status = "Success", Message = $"Đã đặt thành công {targetDates.Count} buổi.", TotalPrice = totalPrice });
        }
        catch(Exception ex)
        {
            await transaction.RollbackAsync();
            return StatusCode(500, "Lỗi: " + ex.Message);
        }
    }
}

public class RecurringBookingRequestDto : BookingRequestDto
{
    public int Weeks { get; set; } = 4;
    public string? DaysOfWeek { get; set; } // e.g. "Monday,Wednesday,Friday"
}
