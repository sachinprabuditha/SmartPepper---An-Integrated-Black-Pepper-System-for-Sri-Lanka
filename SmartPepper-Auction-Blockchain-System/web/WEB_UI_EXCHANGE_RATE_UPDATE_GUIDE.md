# Web UI Exchange Rate Integration Guide

## Status: Mobile App ✅ | Web UI ⚠️

### Mobile App (Flutter) - Already Works! ✅

The mobile app **already fetches live rates** from the backend and will work automatically:

**File:** `mobile/lib/screens/farmer/create_auction_screen.dart`

```dart
// Line 108: Fetches from governance settings
_lkrToEthRate = (settingsResponse['lkrToEthRate'] ?? 0.0000031).toDouble();
```

**How it works:**

1. Mobile app calls `/governance/settings` API
2. Backend's exchangeRateService auto-updates governance settings every 5 minutes
3. Mobile app gets live rates automatically
4. **No changes needed!** ✅

---

### Web UI (Next.js) - Needs Update ⚠️

The web UI currently uses **hardcoded** exchange rates and needs to be updated.

## What's Been Created

### 1. Exchange Rate Service (`web/src/services/exchangeRateService.ts`)

- ✅ Created - Fetches live rates from backend
- ✅ Auto-updates every 5 minutes
- ✅ Fallback to cached rates if API fails
- ✅ Provides conversion utilities

### 2. Integration Guide (This File)

- Shows how to update existing components
- Provides migration examples

---

## How to Update Web UI Components

### Step 1: Initialize Service (Layout/Provider)

Add to your root layout or create a provider:

**File:** `web/src/app/layout.tsx` or create `web/src/providers/ExchangeRateProvider.tsx`

```tsx
"use client";

import { useEffect } from "react";
import { exchangeRateService } from "@/services/exchangeRateService";

export function ExchangeRateProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  useEffect(() => {
    // Initialize on mount
    exchangeRateService.initialize();

    // Cleanup on unmount
    return () => {
      exchangeRateService.stopUpdates();
    };
  }, []);

  return <>{children}</>;
}
```

Then wrap your app:

```tsx
<ExchangeRateProvider>{children}</ExchangeRateProvider>
```

### Step 2: Update Components to Use Live Rates

#### Before (Hardcoded ❌):

**File:** `web/src/app/auctions/[id]/page.tsx`

```tsx
// OLD CODE - Hardcoded
const LKR_TO_ETH_RATE = 0.0000031;
const ETH_TO_LKR_RATE = 322580.65;

function ethToLkr(ethAmount: number): number {
  return ethAmount * ETH_TO_LKR_RATE;
}
```

#### After (Live Rates ✅):

```tsx
// NEW CODE - Live rates
import { exchangeRateService } from "@/services/exchangeRateService";

// Use the service methods directly
const lkrAmount = exchangeRateService.ethToLkr(ethAmount);
const ethAmount = exchangeRateService.lkrToEth(lkrAmount);

// Or format directly
const formattedLkr = exchangeRateService.formatLkr(amount);
const formattedEth = exchangeRateService.formatEth(amount);
```

### Step 3: Display Rate Information

Add a rate indicator component:

```tsx
"use client";

import { useState, useEffect } from "react";
import { exchangeRateService } from "@/services/exchangeRateService";

export function ExchangeRateIndicator() {
  const [rates, setRates] = useState(exchangeRateService.getRates());
  const [status, setStatus] = useState(exchangeRateService.getStatus());

  useEffect(() => {
    const interval = setInterval(() => {
      setRates(exchangeRateService.getRates());
      setStatus(exchangeRateService.getStatus());
    }, 1000);

    return () => clearInterval(interval);
  }, []);

  return (
    <div className="text-sm text-gray-600">
      <span className={status.healthy ? "text-green-600" : "text-yellow-600"}>
        ● {status.healthy ? "Live" : "Cached"}
      </span>{" "}
      1 ETH = {exchangeRateService.formatLkr(rates.ethToLkr)}
      {status.lastUpdate && (
        <span className="text-xs ml-2">
          Updated: {new Date(status.lastUpdate).toLocaleTimeString()}
        </span>
      )}
    </div>
  );
}
```

---

## Files That Need Updating

### Priority 1: Core Auction Components

1. **`web/src/app/auctions/[id]/page.tsx`**
   - Replace hardcoded `ETH_TO_LKR_RATE` constant
   - Use `exchangeRateService.ethToLkr()` method
   - Update line 18-19 and all conversion functions

2. **`web/src/components/auction/BidForm.tsx`**
   - Replace hardcoded rates
   - Use live conversion for bid amount display
   - Update lines 10-11

3. **`web/src/components/auction/AuctionCard.tsx`**
   - Replace hardcoded rates
   - Use live conversion for price display
   - Update lines 11-12

### Priority 2: Dashboard Components

4. **`web/src/app/dashboard/exporter/bids/page.tsx`**
   - Already has currency field from backend
   - Just format using service methods

5. **`web/src/app/dashboard/exporter/won/page.tsx`**
   - Already has currency field from backend
   - Just format using service methods

### Priority 3: Create/Admin Pages

6. **`web/src/app/auctions/create/page.tsx`**
   - Use live rates for reserve price conversion
   - Show both ETH and LKR estimates

---

## Quick Migration Script

Here's a find-and-replace guide:

### Replace Constants

**Find:**

```typescript
const LKR_TO_ETH_RATE = 0.0000031;
const ETH_TO_LKR_RATE = 322580.65;
```

**Replace with:**

```typescript
import { exchangeRateService } from "@/services/exchangeRateService";
```

### Replace Functions

**Find:**

```typescript
function ethToLkr(ethAmount: number): number {
  return ethAmount * ETH_TO_LKR_RATE;
}
```

**Replace with:**

```typescript
// Delete the function, use service directly:
exchangeRateService.ethToLkr(ethAmount);
```

### Update Display Code

**Find:**

```typescript
{
  formatLkr(ethToLkr(auction.current_bid));
}
```

**Replace with:**

```typescript
{
  exchangeRateService.formatLkr(
    exchangeRateService.ethToLkr(auction.current_bid),
  );
}
```

---

## Testing Checklist

After updating components:

- [ ] Start backend: `cd backend && npm start`
- [ ] Check logs show: "Exchange Rate Service initialized"
- [ ] Start web UI: `cd web && npm run dev`
- [ ] Open browser console, check for: "✅ Exchange rates loaded"
- [ ] View auction page, verify prices show live rates
- [ ] Create auction, verify conversion is accurate
- [ ] Place bid, verify amounts convert correctly
- [ ] Check exchange rate indicator shows live status
- [ ] Disconnect backend, verify fallback rates work
- [ ] Reconnect, verify it resumes live updates

---

## Environment Variables

Add to `web/.env.local`:

```env
# Backend API URL
NEXT_PUBLIC_API_URL=http://localhost:3000
```

---

## Benefits of Update

### Before ❌

- Hardcoded rates (outdated)
- Manual updates needed
- Inaccurate conversions
- No sync with blockchain

### After ✅

- Live rates from CoinGecko API
- Auto-updates every 5 minutes
- Accurate conversions
- Synced with backend/blockchain
- Fallback if API fails

---

## Example: Complete Component Update

### Before:

```tsx
// OLD auction page
const LKR_TO_ETH_RATE = 0.0000031;
const ETH_TO_LKR_RATE = 322580.65;

function ethToLkr(ethAmount: number): number {
  return ethAmount * ETH_TO_LKR_RATE;
}

// In component
<div>{formatLkr(ethToLkr(auction.current_bid))}</div>;
```

### After:

```tsx
// NEW auction page
import { exchangeRateService } from '@/services/exchangeRateService';

// In component
<div>
  {exchangeRateService.formatLkr(
    exchangeRateService.ethToLkr(auction.current_bid)
  )}
</div>

// Show live rate indicator
<ExchangeRateIndicator />
```

---

## Support

- **Mobile App:** No changes needed - already working! ✅
- **Web UI:** Follow this guide to update components
- **Backend:** Already updated and running ✅
- **Testing:** Use the test script: `cd backend && node test-exchange-rates.js`

---

**Next Steps:**

1. ✅ Mobile app - Already working (fetches from governance settings)
2. ⏳ Web UI - Update components using this guide
3. ⏳ Add ExchangeRateIndicator to show live status
4. ⏳ Test all auction flows
5. ⏳ Deploy to production

---

**Status:**

- Backend: ✅ Complete
- Mobile: ✅ Complete (auto-working)
- Web UI: ⏳ Needs component updates (this guide provides everything needed)
