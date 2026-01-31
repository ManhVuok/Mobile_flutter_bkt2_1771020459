using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PCM.Backend.Data;
using PCM.Backend.Models;
using PCM.Backend.Models.DTOs;
using System.Security.Claims;
using Microsoft.AspNetCore.SignalR;

namespace PCM.Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class WalletController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<Member> _userManager;
    private readonly Microsoft.AspNetCore.SignalR.IHubContext<PCM.Backend.Hubs.PcmHub> _hubContext;

    public WalletController(ApplicationDbContext context, UserManager<Member> userManager, Microsoft.AspNetCore.SignalR.IHubContext<PCM.Backend.Hubs.PcmHub> hubContext)
    {
        _context = context;
        _userManager = userManager;
        _hubContext = hubContext;
    }

    [HttpGet("transactions")]
    public async Task<ActionResult<IEnumerable<WalletTransactionDto>>> GetMyTransactions()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return Unauthorized();

        var transactions = await _context.WalletTransactions
            .Where(t => t.MemberId == userId)
            .OrderByDescending(t => t.CreatedDate)
            .Select(t => new WalletTransactionDto
            {
                Id = t.Id,
                Amount = t.Amount,
                Type = t.Type.ToString(),
                Status = t.Status.ToString(),
                Description = t.Description,
                CreatedDate = t.CreatedDate
            })
            .ToListAsync();

        return Ok(transactions);
    }

    [HttpGet("all-pending")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<IEnumerable<dynamic>>> GetAllPendingTransactions()
    {
        var transactions = await _context.WalletTransactions
            .Include(t => t.Member)
            .Where(t => t.Status == TransactionStatus.Pending && t.Type == WalletTransactionType.Deposit)
            .OrderByDescending(t => t.CreatedDate)
            .Select(t => new
            {
                t.Id,
                t.Amount,
                t.Description,
                t.CreatedDate,
                FullName = t.Member != null ? t.Member.FullName : "Unknown"
            })
            .ToListAsync();

        return Ok(transactions);
    }
    [HttpGet("balance")]
    public async Task<IActionResult> GetBalance()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return Unauthorized();

        var member = await _context.Users.FindAsync(userId);
        if (member == null) return NotFound();

        return Ok(new { 
            balance = member.WalletBalance, 
            totalSpent = member.TotalSpent, 
            tier = member.Tier.ToString() 
        });
    }

    [HttpPost("deposit")]
    public async Task<IActionResult> Deposit([FromBody] DepositRequestDto model)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return Unauthorized();

        var transaction = new WalletTransaction
        {
            MemberId = userId,
            Amount = model.Amount,
            Type = WalletTransactionType.Deposit,
            Status = TransactionStatus.Pending,
            Description = model.Description ?? "Nạp tiền vào ví",
            ProofImageUrl = model.ProofImageUrl,
            CreatedDate = DateTime.UtcNow
        };

        _context.WalletTransactions.Add(transaction);
        await _context.SaveChangesAsync();

        return Ok(new { Status = "Success", Message = "Yêu cầu nạp tiền đã được gửi. Vui lòng chờ Admin duyệt." });
    }

    [HttpPut("approve/{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ApproveTransaction(int id)
    {
        var transaction = await _context.WalletTransactions.Include(t => t.Member).FirstOrDefaultAsync(t => t.Id == id);
        if (transaction == null) return NotFound();

        if (transaction.Status != TransactionStatus.Pending)
            return BadRequest("Giao dịch này không ở trạng thái chờ duyệt.");

        transaction.Status = TransactionStatus.Completed;
        
        // Update User Wallet
        if (transaction.Member != null)
        {
            transaction.Member.WalletBalance += transaction.Amount;
            
            // Re-calculate Tier (Simple logic)
            if (transaction.Type == WalletTransactionType.Deposit)
            {
                // total spent logic is actually for spending, not depositing. 
                // But tier might be based on top-up often too. 
                // Following requirement: Tier is based on TotalSpent.
            }
        }

        await _context.SaveChangesAsync();

        // Notify User
        await _hubContext.Clients.User(transaction.MemberId).SendAsync("ReceiveNotification", "Yêu cầu nạp tiền của bạn đã được duyệt!");

        return Ok(new { Status = "Success", Message = "Đã duyệt giao dịch thành công." });
    }
    [HttpGet("payment-info")]
    public IActionResult GetPaymentInfo()
    {
        // Mock VietQR String or URL
        var qrUrl = "https://img.vietqr.io/image/MB-0987654321-compact.png";
        return Ok(new { 
            BankName = "MB Bank",
            AccountNumber = "0987654321",
            AccountName = "PCM BADMINTON",
            QrUrl = qrUrl,
            Description = "Nap tien [UserCode]"
        });
    }
    [HttpGet("stats")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetRevenueStats()
    {
        var sixMonthsAgo = DateTime.UtcNow.AddMonths(-5);
        // Ensure we group by date parts
        var data = await _context.Bookings
            .Where(b => b.Status != BookingStatus.Cancelled && b.StartTime >= sixMonthsAgo)
            .ToListAsync(); // Fetch first to avoid complex Linq translation issues with DateTime on some providers

        var stats = data
            .GroupBy(b => new { b.StartTime.Year, b.StartTime.Month })
            .Select(g => new { 
                Year = g.Key.Year, 
                Month = g.Key.Month, 
                Revenue = g.Sum(b => b.TotalPrice) 
            })
            .OrderBy(x => x.Year).ThenBy(x => x.Month)
            .ToList();
            
        return Ok(stats);
    }

    [HttpGet("export-report")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ExportRevenueReport()
    {
        // Get all completed bookings (Revenue)
        var bookings = await _context.Bookings
            .Include(b => b.Member)
            .Include(b => b.Court)
            .Where(b => b.Status != BookingStatus.Cancelled) 
            .OrderByDescending(b => b.StartTime)
            .ToListAsync();

        var csv = new System.Text.StringBuilder();
        csv.AppendLine("Ma Dat San,Khach Hang,San,Ngay,Gio Bat Dau,Thoi Luong,Tong Tien,Trang Thai");

        foreach (var b in bookings)
        {
            var memberName = b.Member != null ? b.Member.FullName : "Unknown";
            var courtName = b.Court != null ? b.Court.Name : "Unknown";
            var status = b.Status.ToString();
            var durationHours = (b.EndTime - b.StartTime).TotalHours;

            csv.AppendLine($"{b.Id},{memberName},{courtName},{b.StartTime:dd/MM/yyyy},{b.StartTime:HH:mm},{durationHours}h,{b.TotalPrice},{status}");
        }

        // Add BOM for Excel to read UTF-8 correctly
        var bytes = System.Text.Encoding.UTF8.GetPreamble().Concat(System.Text.Encoding.UTF8.GetBytes(csv.ToString())).ToArray();
        return File(bytes, "text/csv", $"BaoCaoDoanhThu_{DateTime.Now:yyyyMMdd}.csv");
    }
}
