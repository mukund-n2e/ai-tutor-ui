import { NextRequest, NextResponse } from 'next/server';
import Stripe from 'stripe';

// Server-only Stripe instance
const stripe = process.env.STRIPE_SECRET_KEY 
  ? new Stripe(process.env.STRIPE_SECRET_KEY, {
      apiVersion: '2025-08-27.basil',
    })
  : null;

export async function POST(request: NextRequest) {
  try {
    // Check if Stripe is configured
    if (!stripe) {
      return NextResponse.json(
        { error: 'Stripe not configured' },
        { status: 500 }
      );
    }

    const body = await request.json();
    const { planId, market } = body;

    // Validate input
    if (!planId || !market) {
      return NextResponse.json(
        { error: 'Missing planId or market' },
        { status: 400 }
      );
    }

    if (!['L2', 'L3'].includes(planId)) {
      return NextResponse.json(
        { error: 'Invalid plan ID. Only L2 and L3 are available for purchase.' },
        { status: 400 }
      );
    }

    if (!['AU', 'IN'].includes(market)) {
      return NextResponse.json(
        { error: 'Invalid market. Only AU and IN are supported.' },
        { status: 400 }
      );
    }

    // Determine currency and price ID
    const useINR = process.env.STRIPE_ENABLE_INR === 'true' && market === 'IN';
    
    let priceId: string;
    
    if (planId === 'L2') {
      priceId = useINR 
        ? process.env.PRICE_L2_INR! 
        : process.env.PRICE_L2_AUD!;
    } else { // L3
      priceId = useINR 
        ? process.env.PRICE_L3_INR! 
        : process.env.PRICE_L3_AUD!;
    }

    if (!priceId) {
      return NextResponse.json(
        { error: 'Price ID not configured for this plan and market combination' },
        { status: 500 }
      );
    }

    // Get the base URL for redirects
    const origin = request.nextUrl.origin;

    // Create Stripe Checkout Session
    const session = await stripe.checkout.sessions.create({
      mode: 'payment',
      payment_method_types: ['card'],
      line_items: [
        {
          price: priceId,
          quantity: 1,
        },
      ],
      success_url: `${origin}/checkout/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${origin}/checkout/error`,
      metadata: {
        level: planId,
        market,
        planId,
      },
    });

    return NextResponse.json({ url: session.url });

  } catch (error) {
    console.error('Stripe checkout error:', error);
    
    return NextResponse.json(
      { error: 'Failed to create checkout session' },
      { status: 500 }
    );
  }
}