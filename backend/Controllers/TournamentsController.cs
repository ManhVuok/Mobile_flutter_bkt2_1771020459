using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PCM.Backend.Data;
using PCM.Backend.Models;
using PCM.Backend.Models.DTOs;
using System.Security.Claims;

namespace PCM.Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class TournamentsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<Member> _userManager;

    public TournamentsController(ApplicationDbContext context, UserManager<Member> userManager)
    {
        _context = context;
        _userManager = userManager;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Tournament>>> GetTournaments()
    {
        return await _context.Tournaments.OrderByDescending(t => t.StartDate).ToListAsync();
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Tournament>> GetTournament(int id)
    {
        var tournament = await _context.Tournaments
            .Include(t => t.Participants)
                .ThenInclude(p => p.Member)
            .Include(t => t.Matches)
                .ThenInclude(m => m.Team1_Player1)
            .Include(t => t.Matches)
                .ThenInclude(m => m.Team1_Player2)
            .Include(t => t.Matches)
                .ThenInclude(m => m.Team2_Player1)
            .Include(t => t.Matches)
                .ThenInclude(m => m.Team2_Player2)
            .FirstOrDefaultAsync(t => t.Id == id);

        if (tournament == null) return NotFound();
        return Ok(tournament);
    }


    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> CreateTournament(CreateTournamentDto model)
    {
        var tournament = new Tournament
        {
            Name = model.Name,
            StartDate = model.StartDate,
            EndDate = model.EndDate,
            Format = model.Format,
            EntryFee = model.EntryFee,
            PrizePool = model.PrizePool,
            Status = TournamentStatus.Open
        };

        _context.Tournaments.Add(tournament);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetTournaments), new { id = tournament.Id }, tournament);
    }

    [HttpPost("{id}/join")]
    [Authorize]
    public async Task<IActionResult> JoinTournament(int id, [FromBody] string? teamName)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var user = await _userManager.FindByIdAsync(userId!);
        if (user == null) return Unauthorized();

        var tournament = await _context.Tournaments.Include(t => t.Participants).FirstOrDefaultAsync(t => t.Id == id);
        if (tournament == null) return NotFound();

        if (tournament.Status != TournamentStatus.Open && tournament.Status != TournamentStatus.Registering)
            return BadRequest("Giải đấu không còn nhận đăng ký.");

        if (tournament.Participants.Any(p => p.MemberId == userId))
            return BadRequest("Bạn đã tham gia giải đấu này rồi.");

        // Check Wallet
        if (user.WalletBalance < tournament.EntryFee)
            return BadRequest($"Số dư không đủ để đóng lệ phí ({tournament.EntryFee}).");

        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            // Trừ tiền
            user.WalletBalance -= tournament.EntryFee;
            user.TotalSpent += tournament.EntryFee;

            var walletTx = new WalletTransaction
            {
                MemberId = userId!,
                Amount = -tournament.EntryFee,
                Type = WalletTransactionType.Payment,
                Status = TransactionStatus.Completed,
                Description = $"Phí tham gia giải {tournament.Name}",
                RelatedId = tournament.Id.ToString(),
                CreatedDate = DateTime.UtcNow
            };
            _context.WalletTransactions.Add(walletTx);

            // Add Participant
            _context.TournamentParticipants.Add(new TournamentParticipant
            {
                TournamentId = id,
                MemberId = userId!,
                TeamName = teamName ?? user.FullName,
                IsPaid = true
            });

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            return Ok(new { Status = "Success", Message = "Đăng ký thành công!" });
        }
        catch (Exception)
        {
            await transaction.RollbackAsync();
            return StatusCode(500, "Lỗi khi xử lý đăng ký.");
        }
    }

    [HttpPost("{id}/generate-schedule")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GenerateSchedule(int id)
    {
        // Simple Dummy Implementation for assignment
        var tournament = await _context.Tournaments.Include(t => t.Participants).FirstOrDefaultAsync(t => t.Id == id);
        if (tournament == null) return NotFound();

        // Check if matches already exist
        if (await _context.Matches.AnyAsync(m => m.TournamentId == id))
             return BadRequest("Lịch thi đấu đã được tạo.");

        var participants = tournament.Participants.ToList();
        if (participants.Count < 2) return BadRequest("Cần ít nhất 2 người chơi.");

        // Create simple Single Elimination or Round Robin pairs
        for (int i = 0; i < participants.Count; i += 2)
        {
            if (i + 1 < participants.Count)
            {
                _context.Matches.Add(new Match
                {
                    TournamentId = id,
                    RoundName = "Round 1",
                    Team1_Player1Id = participants[i].MemberId,
                    Team2_Player1Id = participants[i+1].MemberId,
                    Date = tournament.StartDate,
                    Status = MatchStatus.Scheduled
                });
            }
        }
        
        tournament.Status = TournamentStatus.Ongoing;
        await _context.SaveChangesAsync();

        return Ok(new { Status = "Success", Message = "Đã tạo lịch thi đấu." });
    }
}
