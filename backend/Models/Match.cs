using System.ComponentModel.DataAnnotations.Schema;

namespace PCM.Backend.Models;

public class Match
{
    public int Id { get; set; }

    public int? TournamentId { get; set; }
    public Tournament? Tournament { get; set; }

    public string RoundName { get; set; } = string.Empty; // "Group A", "Final"
    public DateTime? Date { get; set; }
    public DateTime? StartTime { get; set; }

    // Participants
    public string? Team1_Player1Id { get; set; }
    public Member? Team1_Player1 { get; set; }
    public string? Team1_Player2Id { get; set; } // Optional
    public Member? Team1_Player2 { get; set; }

    public string? Team2_Player1Id { get; set; }
    public Member? Team2_Player1 { get; set; }
    public string? Team2_Player2Id { get; set; } // Optional
    public Member? Team2_Player2 { get; set; }

    // Results
    public int Score1 { get; set; }
    public int Score2 { get; set; }
    public string? Details { get; set; } // JSON or String "11-9, 5-11"
    public WinningSide? Winner { get; set; }

    public bool IsRanked { get; set; }
    public MatchStatus Status { get; set; } = MatchStatus.Scheduled;
}
