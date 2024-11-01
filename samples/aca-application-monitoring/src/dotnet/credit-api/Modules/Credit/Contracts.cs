using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace CreditApi.Modules.Credit;

public class CreateCreditRequest
{
    [Required]
    public string? Name { get; set; }
    public string? StartDate { get; set; }
}

public class CreateCreditResponse(Guid creditId)
{
    public Guid CreditId { get; set; } = creditId;
}

public class GetCreditResponse(Credit credit)
{
    public Guid CreditId { get; set; } = credit.CreditId;
    public string? Name { get; set; } = credit.Name;
    public decimal InterestRate { get; set; } = credit.InterestRate;
    public DateOnly CurrentMonth { get; set; } = credit.CurrentMonth;
    public ICollection<Transaction> Transactions { get; set; } = credit.Transactions;
}

public class AddTransactionRequest
{
    [Required]
    public int Value { get; set; }
    [Required]
    public string? Currency { get; set; }
    
    public string? TransactionDate { get; set; }
}

public class GetTransactionsResponse
{
    public int Count { get; set; }
}
