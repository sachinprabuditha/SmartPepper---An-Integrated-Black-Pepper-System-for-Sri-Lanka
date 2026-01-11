# SmartPepper Web Dashboard

🌶️ Real-time blockchain-based pepper auction platform built with Next.js, React, and Web3.

## Features

- ✅ Real-time auction bidding with WebSocket
- ✅ Web3 wallet integration (MetaMask, WalletConnect)
- ✅ Live auction countdown timers
- ✅ Bid history with blockchain transaction links
- ✅ Responsive design with Tailwind CSS
- ✅ Dark mode support
- ✅ Real-time notifications

## Tech Stack

- **Framework:** Next.js 14 (App Router) 
- **UI:** React 18, Tailwind CSS
- **Web3:** Wagmi, Viem, RainbowKit
- **State:** Zustand
- **Real-time:** Socket.IO Client
- **HTTP:** Axios
- **Utilities:** date-fns, lucide-react, react-hot-toast

## Getting Started

### Prerequisites

- Node.js 18+
- Backend server running (http://localhost:3000)
- Smart contract deployed

### Installation

```bash
npm install
```

### 🔧 Fix TypeScript Errors in VS Code

If you see "Cannot find module './providers'" or similar errors:

**Option 1: Reload VS Code Window**

1. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
2. Type: "Developer: Reload Window"
3. Press Enter

**Option 2: Restart TypeScript Server**

1. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
2. Type: "TypeScript: Restart TS Server"
3. Press Enter

**Option 3: Delete and Reinstall**

```bash
rm -rf node_modules .next
npm install
```

These errors appear when TypeScript hasn't indexed the newly installed dependencies yet. They will disappear after reloading!

### Installation

```bash
# Install dependencies
npm install

# Copy environment file
copy .env.example .env

# Configure environment variables
# Edit .env with your settings
```

### Environment Variables

```env
NEXT_PUBLIC_API_URL=http://localhost:3000
NEXT_PUBLIC_WS_URL=ws://localhost:3000
NEXT_PUBLIC_CONTRACT_ADDRESS=0x...
NEXT_PUBLIC_CHAIN_ID=11155111
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id
```

### Development

```bash
# Run development server
npm run dev

# Open browser
# Navigate to http://localhost:3001
```

### Build for Production

```bash
# Build
npm run build

# Start production server
npm start
```

## Project Structure

```
web/
├── src/
│   ├── app/                # Next.js app router pages
│   │   ├── layout.tsx      # Root layout
│   │   ├── page.tsx        # Home page
│   │   ├── providers.tsx   # Web3 providers
│   │   └── auctions/       # Auction pages
│   ├── components/         # React components
│   │   ├── layout/         # Header, footer
│   │   └── auction/        # Auction-specific components
│   ├── store/              # Zustand state management
│   ├── lib/                # API client, utilities
│   ├── config/             # Contract ABIs, configs
│   └── styles/             # Global styles
├── public/                 # Static assets
└── package.json
```

## Key Components

### AuctionList

Displays grid of auction cards with filters

### AuctionCard

Individual auction preview with status badges

### AuctionTimer

Real-time countdown with urgency indicators

### BidForm

Web3-enabled bidding interface

### BidHistory

Live bid updates via WebSocket

## Web3 Integration

### Wallet Connection

```typescript
import { ConnectButton } from "@rainbow-me/rainbowkit";

// Supports MetaMask, WalletConnect, Coinbase Wallet
<ConnectButton />;
```

### Smart Contract Interaction

```typescript
import { useWriteContract } from "wagmi";

const { writeContract } = useWriteContract();

writeContract({
  address: CONTRACT_ADDRESS,
  abi: PEPPER_AUCTION_ABI,
  functionName: "placeBid",
  args: [auctionId],
  value: parseEther(bidAmount),
});
```

### WebSocket Real-time Updates

```typescript
// Auto-connects on app load
const { joinAuction, leaveAuction } = useAuctionStore();

// Join auction room
joinAuction(auctionId, userAddress);

// Receive real-time bid updates
socket.on("new_bid", (data) => {
  // Update UI
});
```

## Pages

### / (Home)

- Hero section
- Feature highlights
- Active auctions preview
- Platform statistics

### /auctions

- Full auction list
- Filter by status
- Search functionality

### /auctions/[id]

- Auction details
- Live bidding interface
- Bid history
- Countdown timer
- Compliance status

### /create

- Create new auction (farmers)
- Lot registration
- Certificate upload

### /my-auctions

- User's auction history
- Active bids
- Won auctions

## Styling

### Tailwind CSS

Custom theme with pepper-themed colors:

```javascript
colors: {
  primary: { /* Orange palette */ },
  pepper: {
    green: '#2d5016',
    red: '#dc2626',
    black: '#1a1a1a',
    gold: '#fbbf24',
  }
}
```

### Custom Components

- `.btn-primary` - Primary action buttons
- `.card` - Content cards
- `.badge-*` - Status badges
- `.input` - Form inputs

## Real-time Features

### Live Auction Updates

- New bids appear instantly
- Current price updates
- Bid count increments
- User join/leave notifications

### Countdown Timers

- Updates every second
- Urgency indicator (last 5 minutes)
- Auto-refresh when auction ends

### Toast Notifications

- Bid confirmations
- Transaction status
- Error messages
- Success alerts

## Security

- Client-side wallet signature verification
- Transaction confirmation before submission
- Rate limiting on backend
- HTTPS in production
- Environment variable protection

## Performance

- Server-side rendering (SSR)
- Code splitting
- Image optimization
- Lazy loading components
- WebSocket connection pooling

## Browser Support

- Chrome/Edge (recommended)
- Firefox
- Safari
- Mobile browsers with Web3 support

## Troubleshooting

### Wallet Not Connecting

1. Check MetaMask is installed
2. Ensure correct network (Sepolia)
3. Check WalletConnect project ID

### Bids Not Updating

1. Verify backend WebSocket server running
2. Check browser console for errors
3. Confirm auction status is 'active'

### Transaction Failing

1. Check wallet has sufficient ETH
2. Verify contract address is correct
3. Ensure bid amount meets minimum

## License

MIT License

## Support

For issues or questions, open a GitHub issue or contact the team.

---

Built with ❤️ for transparent pepper trading
