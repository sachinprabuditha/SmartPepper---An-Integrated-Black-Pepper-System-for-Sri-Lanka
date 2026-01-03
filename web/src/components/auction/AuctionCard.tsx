'use client';

import Link from 'next/link';
import { Auction } from '@/store/auctionStore';
import { formatDistanceToNow } from 'date-fns';
import { Clock, TrendingUp, User, CheckCircle, XCircle, DollarSign } from 'lucide-react';
import { AuctionStatus } from '@/config/contracts';

// Currency conversion
const ETH_TO_LKR_RATE = 322580.65;

function ethToLkr(eth: number): string {
  return new Intl.NumberFormat('en-LK', {
    style: 'currency',
    currency: 'LKR',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(eth * ETH_TO_LKR_RATE);
}

interface AuctionCardProps {
  auction: Auction;
}

export function AuctionCard({ auction }: AuctionCardProps) {
  const getStatusBadge = (status: string) => {
    const statusMap: Record<string, { label: string; className: string }> = {
      created: { label: 'Created', className: 'badge-info' },
      active: { label: 'Live', className: 'badge-success' },
      ended: { label: 'Ended', className: 'badge-warning' },
      settled: { label: 'Settled', className: 'badge-info' },
      failed_compliance: { label: 'Failed', className: 'badge-danger' },
    };

    const statusInfo = statusMap[status] || { label: status, className: 'badge-info' };
    
    return (
      <span className={statusInfo.className}>
        {statusInfo.label}
        {status === 'active' && <span className="ml-1 inline-block w-2 h-2 bg-green-500 rounded-full animate-pulse"></span>}
      </span>
    );
  };

  const timeRemaining = () => {
    const endTime = new Date(auction.endTime);
    const now = new Date();
    
    if (now >= endTime) return 'Ended';
    return formatDistanceToNow(endTime, { addSuffix: true });
  };

  return (
    <div className="card hover:shadow-xl transition-shadow duration-200">
      <div className="flex justify-between items-start mb-4">
        <h3 className="text-xl font-semibold dark:text-white">Lot #{auction.lotId}</h3>
        {getStatusBadge(auction.status)}
      </div>

      <div className="space-y-3 mb-4">
        <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400">
          <User className="w-4 h-4" />
          <span className="font-mono text-xs">
            {auction.farmerAddress 
              ? `${auction.farmerAddress.slice(0, 6)}...${auction.farmerAddress.slice(-4)}`
              : 'Unknown'}
          </span>
        </div>

        <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400">
          <Clock className="w-4 h-4" />
          <span>{timeRemaining()}</span>
        </div>

        <div className="flex items-center gap-2">
          {auction.compliancePassed ? (
            <CheckCircle className="w-4 h-4 text-green-600" />
          ) : (
            <XCircle className="w-4 h-4 text-red-600" />
          )}
          <span className="text-sm">
            {auction.compliancePassed ? 'Compliance Passed' : 'Pending Compliance'}
          </span>
        </div>
      </div>

      <div className="border-t border-gray-200 dark:border-gray-700 pt-4">
        <div className="grid grid-cols-2 gap-4 mb-4">
          <div className="bg-gray-50 dark:bg-gray-900 p-3 rounded-lg">
            <p className="text-xs text-gray-500 dark:text-gray-400 mb-1">Start Price</p>
            <p className="text-lg font-bold text-primary-600">
              {auction.startPrice ? (parseFloat(auction.startPrice) / 1e18).toFixed(4) : '0.0000'} ETH
            </p>
            <p className="text-xs text-gray-500 mt-1">
              ≈ {auction.startPrice ? ethToLkr(parseFloat(auction.startPrice) / 1e18) : 'LKR 0'}
            </p>
          </div>
          <div className="bg-gradient-to-br from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20 p-3 rounded-lg border border-green-200 dark:border-green-800">
            <p className="text-xs text-gray-600 dark:text-gray-400 mb-1">Current Bid</p>
            {auction.currentBid && auction.currentBid !== '0' ? (
              <>
                <p className="text-lg font-bold text-green-600">
                  {(parseFloat(auction.currentBid) / 1e18).toFixed(4)} ETH
                </p>
                <p className="text-xs text-gray-600 dark:text-gray-400 mt-1 font-medium">
                  ≈ {ethToLkr(parseFloat(auction.currentBid) / 1e18)}
                </p>
              </>
            ) : (
              <p className="text-lg font-bold text-gray-400">No bids</p>
            )}
          </div>
        </div>

        <div className="flex items-center justify-between text-sm text-gray-600 dark:text-gray-400 mb-4">
          <span className="flex items-center gap-1">
            <TrendingUp className="w-4 h-4" />
            {auction.bidCount || 0} {auction.bidCount === 1 ? 'bid' : 'bids'}
          </span>
        </div>

        <Link
          href={`/auctions/${auction.auctionId}`}
          className="btn-primary w-full text-center"
        >
          View Auction
        </Link>
      </div>
    </div>
  );
}
