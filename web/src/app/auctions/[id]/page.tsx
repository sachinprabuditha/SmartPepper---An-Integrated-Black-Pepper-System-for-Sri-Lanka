'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import { useAccount, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther } from 'viem';
import { auctionApi } from '@/lib/api';
import { useAuctionStore, Auction, Bid } from '@/store/auctionStore';
import { PEPPER_AUCTION_ABI, CONTRACT_ADDRESS } from '@/config/contracts';
import { AuctionTimer } from '@/components/auction/AuctionTimer';
import { BidHistory } from '@/components/auction/BidHistory';
import { BidForm } from '@/components/auction/BidForm';
import { Loader2, CheckCircle, XCircle, User, Package, Calendar } from 'lucide-react';
import toast from 'react-hot-toast';

export default function AuctionDetailPage() {
  const params = useParams();
  const auctionId = params.id as string;
  const { address } = useAccount();
  
  const [auction, setAuction] = useState<Auction | null>(null);
  const [bids, setBids] = useState<Bid[]>([]);
  const [loading, setLoading] = useState(true);
  
  const { joinAuction, leaveAuction, connected } = useAuctionStore();

  useEffect(() => {
    async function fetchAuction() {
      try {
        setLoading(true);
        const response = await auctionApi.getById(parseInt(auctionId));
        setAuction(response.data.auction);
        setBids(response.data.bids || []);
      } catch (error) {
        console.error('Failed to fetch auction:', error);
        toast.error('Failed to load auction details');
      } finally {
        setLoading(false);
      }
    }

    if (auctionId) {
      fetchAuction();
    }
  }, [auctionId]);

  useEffect(() => {
    if (auction && address && connected) {
      joinAuction(auction.auctionId, address);
      
      return () => {
        leaveAuction(auction.auctionId, address);
      };
    }
  }, [auction, address, connected, joinAuction, leaveAuction]);

  if (loading) {
    return (
      <div className="container mx-auto px-4 py-12">
        <div className="flex justify-center items-center min-h-[400px]">
          <Loader2 className="w-12 h-12 animate-spin text-primary-600" />
        </div>
      </div>
    );
  }

  if (!auction) {
    return (
      <div className="container mx-auto px-4 py-12">
        <div className="card text-center py-12">
          <p className="text-xl text-gray-600 dark:text-gray-400">Auction not found</p>
        </div>
      </div>
    );
  }

  const isFarmer = address?.toLowerCase() === auction.farmerAddress.toLowerCase();
  const isActive = auction.status === 'active';
  const hasEnded = new Date(auction.endTime) <= new Date();

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="grid lg:grid-cols-3 gap-8">
        {/* Main Auction Details */}
        <div className="lg:col-span-2 space-y-6">
          {/* Header */}
          <div className="card">
            <div className="flex justify-between items-start mb-6">
              <div>
                <h1 className="text-3xl font-bold mb-2">Auction #{auction.auctionId}</h1>
                <p className="text-gray-600 dark:text-gray-400">Lot ID: {auction.lotId}</p>
              </div>
              <div className="text-right">
                {isActive && (
                  <span className="badge-success flex items-center gap-2">
                    <span className="inline-block w-2 h-2 bg-green-500 rounded-full animate-pulse"></span>
                    Live Auction
                  </span>
                )}
                {auction.status === 'ended' && <span className="badge-warning">Ended</span>}
                {auction.status === 'settled' && <span className="badge-info">Settled</span>}
              </div>
            </div>

            {/* Compliance Status */}
            <div className="flex items-center gap-3 mb-6 p-4 bg-gray-50 dark:bg-gray-900 rounded-lg">
              {auction.compliancePassed ? (
                <>
                  <CheckCircle className="w-6 h-6 text-green-600" />
                  <div>
                    <p className="font-semibold text-green-700 dark:text-green-400">Compliance Passed</p>
                    <p className="text-sm text-gray-600 dark:text-gray-400">All certifications verified</p>
                  </div>
                </>
              ) : (
                <>
                  <XCircle className="w-6 h-6 text-red-600" />
                  <div>
                    <p className="font-semibold text-red-700 dark:text-red-400">Compliance Pending</p>
                    <p className="text-sm text-gray-600 dark:text-gray-400">Awaiting certificate validation</p>
                  </div>
                </>
              )}
            </div>

            {/* Auction Details */}
            <div className="grid md:grid-cols-2 gap-6">
              <div className="space-y-4">
                <div className="flex items-center gap-3">
                  <User className="w-5 h-5 text-gray-500" />
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Farmer</p>
                    <p className="font-mono text-sm">{auction.farmerAddress}</p>
                  </div>
                </div>

                <div className="flex items-center gap-3">
                  <Calendar className="w-5 h-5 text-gray-500" />
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">End Time</p>
                    <p className="font-medium">{new Date(auction.endTime).toLocaleString()}</p>
                  </div>
                </div>
              </div>

              <div className="space-y-4">
                <div className="flex items-center gap-3">
                  <Package className="w-5 h-5 text-gray-500" />
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Total Bids</p>
                    <p className="text-2xl font-bold text-primary-600">{auction.bidCount}</p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Pricing Information */}
          <div className="card">
            <h2 className="text-xl font-semibold mb-4">Pricing</h2>
            <div className="grid md:grid-cols-3 gap-6">
              <div>
                <p className="text-sm text-gray-500 dark:text-gray-400 mb-1">Start Price</p>
                <p className="text-2xl font-bold text-gray-700 dark:text-gray-300">
                  {parseFloat(auction.startPrice).toFixed(4)} ETH
                </p>
              </div>
              <div>
                <p className="text-sm text-gray-500 dark:text-gray-400 mb-1">Reserve Price</p>
                <p className="text-2xl font-bold text-gray-700 dark:text-gray-300">
                  {parseFloat(auction.reservePrice).toFixed(4)} ETH
                </p>
              </div>
              <div>
                <p className="text-sm text-gray-500 dark:text-gray-400 mb-1">Current Bid</p>
                <p className="text-3xl font-bold text-green-600">
                  {auction.currentBid !== '0' 
                    ? `${parseFloat(auction.currentBid).toFixed(4)} ETH`
                    : 'No bids yet'
                  }
                </p>
              </div>
            </div>
          </div>

          {/* Bid History */}
          <div className="card">
            <h2 className="text-xl font-semibold mb-4">Bid History</h2>
            <BidHistory auctionId={auction.auctionId} bids={bids} />
          </div>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Timer */}
          {isActive && !hasEnded && (
            <div className="card">
              <h3 className="text-lg font-semibold mb-4">Time Remaining</h3>
              <AuctionTimer endTime={auction.endTime} />
            </div>
          )}

          {/* Bid Form */}
          {isActive && !hasEnded && !isFarmer && (
            <div className="card">
              <h3 className="text-lg font-semibold mb-4">Place Your Bid</h3>
              <BidForm auction={auction} />
            </div>
          )}

          {/* Farmer Actions */}
          {isFarmer && (
            <div className="card">
              <h3 className="text-lg font-semibold mb-4">Farmer Actions</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
                You are the owner of this auction
              </p>
              {hasEnded && auction.status === 'active' && (
                <button className="btn-primary w-full">
                  End Auction
                </button>
              )}
              {auction.status === 'ended' && (
                <button className="btn-success w-full">
                  Settle Auction
                </button>
              )}
            </div>
          )}

          {/* Transaction Info */}
          {auction.blockchainTxHash && (
            <div className="card">
              <h3 className="text-lg font-semibold mb-4">Blockchain</h3>
              <div className="space-y-2">
                <p className="text-sm text-gray-500 dark:text-gray-400">Transaction Hash</p>
                <p className="font-mono text-xs break-all">{auction.blockchainTxHash}</p>
                <a
                  href={`https://sepolia.etherscan.io/tx/${auction.blockchainTxHash}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-primary-600 hover:underline text-sm"
                >
                  View on Etherscan →
                </a>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
