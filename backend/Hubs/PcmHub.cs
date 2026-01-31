using Microsoft.AspNetCore.SignalR;

namespace PCM.Backend.Hubs;

public class PcmHub : Hub
{
    public async Task SendNotification(string userId, string message)
    {
        await Clients.User(userId).SendAsync("ReceiveNotification", message);
    }

    public async Task UpdateMatchScore(int matchId, int score1, int score2)
    {
        await Clients.Group($"Match_{matchId}").SendAsync("UpdateMatchScore", matchId, score1, score2);
    }
    public async Task UpdateCalendar()
    {
        await Clients.All.SendAsync("UpdateCalendar");
    }

    public async Task JoinMatchGroup(int matchId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"Match_{matchId}");
    }

    public async Task LeaveMatchGroup(int matchId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"Match_{matchId}");
    }

    public async Task SendMessage(int matchId, string senderName, string message)
    {
        await Clients.Group($"Match_{matchId}").SendAsync("ReceiveMessage", senderName, message);
    }
}

