﻿namespace BookingProcessor.Data;

public class BookingMonth
{
    public int DbId { get; init; }
    public string BookingId { get; init; }
    public Guid CreditId { get; init; }
    public int Month { get; init; }
    public ICollection<Booking> Bookings { get; } = new List<Booking>();
    public int Total => Bookings.Sum(booking => booking.Value);
    public bool Closed { get; set; }

    public BookingMonth()
    {
    }
    
    public BookingMonth(Guid creditId, int month)
    {
        Month = month;
        BookingId = $"{creditId}-{month}";
        CreditId = creditId;
    }

    public void AddBooking(int value, string etag)
    {
        if (Bookings.Any(booking => booking.ETag == etag))
        {
            return;
        }

        Bookings.Add(new Booking { Value = value, ETag = etag });
    }
}

public class Booking
{
    public int DbId { get; init; }
    public int Value { get; set; }
    public string ETag { get; set; }
}