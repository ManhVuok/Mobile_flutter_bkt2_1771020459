using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PCM.Backend.Data;
using PCM.Backend.Models;
using System.Security.Claims;

namespace PCM.Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class MembersController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<Member> _userManager;

    public MembersController(ApplicationDbContext context, UserManager<Member> userManager)
    {
        _context = context;
        _userManager = userManager;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Member>>> GetMembers()
    {
        return await _context.Users
            .Select(u => new Member 
            {
                Id = u.Id,
                FullName = u.FullName,
                Email = u.Email,
                UserName = u.UserName,
                RankLevel = u.RankLevel,
                Tier = u.Tier,
                AvatarUrl = u.AvatarUrl,
                JoinDate = u.JoinDate
            })
            .ToListAsync();
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Member>> GetMember(string id)
    {
        var member = await _context.Users.FindAsync(id);

        if (member == null)
        {
            return NotFound();
        }

        // Return safe data
        return Ok(new 
        {
            member.Id,
            member.FullName,
            member.Email,
            member.RankLevel,
            member.Tier,
            member.AvatarUrl,
            member.JoinDate,
            member.TotalSpent
        });
    }
    
    [HttpGet("me")]
    public async Task<ActionResult<Member>> GetMe()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return Unauthorized();

        var member = await _context.Users.FindAsync(userId);
        if (member == null) return NotFound();

        // Return safe DTO to prevent circular references
        return Ok(new
        {
            member.Id,
            member.FullName,
            member.Email,
            member.UserName,
            member.RankLevel,
            member.Tier,
            member.AvatarUrl,
            member.JoinDate,
            member.WalletBalance,
            member.TotalSpent
        });
    }
}
