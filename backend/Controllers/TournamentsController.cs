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

    [HttpGet("my-history")]
    public async Task<ActionResult<IEnumerable<Tournament>>> GetMyTournaments()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return Unauthorized();

        // Join Tournament and TournamentParticipants
        var tournaments = await _context.Tournaments
            .Include(t => t.Participants)
            .Where(t => t.Participants.Any(p => p.MemberId == userId))
            .OrderByDescending(t => t.StartDate)
            .ToListAsync();
            
        return Ok(tournaments);
    }

    // Endpoint để seed dữ liệu mẫu (chỉ dùng cho dev/testing)
    [HttpPost("seed")]
    public async Task<IActionResult> SeedTournaments()
    {
        if (await _context.Tournaments.AnyAsync())
        {
            return Ok(new { Message = "Tournaments đã tồn tại", Count = await _context.Tournaments.CountAsync() });
        }

        var tournaments = new List<Tournament>
        {
            new Tournament
            {
                Name = "Summer Open 2026",
                Description = "Giải đấu mùa hè 2026 - Đã kết thúc",
                StartDate = DateTime.UtcNow.AddMonths(-2),
                EndDate = DateTime.UtcNow.AddMonths(-2).AddDays(3),
                Format = TournamentFormat.RoundRobin,
                EntryFee = 500000,
                PrizePool = 10000000,
                Status = TournamentStatus.Finished
            },
            new Tournament
            {
                Name = "Winter Cup 2026",
                Description = "Giải đấu lớn nhất năm - Đang mở đăng ký!",
                StartDate = DateTime.UtcNow.AddDays(7),
                EndDate = DateTime.UtcNow.AddDays(14),
                Format = TournamentFormat.Knockout,
                EntryFee = 700000,
                PrizePool = 20000000,
                Status = TournamentStatus.Open
            },
            new Tournament
            {
                Name = "Spring Championship",
                Description = "Giải vô địch mùa xuân",
                StartDate = DateTime.UtcNow.AddMonths(2),
                EndDate = DateTime.UtcNow.AddMonths(2).AddDays(5),
                Format = TournamentFormat.Knockout,
                EntryFee = 300000,
                PrizePool = 5000000,
                Status = TournamentStatus.Registering
            }
        };

        _context.Tournaments.AddRange(tournaments);
        await _context.SaveChangesAsync();

        return Ok(new { Message = "Đã tạo 3 giải đấu mẫu!", Count = tournaments.Count });
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
        var tournament = await _context.Tournaments.Include(t => t.Participants).FirstOrDefaultAsync(t => t.Id == id);
        if (tournament == null) return NotFound();

        // Check Matches
        if (await _context.Matches.AnyAsync(m => m.TournamentId == id))
             return BadRequest("Lịch thi đấu đã được tạo.");

        var participants = tournament.Participants.ToList();
        if (participants.Count < 2) return BadRequest("Cần ít nhất 2 người chơi.");

        // Clean & Shuffle
        participants = participants.OrderBy(x => Guid.NewGuid()).ToList();

        if (tournament.Format == TournamentFormat.Knockout)
        {
             // Create Round 1
             int matchCount = participants.Count / 2;
             for (int i = 0; i < matchCount * 2; i += 2)
             {
                 _context.Matches.Add(new Match
                 {
                    TournamentId = id,
                    RoundName = "Round 1",
                    Team1_Player1Id = participants[i].MemberId,
                    Team2_Player1Id = participants[i+1].MemberId, // Assuming Singles for simplicity. If Doubles, need Team logic.
                    Date = tournament.StartDate,
                    Status = MatchStatus.Scheduled
                 });
             }
             // Handle Bye (Odd number) -> Push to Round 2 (Not implemented simple version)
        }
        else // Round Robin
        {
            for (int i = 0; i < participants.Count; i++)
            {
                for (int j = i + 1; j < participants.Count; j++)
                {
                    _context.Matches.Add(new Match
                    {
                        TournamentId = id,
                        RoundName = "Group Stage",
                        Team1_Player1Id = participants[i].MemberId,
                        Team2_Player1Id = participants[j].MemberId,
                        Date = tournament.StartDate.AddHours(i), // Stagger time
                        Status = MatchStatus.Scheduled
                    });
                }
            }
        }
        
        tournament.Status = TournamentStatus.Ongoing;
        await _context.SaveChangesAsync();

        return Ok(new { Status = "Success", Message = $"Đã tạo lịch thi đấu ({tournament.Format})." });
    }
    [HttpPost("{id}/finish")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> FinishTournament(int id, [FromBody] string winnerId)
    {
        var tournament = await _context.Tournaments.FindAsync(id);
        if (tournament == null) return NotFound();

        if (tournament.Status == TournamentStatus.Finished) 
            return BadRequest("Giải đấu đã kết thúc.");

        var winner = await _userManager.FindByIdAsync(winnerId);
        if (winner == null) return NotFound("Không tìm thấy người thắng cuộc.");

        // Transactional Reward
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            // Award Prize
            winner.WalletBalance += tournament.PrizePool;
            
            var walletTx = new WalletTransaction
            {
                MemberId = winnerId,
                Amount = tournament.PrizePool,
                Type = WalletTransactionType.Reward,
                Status = TransactionStatus.Completed,
                Description = $"Thưởng giải đấu {tournament.Name}",
                RelatedId = tournament.Id.ToString(),
                CreatedDate = DateTime.UtcNow
            };
            _context.WalletTransactions.Add(walletTx);

            tournament.Status = TournamentStatus.Finished;
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            return Ok(new { Status = "Success", Message = $"Đã trao giải thưởng {tournament.PrizePool:N0}đ cho {winner.FullName}." });
        }
        catch(Exception ex)
        {
            await transaction.RollbackAsync();
            return StatusCode(500, "Lỗi: " + ex.Message);
        }
    }
}
