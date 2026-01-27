using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using PCM.Backend.Models;

namespace PCM.Backend.Data;

public class ApplicationDbContext : IdentityDbContext<Member>
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
    {
    }

    public DbSet<WalletTransaction> WalletTransactions { get; set; }
    public DbSet<Court> Courts { get; set; }
    public DbSet<Booking> Bookings { get; set; }
    public DbSet<Tournament> Tournaments { get; set; }
    public DbSet<TournamentParticipant> TournamentParticipants { get; set; }
    public DbSet<Match> Matches { get; set; }
    public DbSet<News> News { get; set; }
    public DbSet<Notification> Notifications { get; set; }
    public DbSet<TransactionCategory> TransactionCategories { get; set; }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // Configure relationships and precision
        
        builder.Entity<Member>()
            .Property(m => m.WalletBalance)
            .HasColumnType("decimal(18,2)");
            
        builder.Entity<Member>()
            .Property(m => m.TotalSpent)
            .HasColumnType("decimal(18,2)");

        builder.Entity<WalletTransaction>()
            .HasOne(t => t.Member)
            .WithMany()
            .HasForeignKey(t => t.MemberId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<Booking>()
            .HasOne(b => b.Court)
            .WithMany()
            .HasForeignKey(b => b.CourtId);

        builder.Entity<Booking>()
            .HasOne(b => b.Member)
            .WithMany()
            .HasForeignKey(b => b.MemberId)
            .OnDelete(DeleteBehavior.Restrict);

        // Tournament Relationships
        builder.Entity<TournamentParticipant>()
            .HasOne(tp => tp.Tournament)
            .WithMany(t => t.Participants)
            .HasForeignKey(tp => tp.TournamentId);

        builder.Entity<Match>()
            .HasOne(m => m.Tournament)
            .WithMany(t => t.Matches)
            .HasForeignKey(m => m.TournamentId);
            
        // Match Participants - Optional to configure specifically if using String IDs or Objects
        // If string IDs are FKs, we need to map them if we want navigation properties to work perfectly
        // But IdentityUser FKs can be Tricky. For now, we rely on the Properties in Match.cs
        
        builder.Entity<Match>()
            .HasOne(m => m.Team1_Player1).WithMany().HasForeignKey(m => m.Team1_Player1Id).OnDelete(DeleteBehavior.Restrict);
        builder.Entity<Match>()
            .HasOne(m => m.Team1_Player2).WithMany().HasForeignKey(m => m.Team1_Player2Id).OnDelete(DeleteBehavior.Restrict);
        builder.Entity<Match>()
            .HasOne(m => m.Team2_Player1).WithMany().HasForeignKey(m => m.Team2_Player1Id).OnDelete(DeleteBehavior.Restrict);
        builder.Entity<Match>()
            .HasOne(m => m.Team2_Player2).WithMany().HasForeignKey(m => m.Team2_Player2Id).OnDelete(DeleteBehavior.Restrict);

        // Map Table Names with MSSV Prefix (459)
        builder.Entity<Member>().ToTable("459_Members");
        builder.Entity<WalletTransaction>().ToTable("459_WalletTransactions");
        builder.Entity<Court>().ToTable("459_Courts");
        builder.Entity<Booking>().ToTable("459_Bookings");
        builder.Entity<Tournament>().ToTable("459_Tournaments");
        builder.Entity<TournamentParticipant>().ToTable("459_TournamentParticipants");
        builder.Entity<Match>().ToTable("459_Matches");
        builder.Entity<News>().ToTable("459_News");
        builder.Entity<Notification>().ToTable("459_Notifications");
        builder.Entity<TransactionCategory>().ToTable("459_TransactionCategories");
        // AspNet Identity Tables can remain default or be renamed if strict compliance is needed, usually business tables are the focus.
        // But to be safe, I'll valid business tables are the ones explicitly listed in requirement.
    }
}
