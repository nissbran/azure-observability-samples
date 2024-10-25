using System.Text.Json;
using Azure.Messaging.ServiceBus;
using BookingProcessor.Contract;
using BookingProcessor.Services;

namespace BookingProcessor.Subscriptions;

public class BookingSubscriptionService : IHostedService
{
    private readonly BookingEventHandler _eventHandler;
    private readonly ILogger<BookingSubscriptionService> _logger;
    private readonly ServiceBusSessionProcessor _processor;

    public BookingSubscriptionService(ServiceBusClient client, BookingEventHandler eventHandler, ILogger<BookingSubscriptionService> logger)
    {
        _eventHandler = eventHandler;
        _logger = logger;
        _processor = client.CreateSessionProcessor("bookings", "booking-processor", new ServiceBusSessionProcessorOptions
        {
            MaxConcurrentSessions = 2,
            MaxConcurrentCallsPerSession = 20,
            SessionIdleTimeout = TimeSpan.FromSeconds(20),
            AutoCompleteMessages = false,
            ReceiveMode = ServiceBusReceiveMode.PeekLock
        });
        
        _processor.ProcessMessageAsync += ProcessMessageAsync;
        _processor.ProcessErrorAsync += ProcessErrorAsync;
    }
    
    public async Task StartAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("BookingSubscriptionService is starting.");
        await _processor.StartProcessingAsync(cancellationToken);
    }

    public async Task StopAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("BookingSubscriptionService is stopping.");
        await _processor.StopProcessingAsync(cancellationToken);
    }

    private async Task ProcessMessageAsync(ProcessSessionMessageEventArgs args)
    {   
        var message = args.Message;
        var body = message.Body.ToString();
        var sessionId = message.SessionId;
        var type = message.ApplicationProperties["Type"].ToString();

        _logger.LogInformation("Processing message: {body}, SessionId: {sessionId}, Type: {type}", body, sessionId, type);
        
        var handled = false;
        switch (type)
        {
            case nameof(StartBookingEvent):
                var startBookingEvent = JsonSerializer.Deserialize<StartBookingEvent>(body);
                handled = await _eventHandler.ProcessStartBooking(startBookingEvent);
                break;
            case nameof(BookingEvent):
                var bookingEvent = JsonSerializer.Deserialize<BookingEvent>(body);
                handled = await _eventHandler.ProcessTransactionBooking(bookingEvent);
                break;
            case nameof(CloseMonthEvent):
                var closeMonthEvent = JsonSerializer.Deserialize<CloseMonthEvent>(body);
                handled = await _eventHandler.ProcessCloseMonth(closeMonthEvent);
                break;
        }

        if (handled)
        {
            await args.CompleteMessageAsync(message, args.CancellationToken);
        }
        else
        {
            await args.AbandonMessageAsync(message);
        }
    }

    private Task ProcessErrorAsync(ProcessErrorEventArgs arg)
    {
        _logger.LogError(arg.Exception, "Error processing message: {exception}", arg.Exception.Message);
        return Task.CompletedTask;
    }
}