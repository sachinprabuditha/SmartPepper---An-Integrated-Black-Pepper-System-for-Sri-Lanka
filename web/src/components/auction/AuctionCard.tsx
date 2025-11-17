'use client';

import Link from 'next/link';
import { Auction } from '@/store/auctionStore';
import { formatDistanceToNow } from 'date-fns';
import { Clock, TrendingUp, User, CheckCircle, XCircle } from 'lucide-react';
import { AuctionStatus } from '@/config/contracts';

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
        <h3 className="text-xl font-semibold">Lot #{auction.lotId}</h3>
        {getStatusBadge(auction.status)}
      </div>

      <div className="space-y-3 mb-4">
        <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400">
          <User className="w-4 h-4" />
          <span className="font-mono text-xs">{auction.farmerAddress.slice(0, 6)}...{auction.farmerAddress.slice(-4)}</span>
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
          <div>
            <p className="text-xs text-gray-500 dark:text-gray-400 mb-1">Start Price</p>
            <p className="text-lg font-bold text-primary-600">
              {parseFloat(auction.startPrice).toFixed(4)} ETH
            </p>
          </div>
          <div>
            <p className="text-xs text-gray-500 dark:text-gray-400 mb-1">Current Bid</p>
            <p className="text-lg font-bold text-green-600">
              {auction.currentBid !== '0' ? `${parseFloat(auction.currentBid).toFixed(4)} ETH` : 'No bids'}
            </p>
          </div>
        </div>

        <div className="flex items-center justify-between text-sm text-gray-600 dark:text-gray-400 mb-4">
          <span className="flex items-center gap-1">
            <TrendingUp className="w-4 h-4" />
            {auction.bidCount} {auction.bidCount === 1 ? 'bid' : 'bids'}
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
