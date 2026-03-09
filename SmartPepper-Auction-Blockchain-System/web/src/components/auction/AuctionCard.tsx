'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { Auction } from '@/store/auctionStore';
import { formatDistanceToNow } from 'date-fns';
import { Clock, TrendingUp, User, CheckCircle, XCircle, DollarSign, MapPin, ImageIcon, Loader2 } from 'lucide-react';
import { AuctionStatus } from '@/config/contracts';
import { exchangeRateService } from '@/services/exchangeRateService';

// Currency conversion using live rates
function ethToLkr(eth: number): string {
  return new Intl.NumberFormat('en-LK', {
    style: 'currency',
    currency: 'LKR',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(exchangeRateService.ethToLkr(eth));
}

// IPFS URL converter helper
function convertToGatewayUrl(url: string): string {
  if (!url) return '';
  
  // If it's already a full HTTP URL and not IPFS, return as is
  if ((url.startsWith('http://') || url.startsWith('https://')) && !url.includes('/ipfs/')) {
    return url;
  }
  
  // Extract CID from various formats
  let cid = null;
  
  if (url.startsWith('ipfs://')) {
    cid = url.replace('ipfs://', '');
  } else if (url.startsWith('Qm') || url.startsWith('bafy')) {
    cid = url;
  } else {
    const match = url.match(/\/ipfs\/([a-zA-Z0-9]+)/);
    if (match) {
      cid = match[1];
    }
  }
  
  if (cid) {
    return `http://localhost:8080/ipfs/${cid}`;
  }
  
  return url;
}

interface AuctionCardProps {
  auction: Auction;
}

export function AuctionCard({ auction }: AuctionCardProps) {
  const router = useRouter();
  const [isNavigating, setIsNavigating] = useState(false);

  const handleViewAuction = () => {
    setIsNavigating(true);
    router.push(`/auctions/${auction.auctionId}`);
  };

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
      <span className={`${statusInfo.className} absolute top-3 right-3 z-10 shadow-lg`}>
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
    <div className="card hover:shadow-xl transition-shadow duration-200 overflow-hidden">
      {/* Lot Image */}
      {auction.lotPictures && auction.lotPictures.length > 0 ? (
        <div className="relative h-48 w-full bg-gray-200 dark:bg-gray-700 overflow-hidden">
          <img
            src={convertToGatewayUrl(auction.lotPictures[0])}
            alt={`Lot ${auction.lotId}`}
            className="w-full h-full object-cover"
            onError={(e) => {
              const target = e.target as HTMLImageElement;
              target.style.display = 'none';
              const parent = target.parentElement;
              if (parent) {
                parent.innerHTML = `
                  <div class="flex items-center justify-center h-full bg-gray-100 dark:bg-gray-800">
                    <div class="text-center">
                      <svg class="w-12 h-12 mx-auto text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                      </svg>
                      <p class="text-sm text-gray-500 mt-2">Image unavailable</p>
                    </div>
                  </div>
                `;
              }
            }}
          />
          {getStatusBadge(auction.status)}
        </div>
      ) : (
        <div className="relative h-48 w-full bg-gradient-to-br from-emerald-100 to-green-100 dark:from-emerald-900/30 dark:to-green-900/30 flex items-center justify-center">
          <div className="text-center">
            <ImageIcon className="w-16 h-16 mx-auto text-emerald-600 dark:text-emerald-400 opacity-50" />
            <p className="text-sm text-emerald-700 dark:text-emerald-300 mt-2">Lot #{auction.lotId}</p>
          </div>
          {getStatusBadge(auction.status)}
        </div>
      )}

      <div className="p-4">
        <div className="flex justify-between items-start mb-4">
          <div className="flex-1">
            <h3 className="text-xl font-semibold dark:text-white mb-1">Lot #{auction.lotId}</h3>
            {auction.variety && (
              <p className="text-sm text-gray-600 dark:text-gray-400">{auction.variety}</p>
            )}
          </div>
        </div>

        <div className="space-y-3 mb-4">
          {/* Farmer Name */}
          {auction.farmerName && (
            <div className="flex items-center gap-2 text-sm">
              <User className="w-4 h-4 text-gray-500 dark:text-gray-400" />
              <span className="font-medium text-gray-900 dark:text-white">{auction.farmerName}</span>
            </div>
          )}

          {/* Farm Location */}
          {auction.farmLocation && (
            <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400">
              <MapPin className="w-4 h-4" />
              <span className="truncate">{auction.farmLocation}</span>
            </div>
          )}

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
                {auction.startPrice ? parseFloat(auction.startPrice).toFixed(4) : '0.0000'} ETH
              </p>
              <p className="text-xs text-gray-500 mt-1">
                ≈ {auction.startPrice ? ethToLkr(parseFloat(auction.startPrice)) : 'LKR 0'}
              </p>
            </div>
            <div className="bg-gradient-to-br from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20 p-3 rounded-lg border border-green-200 dark:border-green-800">
              <p className="text-xs text-gray-600 dark:text-gray-400 mb-1">Current Bid</p>
              {auction.currentBid && auction.currentBid !== '0' ? (
                <>
                  <p className="text-lg font-bold text-green-600">
                    {parseFloat(auction.currentBid).toFixed(4)} ETH
                  </p>
                  <p className="text-xs text-gray-600 dark:text-gray-400 mt-1 font-medium">
                    ≈ {ethToLkr(parseFloat(auction.currentBid))}
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

          <button
            onClick={handleViewAuction}
            disabled={isNavigating}
            className="btn-primary w-full text-center flex items-center justify-center gap-2 disabled:opacity-70 disabled:cursor-not-allowed"
          >
            {isNavigating ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                Loading...
              </>
            ) : (
              'View Auction'
            )}
          </button>
        </div>
      </div>
    </div>
  );
}
