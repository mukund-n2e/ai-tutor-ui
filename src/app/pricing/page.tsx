'use client';

import { useState } from 'react';
import Header from '../../components/Header';
import '../../styles/tokens.css';

type Market = 'AU' | 'IN' | 'USD';
type Plan = 'L1' | 'L2' | 'L3' | 'L4';

const PRICING = {
  L2: { AU: 39, IN: 199, USD: 39 },
  L3: { AU: 89, IN: 399, USD: 89 },
  L4: { AU: 199, IN: 899, USD: 199 }
};

const CURRENCY_SYMBOLS = {
  AU: 'A$',
  IN: '₹',
  USD: 'US$'
};

export default function Pricing() {
  const [selectedMarket, setSelectedMarket] = useState<Market>('AU');

  const handleCheckout = async (planId: Plan) => {
    if (planId === 'L1') return; // Free plan
    if (planId === 'L4') return; // Coming soon

    try {
      const response = await fetch('/api/checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          planId, 
          market: selectedMarket === 'USD' ? 'AU' : selectedMarket // Fallback to AU for USD
        })
      });

      const data = await response.json();
      
      if (data.url) {
        window.location.href = data.url;
      } else {
        console.error('Checkout error:', data.error);
      }
    } catch (error) {
      console.error('Checkout failed:', error);
    }
  };

  const formatPrice = (planId: Plan) => {
    if (planId === 'L1') return 'Free';
    if (planId === 'L4') return 'Coming soon';
    
    const price = PRICING[planId as keyof typeof PRICING][selectedMarket];
    const symbol = CURRENCY_SYMBOLS[selectedMarket];
    return `${symbol}${price}`;
  };

  const getNote = () => {
    if (selectedMarket === 'IN' && process.env.NEXT_PUBLIC_STRIPE_ENABLE_INR !== 'true') {
      return '(charged in AUD today)';
    }
    return '';
  };

  return (
    <div className="min-h-screen bg-[var(--background)]">
      <Header />
      <main className="pt-[var(--header-height)]">
        <div className="mx-auto max-w-[1200px] px-4 py-8">
          <h1 className="text-2xl font-bold text-[var(--text-high)] mb-4">Pick your level</h1>
          <p className="text-[var(--text-mid)] mb-6">Choose your market and plan</p>

          {/* Market Selector */}
          <div className="mb-8" role="group" aria-label="Select market">
            <h2 className="text-lg font-semibold text-[var(--text-high)] mb-3">Market</h2>
            <div className="flex gap-3">
              {(['AU', 'IN', 'USD'] as Market[]).map((market) => (
                <button
                  key={market}
                  data-testid={`chk-market-${market.toLowerCase()}`}
                  onClick={() => setSelectedMarket(market)}
                  aria-pressed={selectedMarket === market}
                  className={`px-4 py-2 rounded-lg border-2 font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-[var(--accent)] focus:ring-offset-2 ${
                    selectedMarket === market
                      ? 'bg-[var(--accent)] text-white border-[var(--accent)]'
                      : 'bg-white text-[var(--text-high)] border-[var(--border)] hover:border-[var(--accent)]'
                  }`}
                >
                  {market}
                </button>
              ))}
            </div>
            {getNote() && (
              <p className="text-sm text-[var(--text-mid)] mt-2">{getNote()}</p>
            )}
          </div>

          {/* Plan Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {/* L1 - Free */}
            <div 
              data-testid="chk-plan-l1"
              className="bg-white border-2 border-[var(--border)] rounded-lg p-6 hover:border-[var(--accent)] transition-colors"
            >
              <h3 className="text-xl font-bold text-[var(--text-high)] mb-2">L1</h3>
              <p className="text-[var(--text-mid)] mb-4">Learn AI, build confidence</p>
              <div className="text-2xl font-bold text-[var(--accent)] mb-4">Free</div>
              <p className="text-sm text-[var(--text-mid)] mb-6">No account required</p>
              <button
                onClick={() => handleCheckout('L1')}
                className="w-full bg-[var(--accent)] text-white py-3 px-4 rounded-lg font-medium hover:opacity-90 transition-opacity focus:outline-none focus:ring-2 focus:ring-[var(--accent)] focus:ring-offset-2"
              >
                Get Started
              </button>
            </div>

            {/* L2 - Paid */}
            <div 
              data-testid="chk-plan-l2"
              className="bg-white border-2 border-[var(--border)] rounded-lg p-6 hover:border-[var(--accent)] transition-colors"
            >
              <h3 className="text-xl font-bold text-[var(--text-high)] mb-2">L2</h3>
              <p className="text-[var(--text-mid)] mb-4">Broad use-case skills</p>
              <div className="text-2xl font-bold text-[var(--accent)] mb-4">{formatPrice('L2')}</div>
              <p className="text-sm text-[var(--text-mid)] mb-6">Annual access</p>
              <button
                data-testid="chk-cta"
                onClick={() => handleCheckout('L2')}
                className="w-full bg-[var(--accent)] text-white py-3 px-4 rounded-lg font-medium hover:opacity-90 transition-opacity focus:outline-none focus:ring-2 focus:ring-[var(--accent)] focus:ring-offset-2"
              >
                Buy Now {formatPrice('L2')}
              </button>
            </div>

            {/* L3 - Paid */}
            <div 
              data-testid="chk-plan-l3"
              className="bg-white border-2 border-[var(--border)] rounded-lg p-6 hover:border-[var(--accent)] transition-colors"
            >
              <h3 className="text-xl font-bold text-[var(--text-high)] mb-2">L3</h3>
              <p className="text-[var(--text-mid)] mb-4">Profile-specific skills</p>
              <div className="text-2xl font-bold text-[var(--accent)] mb-4">{formatPrice('L3')}</div>
              <p className="text-sm text-[var(--text-mid)] mb-6">Annual access</p>
              <button
                data-testid="chk-cta"
                onClick={() => handleCheckout('L3')}
                className="w-full bg-[var(--accent)] text-white py-3 px-4 rounded-lg font-medium hover:opacity-90 transition-opacity focus:outline-none focus:ring-2 focus:ring-[var(--accent)] focus:ring-offset-2"
              >
                Buy Now {formatPrice('L3')}
              </button>
            </div>

            {/* L4 - Coming Soon */}
            <div 
              data-testid="chk-plan-l4"
              className="bg-white border-2 border-[var(--border)] rounded-lg p-6 opacity-60"
            >
              <h3 className="text-xl font-bold text-[var(--text-high)] mb-2">L4</h3>
              <p className="text-[var(--text-mid)] mb-4">Applying AI expertise</p>
              <div className="text-2xl font-bold text-[var(--text-mid)] mb-4">{formatPrice('L4')}</div>
              <p className="text-sm text-[var(--text-mid)] mb-6">Advanced features</p>
              <button
                disabled
                className="w-full bg-[var(--border)] text-[var(--text-mid)] py-3 px-4 rounded-lg font-medium cursor-not-allowed"
              >
                Coming Soon
              </button>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
