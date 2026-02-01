using System.ComponentModel.DataAnnotations.Schema;

namespace PCM.Backend.Models;

public class Court
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public string? Description { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal PricePerHour { get; set; }

    public string? ImageUrl { get; set; }
}
