'use client';

import { useState } from 'react';
import { useAccount, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther } from 'viem';
import { Auction } from '@/store/auctionStore';
import { PEPPER_AUCTION_ABI, CONTRACT_ADDRESS } from '@/config/contracts';
import { auctionApi } from '@/lib/api';
import toast from 'react-hot-toast';
import { Loader2, TrendingUp } from 'lucide-react';

interface BidFormProps {
  auction: Auction;
}

export function BidForm({ auction }: BidFormProps) {
  const { address, isConnected } = useAccount();
  const [bidAmount, setBidAmount] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const minBid = auction.currentBid === '0'
    ? parseFloat(auction.startPrice)
    : parseFloat(auction.currentBid) + 0.0001; // Min increment

  const handleBidSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!isConnected || !address) {
      toast.error('Please connect your wallet');
      return;
    }

    const bid = parseFloat(bidAmount);
    if (isNaN(bid) || bid < minBid) {
      toast.error(`Bid must be at least ${minBid.toFixed(4)} ETH`);
      return;
    }

    try {
      setIsSubmitting(true);

      // Write to smart contract
      writeContract({
        address: CONTRACT_ADDRESS as `0x${string}`,
        abi: PEPPER_AUCTION_ABI,
        functionName: 'placeBid',
        args: [BigInt(auction.auctionId)],
        value: parseEther(bidAmount),
      });

    } catch (error: any) {
      console.error('Bid error:', error);
      toast.error(error.message || 'Failed to place bid');
      setIsSubmitting(false);
    }
  };

  // Handle transaction success
  if (isSuccess && hash) {
    // Store bid in backend
    auctionApi.placeBid(auction.auctionId, {
      bidderAddress: address!,
      amount: bidAmount,
      txHash: hash,
    }).then(() => {
      toast.success('Bid placed successfully!');
      setBidAmount('');
      setIsSubmitting(false);
    }).catch((error) => {
      console.error('Failed to record bid:', error);
      toast.error('Bid placed but failed to record in database');
      setIsSubmitting(false);
    });
  }

  if (!isConnected) {
    return (
      <div className="text-center py-6 text-gray-500 dark:text-gray-400">
        <p className="mb-4">Connect your wallet to place a bid</p>
      </div>
    );
  }

  return (
    <form onSubmit={handleBidSubmit} className="space-y-4">
      <div>
        <label className="block text-sm font-medium mb-2">
          Your Bid (ETH)
        </label>
        <input
          type="number"
          step="0.0001"
          min={minBid}
          value={bidAmount}
          onChange={(e) => setBidAmount(e.target.value)}
          placeholder={`Min: ${minBid.toFixed(4)} ETH`}
          className="input"
          disabled={isSubmitting || isPending || isConfirming}
          required
        />
        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
          Minimum bid: {minBid.toFixed(4)} ETH
        </p>
      </div>

      <button
        type="submit"
        className="btn-primary w-full flex items-center justify-center gap-2"
        disabled={isSubmitting || isPending || isConfirming || !bidAmount}
      >
        {(isPending || isConfirming) ? (
          <>
            <Loader2 className="w-4 h-4 animate-spin" />
            {isPending ? 'Confirm in wallet...' : 'Processing...'}
          </>
        ) : (
          <>
            <TrendingUp className="w-4 h-4" />
            Place Bid
          </>
        )}
      </button>

      {isPending && (
        <p className="text-sm text-center text-yellow-600">
          Waiting for wallet confirmation...
        </p>
      )}

      {isConfirming && (
        <p className="text-sm text-center text-blue-600">
          Waiting for transaction confirmation...
        </p>
      )}

      {hash && (
        <p className="text-xs text-center">
          <a
            href={`https://sepolia.etherscan.io/tx/${hash}`}
            target="_blank"
            rel="noopener noreferrer"
            className="text-primary-600 hover:underline"
          >
            View transaction →
          </a>
        </p>
      )}
    </form>
  );
}
