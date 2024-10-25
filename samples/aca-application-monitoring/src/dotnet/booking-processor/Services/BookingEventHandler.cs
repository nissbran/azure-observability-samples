using System.Diagnostics;
using System.Text.Json;
using Azure.Messaging.ServiceBus;
using BookingProcessor.Contract;
using BookingProcessor.Data;
using BookingProcessor.Telemetry;
using Microsoft.EntityFrameworkCore;
using OpenTelemetry;

namespace BookingProcessor.Services;

public class BookingEventHandler
{
    private readonly EventConsumedMetrics _metrics;
    private readonly IDbContextFactory<BookingDbContext> _contextFactory;
    private readonly ILogger<BookingEventHandler> _logger;
    private readonly ServiceBusSender _faultyBookingsSender;

    public BookingEventHandler(EventConsumedMetrics metrics, IDbContextFactory<BookingDbContext> contextFactory, ILogger<BookingEventHandler> logger, ServiceBusClient client)
    {
        _metrics = metrics;
        _contextFactory = contextFactory;
        _logger = logger;
        _faultyBookingsSender = client.CreateSender("faultybookings");
    }

    public async Task<bool> ProcessStartBooking(StartBookingEvent? startBooking)
    {
        if (startBooking == null)
        {
            _logger.LogWarning("Received null start booking event");
            return false;
        }
        
        var creditId = startBooking.CreditId;
        Baggage.SetBaggage("creditId", creditId);
        Activity.Current?.AddTag("creditId", creditId);
        
        using var _ = _logger.BeginScope(new Dictionary<string, object> { { "CreditId",creditId } });
        
        _logger.LogInformation("Started      - {CreditId}", creditId);

        using (var context = _contextFactory.CreateDbContext())
        {
            context.BookingMonths.Add(new BookingMonth(startBooking.CreditId, 1));
            await context.SaveChangesAsync();
        }

        _metrics.IncrementStartBookingEvents();
        
        await Task.Delay(new Random().Next(1000, 2000));

        return true;
    }
    
    public async Task<bool> ProcessTransactionBooking(BookingEvent? booking)
    {
        if (booking == null)
        {
            _logger.LogWarning("Received null booking event");
            return false;
        }
        
        var creditId = booking.CreditId;
        Baggage.SetBaggage("creditId", creditId);
        Activity.Current?.AddTag("creditId", creditId);
        using var _ = _logger.BeginScope(new Dictionary<string, object> { { "CreditId",creditId } });
        
        _logger.LogInformation("Booking      - {CreditId} -- value: {Value} -- tag: {ETag}", booking.CreditId, booking.Value, booking.ETag);
        
        var month = DateOnly.ParseExact(booking.Date, "yyyy-MM-dd").Month;
        using (var context = _contextFactory.CreateDbContext())
        {
            var bookingMonth = await context.BookingMonths.Include(bm => bm.Bookings).FirstOrDefaultAsync(bm => bm.BookingId == $"{creditId}-{month}");
            bookingMonth ??= new BookingMonth(creditId, month);
        
            if (bookingMonth.Closed)
            {
                _logger.LogError("Tried to add transaction to closed month {@Booking}, sending to manual handling", booking);
                
                var message = new ServiceBusMessage(JsonSerializer.Serialize(new FaultyBooking(booking.CreditId, booking.Value, booking.Date, month)));
                message.ApplicationProperties.Add("Type", nameof(FaultyBooking));
                await _faultyBookingsSender.SendMessageAsync(message);
                return true;
            }
            else
            {
                bookingMonth.AddBooking(booking.Value, booking.ETag);
            }
            
            await context.SaveChangesAsync();
        }
        
        _metrics.IncrementTransactionBookingEvents();
        
        await Task.Delay(new Random().Next(1000, 2000));
        
        _logger.LogInformation("Processed    - {CreditId} -- tag: {ETag}", booking.CreditId, booking.ETag);
        return true;
    }
    
    public async Task<bool> ProcessCloseMonth(CloseMonthEvent? closeMonth)
    {
        if (closeMonth == null)
        {
            _logger.LogWarning("Received null close month event");
            return false;
        }
        
        var creditId = closeMonth.CreditId;
        Baggage.SetBaggage("creditId", creditId);
        Activity.Current?.AddTag("creditId", creditId);
        using var _ = _logger.BeginScope(new Dictionary<string, object> { { "CreditId",creditId } });
            
        var month = closeMonth.Month;
        using (var context = _contextFactory.CreateDbContext())
        {
            var bookingMonth = await context.BookingMonths.FirstOrDefaultAsync(bm => bm.BookingId == $"{closeMonth.CreditId}-{month}");
            bookingMonth ??= new BookingMonth(creditId, month);
            bookingMonth.Closed = true;

            await Task.Delay(new Random().Next(500, 2000));

            context.BookingMonths.Update(bookingMonth);
            await context.SaveChangesAsync();
            
            _logger.LogInformation("Closed month - {Id} -- Month: {Month} -- Sum: {Sum}",
                closeMonth.CreditId, bookingMonth.Month, bookingMonth.Total);
        }

        _metrics.IncrementClosedMonthEvents();
        
        return true;
    }
}
