using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PCM.Backend.Data;
using PCM.Backend.Models;

namespace PCM.Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class NewsController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public NewsController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<News>>> GetNews()
    {
        return await _context.News
            .OrderByDescending(n => n.IsPinned)
            .ThenByDescending(n => n.CreatedDate)
            .ToListAsync();
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<News>> CreateNews(News news)
    {
        news.CreatedDate = DateTime.UtcNow;
        _context.News.Add(news);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetNews), new { id = news.Id }, news);
    }
}
