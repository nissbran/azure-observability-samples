using System.Text.Json.Serialization;

namespace CreditApi.Modules.Credit;

public class Credit
{
    public long DbId { get; init; }
    public Guid CreditId { get; init; }
    public string Name { get; init; }
    public decimal InterestRate { get; init; } = 0.33m;
    public DateOnly CurrentMonth { get; set; }
    public ICollection<Transaction> Transactions { get; } = new List<Transaction>();
    [JsonIgnore]
    public IReadOnlyCollection<Transaction> NewTransactions => _newTransactions;

    private readonly List<Transaction> _newTransactions = new();

    public void AddTransaction(int value, DateOnly transactionDate)
    {
        var newTransaction = new Transaction { TransactionId = Guid.NewGuid(), Value = value, TransactionDate = transactionDate};
        Transactions.Add(newTransaction);
        _newTransactions.Add(newTransaction);
    }

    public int CloseCurrentMonth()
    {
        var month = CurrentMonth.Month;
        CurrentMonth = CurrentMonth.AddMonths(1);
        return month;
    }
}

public class Transaction
{
    public long DbId { get; init; }
    public Guid TransactionId { get; init; }
    public required int Value { get; init; }
    public required DateOnly TransactionDate { get; init; }
}