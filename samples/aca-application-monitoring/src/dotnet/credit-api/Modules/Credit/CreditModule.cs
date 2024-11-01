using System.Diagnostics;
using CreditApi.Data;
using CreditApi.Messaging;
using Microsoft.EntityFrameworkCore;
using OpenTelemetry;

namespace CreditApi.Modules.Credit;

public static class CreditModule
{
    public static void MapRoutes(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("v1/credits")
            .WithOpenApi();

        group.MapPost("", CreateCredit)
            .WithName("CreateCredit")
            .RequireRateLimiting("FixedWindow")
            .Produces<CreateCreditResponse>(201);
        group.MapGet("{id:guid}", GetCredit)
            .WithName("GetCredit")
            .Produces<GetCreditResponse>(200);
        group.MapPost("{id:guid}/transactions", AddTransaction);
        group.MapGet("{id:guid}/transactions", GetTransactions);
        group.MapPut("{id:guid}/close-month", CloseMonth);
    }

    private static async Task<IResult> CreateCredit(CreateCreditRequest request, 
        IBookingEventSender eventSender, CreditDbContext dbContext, CreditMetrics metrics)
    {
        var creditId = Guid.NewGuid();
        
        Baggage.SetBaggage("creditId", creditId.ToString());
        Activity.Current?.AddTag("creditId", creditId);
        
        var newCredit = new Credit
        {
            Name = request.Name,
            CreditId = creditId,
            CurrentMonth = DateOnly.ParseExact(request.StartDate, "yyyy-MM-dd")
        };

        dbContext.Credits.Add(newCredit);
        await dbContext.SaveChangesAsync();

        await eventSender.SendAsync(new StartBookingEvent(newCredit.CreditId.ToString()), CancellationToken.None);
        
        metrics.IncrementCreditsCreated();
        
        return TypedResults.Created($"v1/credits/{newCredit.CreditId}", new CreateCreditResponse(newCredit.CreditId));
    }

    private static async Task<IResult> GetCredit(Guid id, CreditDbContext dbContext)
    {
        Baggage.SetBaggage("creditId", id.ToString());
        Activity.Current?.AddTag("creditId", id);
        
        var credit = await dbContext.Credits.Where(c => c.CreditId == id).Include(c => c.Transactions).FirstOrDefaultAsync();
        
        if (credit == null)
            return TypedResults.NotFound();
        
        return TypedResults.Ok(new GetCreditResponse(credit));
    }
    
    private static async Task<IResult> AddTransaction(Guid id, AddTransactionRequest request, IBookingEventSender eventSender, CreditMetrics metrics, CreditDbContext dbContext)
    {
        Baggage.SetBaggage("creditId", id.ToString());
        Activity.Current?.AddTag("creditId", id);
        
        var credit = await dbContext.Credits.Where(c => c.CreditId ==id).FirstOrDefaultAsync();
        
        if (credit == null)
            return TypedResults.NotFound();
    
        var transactionDate = DateOnly.ParseExact(request.TransactionDate, "yyyy-MM-dd");
        
        credit.AddTransaction(request.Value, transactionDate);
    
        await dbContext.SaveChangesAsync();

        foreach (var transaction in credit.NewTransactions)
        {
            metrics.AddTransactionValue(transaction.Value, "SEK");
            
            await eventSender.SendAsync(new BookingEvent(credit.CreditId.ToString(), transaction.Value, transactionDate.ToString("yyyy-MM-dd"), transaction.TransactionId.ToString()), CancellationToken.None);
        }
        
        return TypedResults.Created();
    }
    
    private static async Task<IResult> GetTransactions(Guid id, CreditDbContext dbContext)
    {
        Baggage.SetBaggage("creditId", id.ToString());
        Activity.Current?.AddTag("creditId", id);
        
        var credit = await dbContext.Credits.Where(c => c.CreditId == id).Include(credit => credit.Transactions).FirstOrDefaultAsync();
        
        if (credit == null)
            return TypedResults.NotFound();
        
        return TypedResults.Ok(new GetTransactionsResponse { Count = credit.Transactions.Count });
    }
    
    private static async Task<IResult> CloseMonth(Guid id, CreditDbContext dbContext, IBookingEventSender eventSender)
    {
        Baggage.SetBaggage("creditId", id.ToString());
        Activity.Current?.AddTag("creditId", id);
        
        var credit = await dbContext.Credits.Where(c => c.CreditId == id).FirstOrDefaultAsync();
        
        if (credit == null)
            return TypedResults.NotFound();
        
        var month = credit.CloseCurrentMonth();
        
        await dbContext.SaveChangesAsync();
        
        await eventSender.SendAsync(new CloseMonthEvent(credit.CreditId.ToString(), month), CancellationToken.None);
        
        return TypedResults.Ok();
    }
}