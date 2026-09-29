"""Who charges the businesses. The app only asks a provider to start a
checkout and to tell it when a payment changed a subscription; each
provider (manual, Stripe, Mercado Pago…) implements that its own way."""

from typing import Protocol

from .models import Subscription


class BillingProvider(Protocol):
    code: str

    def checkout_url(self, subscription: Subscription) -> str | None:
        """Where the business pays, or None when staff activates by hand."""


class ManualProvider:
    """Staff turns subscriptions on and off in the admin (invoices sent
    outside the app). The default until a payment provider is chosen."""

    code = "manual"

    def checkout_url(self, subscription: Subscription) -> str | None:
        return None


PROVIDERS: dict[str, BillingProvider] = {ManualProvider.code: ManualProvider()}


def provider_for(subscription: Subscription) -> BillingProvider:
    return PROVIDERS.get(subscription.provider, PROVIDERS["manual"])
