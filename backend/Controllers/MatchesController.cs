using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using PCM.Backend.Data;
using PCM.Backend.Hubs;
using PCM.Backend.Models;
using PCM.Backend.Models.DTOs;

namespace PCM.Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class MatchesController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IHubContext<PcmHub> _hubContext;

    public MatchesController(ApplicationDbContext context, IHubContext<PcmHub> hubContext)
    {
        _context = context;
        _hubContext = hubContext;
    }

    [HttpPost("{id}/result")]
    [Authorize(Roles = "Referee,Admin")] 
    // Assuming Referee role exists, otherwise Admin
    public async Task<IActionResult> UpdateResult(int id, [FromBody] MatchResultDto model)
    {
        var match = await _context.Matches.FindAsync(id);
        if (match == null) return NotFound();

        match.Score1 = model.Score1;
        match.Score2 = model.Score2;
        match.Details = model.Details;
        match.Winner = model.Winner;
        match.Status = MatchStatus.Finished;

        await _context.SaveChangesAsync();

        // Broadcast to Group
        await _hubContext.Clients.Group($"Match_{match.Id}").SendAsync("UpdateMatchScore", match.Id, model.Score1, model.Score2);

        return Ok(new { Status = "Success", Message = "Đã cập nhật kết quả." });
    }
}
