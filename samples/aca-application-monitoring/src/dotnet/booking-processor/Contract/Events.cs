namespace BookingProcessor.Contract;

public record StartBookingEvent(string CreditId);
public record BookingEvent(string CreditId, int Value, string Date, string ETag);
public record CloseMonthEvent(string CreditId, int Month);

public record FaultyBooking(string CreditId, int Value, string Date, int Month);