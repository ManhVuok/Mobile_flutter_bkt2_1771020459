using Microsoft.AspNetCore.Identity;
using PCM.Backend.Models;

namespace PCM.Backend.Data;

/// <summary>
/// Data Seeder - Tạo dữ liệu mẫu theo yêu cầu đề bài:
/// - 1 Admin, 1 Treasurer, 1 Referee
/// - 20 Members với Rank DUPR và Tier khác nhau
/// - Wallet: 2tr - 10tr mỗi thành viên
/// - 1 Giải đấu đã kết thúc, 1 giải đang mở đăng ký
/// </summary>
public static class DbSeeder
{
    public static async Task SeedAsync(IServiceProvider serviceProvider)
    {
        var userManager = serviceProvider.GetRequiredService<UserManager<Member>>();
        var roleManager = serviceProvider.GetRequiredService<RoleManager<IdentityRole>>();
        var context = serviceProvider.GetRequiredService<ApplicationDbContext>();

        // 1. Seed Roles
        string[] roles = { "Admin", "Treasurer", "Referee", "Member" };
        foreach (var role in roles)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                await roleManager.CreateAsync(new IdentityRole(role));
            }
        }

        // 2. Seed Admin
        await CreateUserIfNotExists(userManager, "admin@pcm.vn", "Admin@123", "Admin Vợt Thủ", "Admin", 
            walletBalance: 50000000, tier: MemberTier.Diamond, rankLevel: 5.0);

        // 3. Seed Treasurer
        await CreateUserIfNotExists(userManager, "treasurer@pcm.vn", "Treasurer@123", "Thủ Quỹ PCM", "Treasurer",
            walletBalance: 20000000, tier: MemberTier.Gold, rankLevel: 4.0);

        // 4. Seed Referee
        await CreateUserIfNotExists(userManager, "referee@pcm.vn", "Referee@123", "Trọng Tài Hùng", "Referee",
            walletBalance: 5000000, tier: MemberTier.Silver, rankLevel: 4.5);

        // 5. Seed 20 Members with various Tiers and DUPR
        var memberData = new[]
        {
            ("Nguyễn Văn An", MemberTier.Diamond, 4.8, 10000000m),
            ("Trần Thị Bình", MemberTier.Gold, 4.2, 8000000m),
            ("Lê Hoàng Cường", MemberTier.Gold, 4.0, 7500000m),
            ("Phạm Minh Đức", MemberTier.Silver, 3.5, 5000000m),
            ("Hoàng Thị Em", MemberTier.Silver, 3.2, 4500000m),
            ("Vũ Quang Phong", MemberTier.Silver, 3.8, 6000000m),
            ("Đặng Văn Giang", MemberTier.Standard, 2.5, 2000000m),
            ("Bùi Thị Hà", MemberTier.Standard, 2.8, 2500000m),
            ("Ngô Minh Ích", MemberTier.Gold, 4.1, 9000000m),
            ("Lý Văn Khánh", MemberTier.Diamond, 4.9, 10000000m),
            ("Mai Thị Lan", MemberTier.Silver, 3.6, 5500000m),
            ("Trương Văn Minh", MemberTier.Standard, 3.0, 3000000m),
            ("Đinh Thị Ngọc", MemberTier.Gold, 3.9, 7000000m),
            ("Hồ Văn Oanh", MemberTier.Standard, 2.2, 2000000m),
            ("Phan Thị Phương", MemberTier.Silver, 3.4, 4000000m),
            ("Chu Văn Quân", MemberTier.Gold, 4.3, 8500000m),
            ("Dương Thị Rạng", MemberTier.Standard, 2.6, 2200000m),
            ("Tô Văn Sơn", MemberTier.Silver, 3.7, 5800000m),
            ("Lưu Thị Tâm", MemberTier.Diamond, 4.7, 9500000m),
            ("Cao Văn Uy", MemberTier.Gold, 4.4, 8800000m),
        };

        int i = 1;
        foreach (var (name, tier, rank, balance) in memberData)
        {
            await CreateUserIfNotExists(userManager, $"member{i}@pcm.vn", "Member@123", name, "Member",
                walletBalance: balance, tier: tier, rankLevel: rank);
            i++;
        }

        // 6. Seed Courts (if not exists)
        if (!context.Courts.Any())
        {
            context.Courts.AddRange(
                new Court { Name = "Sân 1 (Trong nhà)", Description = "Sân tiêu chuẩn thi đấu", PricePerHour = 150000, IsActive = true },
                new Court { Name = "Sân 2 (Trong nhà)", Description = "Sân tiêu chuẩn thi đấu", PricePerHour = 150000, IsActive = true },
                new Court { Name = "Sân 3 (Ngoài trời)", Description = "Sân ngoài trời, có mái che", PricePerHour = 100000, IsActive = true },
                new Court { Name = "Sân VIP", Description = "Sân cao cấp, điều hòa", PricePerHour = 250000, IsActive = true }
            );
            await context.SaveChangesAsync();
        }

        // 7. Seed Tournaments
        if (!context.Tournaments.Any())
        {
            context.Tournaments.AddRange(
                new Tournament
                {
                    Name = "Summer Open 2025",
                    StartDate = new DateTime(2025, 6, 1),
                    EndDate = new DateTime(2025, 6, 15),
                    Format = TournamentFormat.Knockout,
                    EntryFee = 200000,
                    PrizePool = 5000000,
                    Status = TournamentStatus.Finished,
                    Description = "Giải đấu mùa hè năm 2025 - Đã kết thúc"
                },
                new Tournament
                {
                    Name = "Winter Cup 2026",
                    StartDate = new DateTime(2026, 2, 1),
                    EndDate = new DateTime(2026, 2, 28),
                    Format = TournamentFormat.RoundRobin,
                    EntryFee = 300000,
                    PrizePool = 10000000,
                    Status = TournamentStatus.Registering,
                    Description = "Giải đấu mùa đông 2026 - Đang mở đăng ký!"
                }
            );
            await context.SaveChangesAsync();
        }

        // 8. Seed News
        if (!context.News.Any())
        {
            context.News.AddRange(
                new News
                {
                    Title = "Khai trương CLB Vợt Thủ Phố Núi",
                    Content = "Chào mừng các thành viên đến với CLB Pickleball đầu tiên của thành phố! Chúng tôi cam kết mang đến trải nghiệm thể thao tuyệt vời nhất.",
                    IsPinned = true,
                    CreatedDate = DateTime.UtcNow.AddDays(-30),
                    ImageUrl = "https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=800"
                },
                new News
                {
                    Title = "Thông báo: Giải Winter Cup 2026 chính thức mở đăng ký",
                    Content = "Giải đấu lớn nhất năm với tổng giải thưởng 10 triệu đồng. Đăng ký ngay trong ứng dụng!",
                    IsPinned = true,
                    CreatedDate = DateTime.UtcNow.AddDays(-5),
                    ImageUrl = "https://images.unsplash.com/photo-1461896836934- voices-of-earth?w=800"
                },
                new News
                {
                    Title = "Tips: 5 kỹ thuật cơ bản cho người mới chơi Pickleball",
                    Content = "1. Tư thế đứng đúng\n2. Cầm vợt chuẩn\n3. Đánh bóng căn bản\n4. Di chuyển linh hoạt\n5. Chiến thuật đơn giản",
                    IsPinned = false,
                    CreatedDate = DateTime.UtcNow.AddDays(-10),
                    ImageUrl = null
                }
            );
            await context.SaveChangesAsync();
        }

        Console.WriteLine("✅ Database seeding completed!");
    }

    private static async Task CreateUserIfNotExists(
        UserManager<Member> userManager,
        string email,
        string password,
        string fullName,
        string role,
        decimal walletBalance,
        MemberTier tier,
        double rankLevel)
    {
        if (await userManager.FindByEmailAsync(email) == null)
        {
            var user = new Member
            {
                UserName = email,
                Email = email,
                FullName = fullName,
                WalletBalance = walletBalance,
                Tier = tier,
                RankLevel = rankLevel,
                JoinDate = DateTime.UtcNow.AddDays(-Random.Shared.Next(30, 365)),
                TotalSpent = walletBalance * 0.3m, // Mock: spent 30% of current balance
                EmailConfirmed = true
            };

            var result = await userManager.CreateAsync(user, password);
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(user, role);
                Console.WriteLine($"Created user: {email} ({role})");
            }
            else
            {
                Console.WriteLine($"Failed to create user {email}: {string.Join(", ", result.Errors.Select(e => e.Description))}");
            }
        }
    }
}
