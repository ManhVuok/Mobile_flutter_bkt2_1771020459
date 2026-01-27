using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PCM.Backend.Data;

namespace PCM.Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize(Roles = "Admin,Treasurer")]
public class ReportsController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public ReportsController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet("revenue")]
    public async Task<IActionResult> ExportRevenue()
    {
        var transactions = await _context.WalletTransactions
            .Include(t => t.Member)
            .OrderByDescending(t => t.CreatedDate)
            .ToListAsync();

        var csv = new StringBuilder();
        csv.AppendLine("Id,Date,Member,Type,Amount,Status,Description");

        foreach (var t in transactions)
        {
            csv.AppendLine($"{t.Id},{t.CreatedDate:yyyy-MM-dd HH:mm},{t.Member?.FullName},{t.Type},{t.Amount},{t.Status},{t.Description}");
        }

        return File(Encoding.UTF8.GetBytes(csv.ToString()), "text/csv", $"RevenueReport_{DateTime.Now:yyyyMMdd}.csv");
    }

    [HttpGet("members")]
    public async Task<IActionResult> ExportMembers()
    {
        var members = await _context.Users.ToListAsync();

        var csv = new StringBuilder();
        csv.AppendLine("Id,Email,FullName,Tier,Rank,WalletBalance,TotalSpent,JoinDate");

        foreach (var m in members)
        {
            csv.AppendLine($"{m.Id},{m.Email},{m.FullName},{m.Tier},{m.RankLevel},{m.WalletBalance},{m.TotalSpent},{m.JoinDate:yyyy-MM-dd}");
        }

        return File(Encoding.UTF8.GetBytes(csv.ToString()), "text/csv", $"MembersReport_{DateTime.Now:yyyyMMdd}.csv");
    }
}
