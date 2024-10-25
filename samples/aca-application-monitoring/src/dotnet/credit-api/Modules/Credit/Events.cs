using System.Text.Json.Serialization;

namespace CreditApi.Modules.Credit;

public abstract class CreditIntegrationEvent(string creditId)
{
    public string CreditId { get; init; } = creditId;
    [JsonIgnore]
    public abstract string Type { get; }
}

public class StartBookingEvent(string creditId) : CreditIntegrationEvent(creditId)
{    
    public override string Type => nameof(StartBookingEvent);
}

public class BookingEvent(string creditId, int value, string date) : CreditIntegrationEvent(creditId)
{
    public int Value { get; } = value;
    public string Date { get; } = date;
    public override string Type => nameof(BookingEvent);
}

public class CloseMonthEvent(string creditId, int month):  CreditIntegrationEvent(creditId) 
{
    public int Month { get; } = month;
    public override string Type => nameof(CloseMonthEvent);
}