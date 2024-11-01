using BookingApi.Data;

namespace BookingApi.Modules.Booking;

public class GetCreditBookingResponseV1
{
    public GetCreditBookingResponseV1(List<BookingMonth> bookingMonth)
    {
        BookingMonths = bookingMonth.Select(b => new BookingMonthResponseV1(b)).ToList();
    }

    public List<BookingMonthResponseV1> BookingMonths { get; }
}

public class BookingMonthResponseV1
{
    public BookingMonthResponseV1(BookingMonth bookingMonth)
    {
        Month = bookingMonth.Month;
        Total = bookingMonth.Total;
        Closed = bookingMonth.Closed;
        Bookings = bookingMonth.Bookings.Select(b => new BookingResponse(b)).ToList();
    }

    public int Month { get; }
    public int Total { get; }
    public bool Closed { get; }
    public List<BookingResponse> Bookings { get; }
}

public class GetCreditBookingResponseV2
{
    public GetCreditBookingResponseV2(List<BookingMonth> bookingMonth)
    {
        BookingMonths = bookingMonth.Select(b => new BookingMonthResponseV2(b)).ToList();
    }

    public List<BookingMonthResponseV2> BookingMonths { get; }
}

public class BookingMonthResponseV2
{
    public BookingMonthResponseV2(BookingMonth bookingMonth)
    {
        Month = bookingMonth.Month;
        Closed = bookingMonth.Closed;
    }

    public int Month { get; }
    public bool Closed { get; }
}

public class BookingResponse(Data.Booking booking)
{
    public int Value { get; } = booking.Value;
}
