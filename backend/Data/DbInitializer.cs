using Microsoft.AspNetCore.Identity;
using PCM.Backend.Models;

namespace PCM.Backend.Data;

public static class DbInitializer
{
    public static async Task Initialize(ApplicationDbContext context, UserManager<Member> userManager, RoleManager<IdentityRole> roleManager)
    {
        // Ensure database is created
        context.Database.EnsureCreated();

        // Seed Roles
        string[] roles = { "Admin", "Treasurer", "Referee", "Member" };
        foreach (var role in roles)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                await roleManager.CreateAsync(new IdentityRole(role));
            }
        }

        // Seed Admin // Pass: Admin@123
        if (await userManager.FindByEmailAsync("admin@pcm.local") == null)
        {
            var admin = new Member
            {
                UserName = "admin@pcm.local",
                Email = "admin@pcm.local",
                FullName = "System Admin",
                EmailConfirmed = true,
                Tier = MemberTier.Diamond
            };
            await userManager.CreateAsync(admin, "Admin@123");
            await userManager.AddToRoleAsync(admin, "Admin");
        }
        
         // Seed Treasurer // Pass: Admin@123
        if (await userManager.FindByEmailAsync("treasurer@pcm.local") == null)
        {
            var treasurer = new Member
            {
                UserName = "treasurer@pcm.local",
                Email = "treasurer@pcm.local",
                FullName = "Chief Treasurer",
                EmailConfirmed = true,
                Tier = MemberTier.Gold
            };
            await userManager.CreateAsync(treasurer, "Admin@123");
            await userManager.AddToRoleAsync(treasurer, "Treasurer");
        }

        // Seed Members (20 members)
        if (!context.Users.Any(u => u.Email!.Contains("member")))
        {
            var random = new Random();
            for (int i = 1; i <= 20; i++)
            {
                var email = $"member{i}@pcm.local";
                var member = new Member
                {
                    UserName = email,
                    Email = email,
                    FullName = $"Vợt Thủ {i}",
                    EmailConfirmed = true,
                    WalletBalance = random.Next(2000000, 10000000),
                    RankLevel = Math.Round(random.NextDouble() * (5.0 - 2.5) + 2.5, 2), // DUPR 2.5 - 5.0
                    Tier = (MemberTier)random.Next(0, 4)
                };

                await userManager.CreateAsync(member, "Member@123");
                await userManager.AddToRoleAsync(member, "Member");
            }
        }

        // Seed Courts
        if (!context.Courts.Any())
        {
            context.Courts.AddRange(
                new Court { Name = "Sân 1 (Trong nhà)", PricePerHour = 150000 },
                new Court { Name = "Sân 2 (Trong nhà)", PricePerHour = 150000 },
                new Court { Name = "Sân 3 (Ngoài trời)", PricePerHour = 100000 },
                new Court { Name = "Sân 4 (Ngoài trời)", PricePerHour = 100000 }
            );
            await context.SaveChangesAsync();
        }

        // Seed Tournaments
        if (!context.Tournaments.Any())
        {
             // Past Tournament
            var pastTournament = new Tournament
            {
                Name = "Summer Open 2026",
                StartDate = DateTime.UtcNow.AddMonths(-2),
                EndDate = DateTime.UtcNow.AddMonths(-2).AddDays(2),
                Format = TournamentFormat.RoundRobin,
                EntryFee = 500000,
                PrizePool = 10000000,
                Status = TournamentStatus.Finished
            };
            
            // Ongoing/Upcoming
             var upcomingTournament = new Tournament
            {
                Name = "Winter Cup 2026",
                StartDate = DateTime.UtcNow.AddDays(10),
                EndDate = DateTime.UtcNow.AddDays(12),
                Format = TournamentFormat.Knockout,
                EntryFee = 700000,
                PrizePool = 20000000,
                Status = TournamentStatus.Open
            };

            context.Tournaments.AddRange(pastTournament, upcomingTournament);
            await context.SaveChangesAsync();
        }
    }
}
