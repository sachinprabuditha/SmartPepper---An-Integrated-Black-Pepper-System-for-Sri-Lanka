import { AuctionList } from '@/components/auction/AuctionList';
import { Gavel } from 'lucide-react';

export default function AuctionsPage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-8">
        <div className="flex items-center gap-3 mb-4">
          <Gavel className="w-8 h-8 text-primary-600 dark:text-primary-400" />
          <h1 className="text-4xl font-bold dark:text-white">Live Auctions</h1>
        </div>
        <p className="text-gray-600 dark:text-gray-400">
          Browse all active pepper auctions. Place bids in real-time with blockchain security.
        </p>
      </div>

      <AuctionList limit={100} />
    </div>
  );
}
