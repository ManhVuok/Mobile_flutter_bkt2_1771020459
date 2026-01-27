using System.ComponentModel.DataAnnotations.Schema;

namespace PCM.Backend.Models;

public class Booking
{
    public int Id { get; set; }

    public int CourtId { get; set; }
    public Court? Court { get; set; }

    public string MemberId { get; set; } = string.Empty;
    public Member? Member { get; set; }

    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal TotalPrice { get; set; }

    public int? TransactionId { get; set; } // Link to WalletTransaction if needed, mainly logical link through RelatedId in Transaction

    public bool IsRecurring { get; set; }
    public string? RecurrenceRule { get; set; } // e.g., "Weekly;Tue,Thu"
    public int? ParentBookingId { get; set; }
    public Booking? ParentBooking { get; set; }

    public BookingStatus Status { get; set; } = BookingStatus.PendingPayment;
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
}
