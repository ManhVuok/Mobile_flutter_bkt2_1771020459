using Microsoft.AspNetCore.Identity;
using System.ComponentModel.DataAnnotations.Schema;

namespace PCM.Backend.Models;

public class Member : IdentityUser
{
    public string FullName { get; set; } = string.Empty;
    public DateTime JoinDate { get; set; } = DateTime.UtcNow;
    public double RankLevel { get; set; } = 1.0; // DUPR
    public bool IsActive { get; set; } = true;

    [Column(TypeName = "decimal(18,2)")]
    public decimal WalletBalance { get; set; } = 0;

    public MemberTier Tier { get; set; } = MemberTier.Standard;

    [Column(TypeName = "decimal(18,2)")]
    public decimal TotalSpent { get; set; } = 0;

    public string? AvatarUrl { get; set; }

    // Navigation properties can be added here
}
