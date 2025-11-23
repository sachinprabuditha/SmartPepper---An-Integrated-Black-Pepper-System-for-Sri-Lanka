'use client';

import { Bid } from '@/store/auctionStore';
import { formatDistanceToNow } from 'date-fns';
import { TrendingUp } from 'lucide-react';

interface BidHistoryProps {
  auctionId: number;
  bids: Bid[];
}

export function BidHistory({ auctionId, bids }: BidHistoryProps) {
  if (bids.length === 0) {
    return (
      <div className="text-center py-8 text-gray-500 dark:text-gray-400">
        <TrendingUp className="w-12 h-12 mx-auto mb-2 opacity-50" />
        <p>No bids yet. Be the first to bid!</p>
      </div>
    );
  }

  return (
    <div className="space-y-3 max-h-96 overflow-y-auto">
      {bids.map((bid, index) => (
        <div
          key={bid.id}
          className={`p-4 rounded-lg border ${
            index === 0
              ? 'border-green-500 bg-green-50 dark:bg-green-900/20'
              : 'border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900'
          }`}
        >
          <div className="flex justify-between items-start mb-2">
            <div>
              <p className="font-mono text-sm text-gray-600 dark:text-gray-400">
                {bid.bidderAddress.slice(0, 6)}...{bid.bidderAddress.slice(-4)}
              </p>
              <p className="text-xs text-gray-500 dark:text-gray-500">
                {formatDistanceToNow(new Date(bid.placedAt), { addSuffix: true })}
              </p>
            </div>
            <div className="text-right">
              <p className="text-lg font-bold text-primary-600">
                {parseFloat(bid.amount).toFixed(4)} ETH
              </p>
              {index === 0 && (
                <span className="text-xs text-green-600 dark:text-green-400 font-semibold">
                  Leading Bid
                </span>
              )}
            </div>
          </div>
          {bid.blockchainTxHash && (
            <a
              href={`https://sepolia.etherscan.io/tx/${bid.blockchainTxHash}`}
              target="_blank"
              rel="noopener noreferrer"
              className="text-xs text-primary-600 hover:underline"
            >
              View Transaction →
            </a>
          )}
        </div>
      ))}
    </div>
  );
}
