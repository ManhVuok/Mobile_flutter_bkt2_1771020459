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
    public async Task<IActionResult> CreateBooking([FromBody] BookingRequestDto model)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var user = await _userManager.FindByIdAsync(userId!);
        if (user == null) return Unauthorized();

        var court = await _context.Courts.FindAsync(model.CourtId);
        if (court == null) return NotFound("Sân không tồn tại.");

        DateTime startTime = model.Date.Date.AddHours(model.StartHour);
        DateTime endTime = startTime.AddHours(model.DurationHours);

        // 1. Check Availability
        bool isBusy = await _context.Bookings.AnyAsync(b => 
            b.CourtId == model.CourtId && 
            b.Status != BookingStatus.Cancelled &&
            ((b.StartTime < endTime && b.StartTime >= startTime) || 
             (b.EndTime > startTime && b.EndTime <= endTime) ||
             (b.StartTime <= startTime && b.EndTime >= endTime)));

        if (isBusy) return BadRequest("Khung giờ này đã có người đặt.");

        // 2. Check Wallet
        decimal totalPrice = court.PricePerHour * model.DurationHours;
        if (user.WalletBalance < totalPrice)
            return BadRequest($"Số dư không đủ. Cần {totalPrice}, hiện có {user.WalletBalance}.");

        // 3. Process Logic
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            // Trừ tiền
            user.WalletBalance -= totalPrice;
            user.TotalSpent += totalPrice;

            // Update Tier Logic
            if (user.TotalSpent >= 50000000 && user.Tier < MemberTier.Diamond) user.Tier = MemberTier.Diamond;
            else if (user.TotalSpent >= 20000000 && user.Tier < MemberTier.Gold) user.Tier = MemberTier.Gold;
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

            // Link ngược lại (Optional, nếu DB có FK nullable)
            walletTx.RelatedId = booking.Id.ToString();
            await _context.SaveChangesAsync();

            await transaction.CommitAsync();
            
            // Real-time Update
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

    [HttpPost("recurring")]
    [Authorize(Roles = "VIP,Admin")] // Or check Tier >= Gold
    public async Task<IActionResult> CreateRecurringBooking([FromBody] RecurringBookingRequestDto model)
    {
         // Simplified Recurring: Book same time for next 4 weeks
         // Implementation skipped for brevity in this specific turn but framework is:
         // 1. Calculate dates. 
         // 2. Check collision for ALL dates.
         // 3. Calc Total Price.
         // 4. Loop Create Bookings.
         return BadRequest("Feature coming soon (Advanced VIP)");
    }
}

public class RecurringBookingRequestDto : BookingRequestDto
{
    public int Weeks { get; set; } = 4;
}
