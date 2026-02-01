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
    [HttpPost("seed")]
    public async Task<IActionResult> SeedNews()
    {
        // Clear existing news to refresh content
        if (await _context.News.AnyAsync())
        {
            _context.News.RemoveRange(await _context.News.ToListAsync());
            await _context.SaveChangesAsync();
        }

        var newsList = new List<News>
        {
            new News
            {
                Title = "Giải Đấu Mùa Hè 2026 Khởi Tranh!",
                Content = "Chào mừng các tay vợt đến với giải đấu lớn nhất trong năm. Tổng giải thưởng lên đến 50 triệu đồng. Đăng ký ngay để nhận ưu đãi sớm.",
                ImageUrl = "https://images.unsplash.com/photo-1626224583764-847890e045b5?q=80&w=1000&auto=format&fit=crop",
                CreatedDate = DateTime.UtcNow.AddDays(-2),
                IsPinned = true
            },
            new News
            {
                Title = "Khai Trương Sân Số 5 & 6",
                Content = "Để đáp ứng nhu cầu ngày càng tăng, chúng tôi đã hoàn thiện và đưa vào hoạt động thêm 2 sân mới tiêu chuẩn quốc tế. Mặt sân cứng chuẩn thi đấu.",
                ImageUrl = "https://images.unsplash.com/photo-1599586120429-48285b6a8a81?q=80&w=1000&auto=format&fit=crop",
                CreatedDate = DateTime.UtcNow.AddDays(-5),
                IsPinned = false
            },
            new News
            {
                Title = "Ưu Đãi Đặc Biệt Cho Thành Viên Mới",
                Content = "Giảm 20% cho lần đặt sân đầu tiên của thành viên mới đăng ký trong tháng này. Nhập mã NEW20 khi thanh toán.",
                ImageUrl = "https://images.unsplash.com/photo-1591117207239-0889dfe3c316?q=80&w=1000&auto=format&fit=crop",
                CreatedDate = DateTime.UtcNow.AddDays(-10),
                IsPinned = false
            },
            new News
            {
                Title = "Lớp Học Pickleball Cơ Bản - Khóa 12",
                Content = "Bạn mới chơi Pickleball? Tham gia ngay khóa học cơ bản với HLV chuyên nghiệp. Học cách cầm vợt, di chuyển và các kỹ thuật căn bản.",
                ImageUrl = "https://images.unsplash.com/photo-1574629810360-7efbbe195018?q=80&w=1000&auto=format&fit=crop",
                CreatedDate = DateTime.UtcNow.AddDays(-12),
                IsPinned = false
            },
            new News
            {
                Title = "Thông Báo Bảo Trì Hệ Thống Đèn",
                Content = "Chúng tôi sẽ tiến hành bảo trì hệ thống đèn chiếu sáng sân 1 và sân 2 vào ngày 15/05 từ 8:00 đến 12:00. Xin lỗi vì sự bất tiện này.",
                ImageUrl = "https://images.unsplash.com/photo-1554110397-9bac083977c6?q=80&w=1000&auto=format&fit=crop",
                CreatedDate = DateTime.UtcNow.AddDays(-1),
                IsPinned = true
            },
            new News
            {
                Title = "Giao Lưu Cuối Tuần: Thử Thách Đôi Nam Nữ",
                Content = "Cuối tuần này sẽ diễn ra buổi giao lưu dành cho các cặp đôi nam nữ. Không cần đăng ký trước, chỉ cần đến và tham gia.",
                ImageUrl = "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1000&auto=format&fit=crop",
                CreatedDate = DateTime.UtcNow.AddDays(-7),
                IsPinned = false
            }
        };

        _context.News.AddRange(newsList);
        await _context.SaveChangesAsync();

        return Ok(new { Message = "Đã tạo tin tức mẫu!", Count = newsList.Count });
    }
}
