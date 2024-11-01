namespace BookingApi.Data;

public class BookingMonth
{
    public int DbId { get; init; }
    public string BookingId { get; init; }
    public Guid CreditId { get; init; }
    public int Month { get; init; }
    public ICollection<Booking> Bookings { get; } = new List<Booking>();
    public int Total => Bookings.Sum(booking => booking.Value);
    public bool Closed { get; set; }
}

public class Booking
{
    public int DbId { get; init; }
    public int Value { get; set; }
}