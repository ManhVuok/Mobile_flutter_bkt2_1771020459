using System.ComponentModel.DataAnnotations.Schema;

namespace PCM.Backend.Models;

public class Tournament
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public TournamentFormat Format { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal EntryFee { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal PrizePool { get; set; }

    public TournamentStatus Status { get; set; } = TournamentStatus.Open;

    public string? Description { get; set; } // Mô tả giải đấu
    public string? Settings { get; set; } // JSON string

    public ICollection<TournamentParticipant> Participants { get; set; } = new List<TournamentParticipant>();
    public ICollection<Match> Matches { get; set; } = new List<Match>();
}
