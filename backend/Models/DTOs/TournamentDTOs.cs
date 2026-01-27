using System.ComponentModel.DataAnnotations;

namespace PCM.Backend.Models.DTOs;

public class CreateTournamentDto
{
    [Required]
    public string Name { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public TournamentFormat Format { get; set; }
    public decimal EntryFee { get; set; }
    public decimal PrizePool { get; set; }
}

public class MatchResultDto
{
    public int Score1 { get; set; }
    public int Score2 { get; set; }
    public string? Details { get; set; }
    public WinningSide Winner { get; set; }
}
