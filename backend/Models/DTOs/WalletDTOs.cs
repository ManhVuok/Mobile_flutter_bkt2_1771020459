using System.ComponentModel.DataAnnotations;

namespace PCM.Backend.Models.DTOs;

public class DepositRequestDto
{
    [Required]
    [Range(10000, 100000000)]
    public decimal Amount { get; set; }
    
    public string? ProofImageUrl { get; set; }
    public string? Description { get; set; }
}

public class WalletTransactionDto
{
    public int Id { get; set; }
    public decimal Amount { get; set; }
    public string Type { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime CreatedDate { get; set; }
}
