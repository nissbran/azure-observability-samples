using System.Text.Json;
using Azure.Messaging.ServiceBus;
using CreditApi.Modules.Credit;

namespace CreditApi.Messaging;

public class ServiceBusBookingEventSender(ServiceBusClient client) : IBookingEventSender
{
    private readonly ServiceBusSender _sender = client.CreateSender("bookings");

    public async Task SendAsync<T>(T integrationEvent, CancellationToken cancellationToken) where T : CreditIntegrationEvent
    {
        var message = new ServiceBusMessage(JsonSerializer.Serialize(integrationEvent));
        message.ApplicationProperties.Add("Type", integrationEvent.Type);
        message.SessionId = integrationEvent.CreditId;
        await _sender.SendMessageAsync(message, cancellationToken);
    }
}