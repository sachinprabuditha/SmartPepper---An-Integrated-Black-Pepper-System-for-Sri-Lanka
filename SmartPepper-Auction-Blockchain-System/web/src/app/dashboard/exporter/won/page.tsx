'use client';

import { useAuth } from '@/contexts/AuthContext';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { auctionApi } from '@/lib/api';
import { formatDistanceToNow } from 'date-fns';

interface Bid {
  id: number;
  amount: string;
  amountLkr: string;
  currency: string;
  placedAt: string;
  status: string;
}

interface WonAuction {
  auctionId: number;
  lotId: string;
  status: string;
  currentBid: string;
  startTime: string;
  endTime: string;
  farmerAddress: string;
  reservePrice: string;
  bidCount: number;
  variety: string;
  quantity: number;
  quality: string;
  isLeading: boolean;
  myHighestBid: string;
  myHighestBidLkr: string;
  myBids: Bid[];
}

export default function WonAuctionsPage() {
  const { user, loading } = useAuth();
  const router = useRouter();
  const [wonAuctions, setWonAuctions] = useState<WonAuction[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (!loading && (!user || user.role !== 'exporter')) {
      router.push('/login');
    }
  }, [user, loading, router]);

  useEffect(() => {
    if (user) {
      loadWonAuctions();
    }
  }, [user]);

  const loadWonAuctions = async () => {
    try {
      setIsLoading(true);
      
      if (!user?.id) {
        console.error('No user ID found');
        return;
      }

      console.log('Fetching won auctions for user ID:', user.id);
      const response = await auctionApi.getUserBids(user.id);
      console.log('User bids response:', response.data);
      
      // Filter only won auctions (status = 'ended' and isLeading = true)
      const auctionsWithBids = response.data?.auctions || [];
      const won = auctionsWithBids.filter((auction: WonAuction) => 
        auction.status === 'ended' && auction.isLeading
      );
      
      setWonAuctions(won);
    } catch (error: any) {
      console.error('Failed to load won auctions:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const formatAmount = (amount: string) => {
    const value = parseFloat(amount || '0');
    return value.toFixed(4);
  };

  const calculateTotalSpent = () => {
    return wonAuctions.reduce((sum, auction) => 
      sum + parseFloat(auction.currentBid || '0'), 0
    ).toFixed(4);
  };

  const calculateTotalSpentLkr = () => {
    return wonAuctions.reduce((sum, auction) => 
      sum + parseFloat(auction.myHighestBidLkr || '0'), 0
    ).toFixed(2);
  };

  if (loading || isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600 dark:text-gray-400">Loading won auctions...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return null;
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <Link 
            href="/dashboard/exporter" 
            className="text-blue-600 hover:text-blue-700 text-sm mb-4 inline-block"
          >
            ← Back to Dashboard
          </Link>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">🏆 Won Auctions</h1>
          <p className="text-gray-600 dark:text-gray-400 mt-2">
            View your successfully won pepper lots and manage payments
          </p>
        </div>

        {/* Summary Stats */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
            <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Total Won Auctions</div>
            <div className="text-3xl font-bold text-green-600">{wonAuctions.length}</div>
            <div className="text-xs text-gray-500 mt-1">Successfully acquired lots</div>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
            <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Total Spent</div>
            <div className="text-2xl font-bold text-gray-900 dark:text-white">{calculateTotalSpent()} ETH</div>
            <div className="text-sm text-gray-600 dark:text-gray-400 mt-1">
              ≈ LKR {parseFloat(calculateTotalSpentLkr()).toLocaleString()}
            </div>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
            <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Average Price</div>
            <div className="text-2xl font-bold text-gray-900 dark:text-white">
              {wonAuctions.length > 0 ? (parseFloat(calculateTotalSpent()) / wonAuctions.length).toFixed(4) : '0.0000'} ETH
            </div>
            <div className="text-xs text-gray-500 mt-1">Per lot</div>
          </div>
        </div>

        {/* Won Auctions List */}
        <div className="space-y-4">
          {wonAuctions.length === 0 ? (
            <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-12 text-center">
              <div className="text-4xl mb-4">🎯</div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                No Won Auctions Yet
              </h3>
              <p className="text-gray-600 dark:text-gray-400 mb-4">
                You haven't won any auctions yet. Keep bidding to win great pepper lots!
              </p>
              <Link
                href="/auctions"
                className="inline-block px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
              >
                Browse Active Auctions
              </Link>
            </div>
          ) : (
            wonAuctions.map((auction) => (
              <div 
                key={auction.auctionId} 
                className="bg-white dark:bg-gray-800 rounded-lg shadow border border-gray-200 dark:border-gray-700 overflow-hidden"
              >
                <div className="p-6">
                  <div className="flex items-start justify-between mb-4">
                    <div>
                      <div className="flex items-center gap-3 mb-2">
                        <h3 className="text-xl font-bold text-gray-900 dark:text-white">
                          {auction.variety || 'Pepper Lot'}
                        </h3>
                        <span className="px-3 py-1 text-sm font-semibold rounded-full bg-yellow-100 dark:bg-yellow-900 text-yellow-800 dark:text-yellow-200">
                          ✅ Won
                        </span>
                      </div>
                      <div className="flex items-center gap-4 text-sm text-gray-600 dark:text-gray-400">
                        <span>📦 Lot: {auction.lotId}</span>
                        <span>⚖️ {auction.quantity} kg</span>
                        <span>⭐ {auction.quality}</span>
                      </div>
                    </div>
                    <Link
                      href={`/auctions/${auction.auctionId}`}
                      className="px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700 transition"
                    >
                      View Details →
                    </Link>
                  </div>

                  {/* Winning Bid Info */}
                  <div className="bg-green-50 dark:bg-green-900/20 rounded-lg p-4 mb-4">
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                      <div>
                        <div className="text-xs text-gray-600 dark:text-gray-400 mb-1">Your Winning Bid</div>
                        <div className="text-2xl font-bold text-green-600">
                          {formatAmount(auction.myHighestBid)} ETH
                        </div>
                        <div className="text-sm text-gray-600 dark:text-gray-400">
                          ≈ LKR {parseFloat(auction.myHighestBidLkr || '0').toLocaleString()}
                        </div>
                      </div>
                      <div>
                        <div className="text-xs text-gray-600 dark:text-gray-400 mb-1">Total Bids Placed</div>
                        <div className="text-2xl font-bold text-gray-900 dark:text-white">
                          {auction.myBids?.length || 0}
                        </div>
                        <div className="text-sm text-gray-600 dark:text-gray-400">
                          By you
                        </div>
                      </div>
                      <div>
                        <div className="text-xs text-gray-600 dark:text-gray-400 mb-1">Auction Ended</div>
                        <div className="text-lg font-bold text-gray-900 dark:text-white">
                          {formatDistanceToNow(new Date(auction.endTime), { addSuffix: true })}
                        </div>
                        <div className="text-sm text-gray-600 dark:text-gray-400">
                          {new Date(auction.endTime).toLocaleString()}
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Payment & Delivery Status */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                    <div className="border border-orange-200 dark:border-orange-800 rounded-lg p-4">
                      <div className="flex items-center gap-2 mb-2">
                        <span className="text-2xl">💳</span>
                        <span className="font-semibold text-gray-900 dark:text-white">Escrow Status</span>
                      </div>
                      <span className="px-3 py-1 text-sm font-semibold rounded-full bg-orange-100 dark:bg-orange-900 text-orange-800 dark:text-orange-200">
                        Escrow Required
                      </span>
                      <Link
                        href={`/dashboard/exporter/won/${auction.auctionId}/escrow`}
                        className="mt-3 block w-full text-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700 transition"
                      >
                        💰 Deposit Escrow
                      </Link>
                    </div>
                    <div className="border border-blue-200 dark:border-blue-800 rounded-lg p-4">
                      <div className="flex items-center gap-2 mb-2">
                        <span className="text-2xl">🚚</span>
                        <span className="font-semibold text-gray-900 dark:text-white">Delivery Status</span>
                      </div>
                      <span className="px-3 py-1 text-sm font-semibold rounded-full bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200">
                        Awaiting Escrow
                      </span>
                    </div>
                  </div>

                  {/* Farmer Info */}
                  <div className="border-t border-gray-200 dark:border-gray-700 pt-4">
                    <div className="text-sm text-gray-600 dark:text-gray-400">
                      Farmer: <span className="font-mono text-gray-900 dark:text-white">{auction.farmerAddress}</span>
                    </div>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
