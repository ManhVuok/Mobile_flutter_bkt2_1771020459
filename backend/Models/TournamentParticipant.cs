namespace PCM.Backend.Models;

public class TournamentParticipant
{
    public int Id { get; set; }

    public int TournamentId { get; set; }
    public Tournament? Tournament { get; set; }

    public string MemberId { get; set; } = string.Empty;
    public Member? Member { get; set; }

    public string? TeamName { get; set; }
    public bool IsPaid { get; set; } // PaymentStatus
}
