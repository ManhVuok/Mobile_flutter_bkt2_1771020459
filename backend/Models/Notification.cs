namespace PCM.Backend.Models;

public class Notification
{
    public int Id { get; set; }
    
    public string ReceiverId { get; set; } = string.Empty;
    public Member? Receiver { get; set; }

    public string Message { get; set; } = string.Empty;
    public string Type { get; set; } = "Info"; // Info, Success, Warning
    public string? LinkUrl { get; set; }
    public bool IsRead { get; set; }
    public string? RelatedId { get; set; }
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
}
