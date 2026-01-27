using System.ComponentModel.DataAnnotations.Schema;

namespace PCM.Backend.Models;

public class WalletTransaction
{
    public int Id { get; set; }
    
    public string MemberId { get; set; } = string.Empty;
    public Member? Member { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal Amount { get; set; }

    public WalletTransactionType Type { get; set; }
    public TransactionStatus Status { get; set; }

    public string? RelatedId { get; set; } // ID of Booking or Tournament
    public string? Description { get; set; }
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
     public string? ProofImageUrl { get; set; } // Added for Deposit proof
}
