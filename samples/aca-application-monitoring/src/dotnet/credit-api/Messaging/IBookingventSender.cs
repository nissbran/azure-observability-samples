using CreditApi.Modules.Credit;

namespace CreditApi.Messaging;

public interface IBookingEventSender
{
    public Task SendAsync<T>(T integrationEvent, CancellationToken cancellationToken) where T : CreditIntegrationEvent;
}