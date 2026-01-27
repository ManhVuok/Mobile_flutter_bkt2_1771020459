namespace PCM.Backend.Models;

public class News
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public bool IsPinned { get; set; }
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public string? ImageUrl { get; set; }
}
