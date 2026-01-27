using System.ComponentModel.DataAnnotations;

namespace PCM.Backend.Models.DTOs;

public class BookingRequestDto
{
    [Required]
    public int CourtId { get; set; }
    
    [Required]
    public DateTime Date { get; set; } // Only Date part is usually needed if selecting slot, but Full DateTime is safer
    
    [Required]
    public int StartHour { get; set; }
    
    [Required]
    public int DurationHours { get; set; } = 1;
}

public class RecurringBookingRequestDto : BookingRequestDto
{
    [Required]
    public string RecurrenceRule { get; set; } = "Weekly";
    public int Weeks { get; set; } = 4;
    public string DaysOfWeek { get; set; } = ""; // "Tue,Thu"
}
