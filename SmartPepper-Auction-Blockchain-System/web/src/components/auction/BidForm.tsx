'use client';

import { useState } from 'react';
import { useAccount } from 'wagmi';
import { auctionApi } from '@/lib/api';
import toast from 'react-hot-toast';
import { Loader2, TrendingUp, Zap, AlertCircle, DollarSign } from 'lucide-react';

// Currency conversion
const ETH_TO_LKR_RATE = 322580.65;

function ethToLkr(eth: number): string {
  return new Intl.NumberFormat('en-LK', {
    style: 'currency',
    currency: 'LKR',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(eth * ETH_TO_LKR_RATE);
}

interface BidFormProps {
  auctionId: number;
  currentBid: string;
  minimumBid: string;
}

export function BidForm({ auctionId, currentBid, minimumBid }: BidFormProps) {
  const { address, isConnected } = useAccount();
  const [bidAmount, setBidAmount] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const currentBidEth = parseFloat(currentBid || '0');
  const minIncrementPercent = 0.05; // 5% minimum increment
  const minBidEth = currentBidEth > 0 
    ? currentBidEth * (1 + minIncrementPercent)  // 5% above current bid
    : parseFloat(minimumBid || '0');

  // Quick bid buttons
  const quickBids = [
    { label: 'Min', value: minBidEth },
    { label: '+5%', value: minBidEth * 1.05 },
    { label: '+10%', value: minBidEth * 1.10 },
    { label: '+20%', value: minBidEth * 1.20 },
  ];

  const handleBidSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!isConnected || !address) {
      toast.error('Please connect your wallet');
      return;
    }

    const bid = parseFloat(bidAmount);
    if (isNaN(bid) || bid < minBidEth) {
      toast.error(`Bid must be at least ${minBidEth.toFixed(4)} ETH (5% above current bid)`);
      return;
    }

    try {
      setIsSubmitting(true);
      
      // Show loading toast
      const loadingToast = toast.loading('Submitting bid...');

      // Place bid via backend API (off-chain validation + real-time broadcast)
      const response = await auctionApi.placeBid(auctionId, {
        bidderAddress: address,
        bidderName: address.slice(0, 6) + '...' + address.slice(-4), // Optional display name
        amount: bidAmount,
      });

      toast.dismiss(loadingToast);

      if (response.data.success) {
        toast.success('🎉 Bid placed successfully!', {
          duration: 4000,
          icon: '✅',
        });
        
        // Show bid details
        toast.custom(
          <div className="bg-green-50 border border-green-200 rounded-lg p-4 shadow-lg">
            <div className="flex items-start gap-3">
              <Zap className="w-5 h-5 text-green-600 mt-0.5" />
              <div>
                <p className="font-semibold text-green-900">You are now the highest bidder!</p>
                <p className="text-sm text-green-700 mt-1">
                  Your bid: {parseFloat(bidAmount).toFixed(4)} ETH
                </p>
                <p className="text-xs text-green-600 mt-1">
                  You'll be notified if someone outbids you
                </p>
              </div>
            </div>
          </div>,
          { duration: 6000 }
        );

        // Reset form
        setBidAmount('');
      } else {
        toast.error(response.data.message || 'Failed to place bid');
      }

    } catch (error: any) {
      console.error('Bid error:', error);
      const errorMessage = error.response?.data?.message || error.message || 'Failed to place bid';
      
      toast.error(
        <div className="flex items-start gap-2">
          <AlertCircle className="w-4 h-4 mt-0.5 flex-shrink-0" />
          <div>
            <p className="font-medium">Bid Failed</p>
            <p className="text-xs mt-1">{errorMessage}</p>
          </div>
        </div>,
        { duration: 5000 }
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  if (!isConnected) {
    return (
      <div className="text-center py-6 border-2 border-dashed border-gray-300 dark:border-gray-700 rounded-lg">
        <TrendingUp className="w-12 h-12 mx-auto mb-3 text-gray-400" />
        <p className="text-gray-500 dark:text-gray-400 mb-4">Connect your wallet to place a bid</p>
      </div>
    );
  }

  return (
    <form onSubmit={handleBidSubmit} className="space-y-4">
      {/* Real-time bidding notice */}
      <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-3">
        <div className="flex items-start gap-2">
          <Zap className="w-4 h-4 text-blue-600 dark:text-blue-400 mt-0.5 flex-shrink-0" />
          <div>
            <p className="text-sm font-medium text-blue-900 dark:text-blue-300">Real-time Bidding</p>
            <p className="text-xs text-blue-700 dark:text-blue-400 mt-1">
              Your bid is validated instantly. If you win, you'll lock escrow after the auction ends.
            </p>
          </div>
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium mb-2 dark:text-gray-300">
          Your Bid Amount
        </label>
        <div className="relative">
          <input
            type="number"
            step="0.0001"
            min={minBidEth}
            value={bidAmount}
            onChange={(e) => setBidAmount(e.target.value)}
            placeholder={`Minimum: ${minBidEth.toFixed(4)} ETH`}
            className="input pr-16"
            disabled={isSubmitting}
            required
          />
          <span className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-500 font-medium">
            ETH
          </span>
        </div>
        
        {/* Dual currency display */}
        <div className="mt-2 space-y-1">
          <p className="text-xs text-gray-500 dark:text-gray-400">
            Current bid: {currentBidEth.toFixed(4)} ETH • Minimum: {minBidEth.toFixed(4)} ETH (+5%)
          </p>
          {bidAmount && !isNaN(parseFloat(bidAmount)) && (
            <div className="flex items-center gap-2 text-sm">
              <DollarSign className="w-4 h-4 text-blue-600" />
              <span className="font-medium text-blue-700 dark:text-blue-400">
                {ethToLkr(parseFloat(bidAmount))}
              </span>
              <span className="text-xs text-gray-500">(LKR equivalent)</span>
            </div>
          )}
        </div>
      </div>

      {/* Quick bid buttons */}
      <div className="grid grid-cols-4 gap-2">
        {quickBids.map((quick) => (
          <button
            key={quick.label}
            type="button"
            onClick={() => setBidAmount(quick.value.toFixed(4))}
            className="px-3 py-2 text-sm bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 rounded-lg transition-colors font-medium"
            disabled={isSubmitting}
          >
            {quick.label}
          </button>
        ))}
      </div>

      <button
        type="submit"
        className="btn-primary w-full flex items-center justify-center gap-2 font-semibold"
        disabled={isSubmitting || !bidAmount}
      >
        {isSubmitting ? (
          <>
            <Loader2 className="w-4 h-4 animate-spin" />
            Placing bid...
          </>
        ) : (
          <>
            <Zap className="w-4 h-4" />
            Place Bid Instantly
          </>
        )}
      </button>

      {/* Info about escrow */}
      <div className="bg-gray-50 dark:bg-gray-900 rounded-lg p-3 border border-gray-200 dark:border-gray-700">
        <p className="text-xs text-gray-600 dark:text-gray-400">
          <span className="font-medium">Note:</span> If you win, you'll need to lock your bid amount in escrow 
          via smart contract after the auction ends.
        </p>
      </div>
    </form>
  );
}
