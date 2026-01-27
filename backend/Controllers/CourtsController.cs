using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PCM.Backend.Data;
using PCM.Backend.Models;

namespace PCM.Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class CourtsController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public CourtsController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Court>>> GetCourts()
    {
        return await _context.Courts.Where(c => c.IsActive).ToListAsync();
    }
    
    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> CreateCourt([FromBody] Court court)
    {
        _context.Courts.Add(court);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetCourts), new { id = court.Id }, court);
    }
}
