using System.ComponentModel.DataAnnotations;

namespace PCM.Backend.Models;

public class TransactionCategory
{
    public int Id { get; set; }
    
    [Required]
    public string Name { get; set; } = string.Empty;
    
    [Required]
    public string Type { get; set; } = string.Empty; // "Thu" or "Chi"
}
