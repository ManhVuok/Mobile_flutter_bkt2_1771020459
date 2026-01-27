using Microsoft.EntityFrameworkCore;
using PCM.Backend.Data;
using PCM.Backend.Models;

namespace PCM.Backend.Services;

public class BookingCleanupService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<BookingCleanupService> _logger;

    public BookingCleanupService(IServiceProvider serviceProvider, ILogger<BookingCleanupService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            _logger.LogInformation("BookingCleanupService running...");

            using (var scope = _serviceProvider.CreateScope())
            {
                var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                
                // 1. Auto-Cancel Unpaid Bookings (> 5 mins)
                var timeout = DateTime.UtcNow.AddMinutes(-5);
                var expiredBookings = await context.Bookings
                    .Where(b => b.Status == BookingStatus.PendingPayment && b.CreatedDate < timeout)
                    .ToListAsync(stoppingToken);

                if (expiredBookings.Any())
                {
                    foreach (var booking in expiredBookings)
                    {
                        booking.Status = BookingStatus.Cancelled;
                        _logger.LogInformation($"Auto-cancelled booking {booking.Id}");
                    }
                    await context.SaveChangesAsync(stoppingToken);
                }

                // 2. Auto-Remind (24h before StartTime)
                // Logic: Find confirmed bookings starting in 23h-24h range that haven't been reminded.
                // For simplicity: Find bookings tomorrow, send noti if not sent. 
                // Since we don't have "IsReminded" flag, we might send duplicates. 
                // Enhanced: Check Notification table to see if Reminder exists for this booking? 
                // Or just keep it simple: StartTime between Now+23h and Now+24h.
                var from = DateTime.UtcNow.AddHours(23);
                var to = DateTime.UtcNow.AddHours(24);
                
                var upcomingBookings = await context.Bookings
                    .Include(b => b.Member)
                    .Where(b => b.Status == BookingStatus.Confirmed && b.StartTime >= from && b.StartTime <= to)
                    .ToListAsync(stoppingToken);

                foreach (var booking in upcomingBookings)
                {
                    // Check duplicate simple (Optional)
                    bool reminded = await context.Notifications.AnyAsync(n => n.RelatedId == booking.Id.ToString() && n.Type == "Reminder");
                    if (!reminded)
                    {
                         context.Notifications.Add(new Notification
                         {
                             ReceiverId = booking.MemberId,
                             Message = $"Nhắc nhở: Bạn có lịch đặt sân {booking.Court?.Name} vào {booking.StartTime:dd/MM HH:mm}",
                             Type = "Reminder",
                             RelatedId = booking.Id.ToString(), // Need to add RelatedId to Notification model or use Description
                             CreatedDate = DateTime.UtcNow
                         });
                    }
                }
                await context.SaveChangesAsync(stoppingToken);
            }

            await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
        }
    }
}
