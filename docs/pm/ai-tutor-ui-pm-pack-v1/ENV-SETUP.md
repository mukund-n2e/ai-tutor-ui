# ENV Setup

Copy `.env.example` to `.env.local` for local dev.

## Stripe
STRIPE_SECRET_KEY=
STRIPE_PRICE_L2_AUD=
STRIPE_PRICE_L2_INR=
STRIPE_PRICE_L2_USD=
STRIPE_PRICE_L3_AUD=
STRIPE_PRICE_L3_INR=
STRIPE_PRICE_L3_USD=
STRIPE_ENABLE_INR=true

> Build does not require these. API routes return 400 when absent.
