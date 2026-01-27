namespace PCM.Backend.Models;

public enum MemberTier
{
    Standard,
    Silver,
    Gold,
    Diamond
}

public enum WalletTransactionType
{
    Deposit,
    Withdraw,
    Payment,
    Refund,
    Reward
}

public enum TransactionStatus
{
    Pending,
    Completed,
    Rejected,
    Failed
}

public enum BookingStatus
{
    PendingPayment,
    Confirmed,
    Cancelled,
    Completed,
    Holding // Custom status for Hold Slot
}

public enum TournamentFormat
{
    RoundRobin,
    Knockout,
    Hybrid
}

public enum TournamentStatus
{
    Open,
    Registering,
    DrawCompleted,
    Ongoing,
    Finished
}

public enum MatchResultType
{
    Normal,
    Walkover,
    Retired
}

public enum WinningSide
{
    Team1,
    Team2,
    Draw
}

public enum MatchStatus
{
    Scheduled,
    InProgress,
    Finished
}
