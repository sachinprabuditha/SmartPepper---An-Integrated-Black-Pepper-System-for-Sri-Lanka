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

interface AuctionWithBids {
  auctionId: number;
  lotId: string;
  status: string;
  currentBid: string;
  highestBidder: string;
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

export default function MyBidsPage() {
  const { user, loading } = useAuth();
  const router = useRouter();
  const [bids, setBids] = useState<AuctionWithBids[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'active' | 'won' | 'lost'>('all');

  useEffect(() => {
    if (!loading && (!user || user.role !== 'exporter')) {
      router.push('/login');
    }
  }, [user, loading, router]);

  useEffect(() => {
    if (user?.id) {
      loadMyBids();
    }
  }, [user]);

  const loadMyBids = async () => {
    try {
      setIsLoading(true);
      
      if (!user?.id) {
        console.error('No user ID found');
        return;
      }

      console.log('Fetching bids for user ID:', user.id);
      const response = await auctionApi.getUserBids(user.id);
      console.log('User bids response:', response.data);
      
      const auctionsWithBids = response.data?.auctions || [];
      setBids(auctionsWithBids);
    } catch (error: any) {
      console.error('Failed to load bids:', error);
      console.error('Error details:', error.response?.data || error.message);
    } finally {
      setIsLoading(false);
    }
  };

  const getFilteredBids = () => {
    switch (filter) {
      case 'active':
        return bids.filter(b => b.status === 'active');
      case 'won':
        return bids.filter(b => b.status === 'ended' && b.isLeading);
      case 'lost':
        return bids.filter(b => b.status === 'ended' && !b.isLeading);
      default:
        return bids;
    }
  };

  const formatAmount = (amount: string) => {
    // Database stores amounts in ETH already, not Wei
    const value = parseFloat(amount || '0');
    return value.toFixed(4);
  };

  const getStatusBadge = (auction: AuctionWithBids) => {
    if (auction.status === 'active') {
      return auction.isLeading ? (
        <span className="px-3 py-1 text-sm font-semibold rounded-full bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
          🏆 Leading
        </span>
      ) : (
        <span className="px-3 py-1 text-sm font-semibold rounded-full bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200">
          💰 Active
        </span>
      );
    }
    
    if (auction.status === 'ended') {
      return auction.isLeading ? (
        <span className="px-3 py-1 text-sm font-semibold rounded-full bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200">
          ✅ Won
        </span>
      ) : (
        <span className="px-3 py-1 text-sm font-semibold rounded-full bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300">
          ❌ Lost
        </span>
      );
    }

    return (
      <span className="px-3 py-1 text-sm font-semibold rounded-full bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400">
        {auction.status}
      </span>
    );
  };

  if (loading || isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600 dark:text-gray-400">Loading your bids...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return null;
  }

  const filteredBids = getFilteredBids();
  const activeBidsCount = bids.filter(b => b.status === 'active').length;
  const wonAuctionsCount = bids.filter(b => b.status === 'ended' && b.isLeading).length;
  const totalSpent = bids
    .filter(b => b.status === 'ended' && b.isLeading)
    .reduce((sum, b) => sum + parseFloat(formatAmount(b.currentBid)), 0);

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <Link href="/dashboard/exporter" className="text-blue-600 hover:text-blue-700 mb-4 inline-block">
            ← Back to Dashboard
          </Link>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">💰 My Bids</h1>
          <p className="text-gray-600 dark:text-gray-400 mt-2">Track all your bidding activity</p>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
            <div className="text-3xl mb-2">📊</div>
            <div className="text-2xl font-bold text-gray-900 dark:text-white">{bids.length}</div>
            <div className="text-sm text-gray-600 dark:text-gray-400">Total Auctions</div>
          </div>
          
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
            <div className="text-3xl mb-2">🎯</div>
            <div className="text-2xl font-bold text-blue-600">{activeBidsCount}</div>
            <div className="text-sm text-gray-600 dark:text-gray-400">Active Bids</div>
          </div>
          
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
            <div className="text-3xl mb-2">🏆</div>
            <div className="text-2xl font-bold text-green-600">{wonAuctionsCount}</div>
            <div className="text-sm text-gray-600 dark:text-gray-400">Won Auctions</div>
          </div>
          
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
            <div className="text-3xl mb-2">💵</div>
            <div className="text-2xl font-bold text-gray-900 dark:text-white">{totalSpent.toFixed(4)} ETH</div>
            <div className="text-sm text-gray-600 dark:text-gray-400">Total Spent</div>
          </div>
        </div>

        {/* Filters */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-4 mb-6">
          <div className="flex flex-wrap gap-3">
            <button
              onClick={() => setFilter('all')}
              className={`px-4 py-2 rounded-lg font-medium transition ${
                filter === 'all'
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300'
              }`}
            >
              All Bids ({bids.length})
            </button>
            <button
              onClick={() => setFilter('active')}
              className={`px-4 py-2 rounded-lg font-medium transition ${
                filter === 'active'
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300'
              }`}
            >
              Active ({activeBidsCount})
            </button>
            <button
              onClick={() => setFilter('won')}
              className={`px-4 py-2 rounded-lg font-medium transition ${
                filter === 'won'
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300'
              }`}
            >
              Won ({wonAuctionsCount})
            </button>
            <button
              onClick={() => setFilter('lost')}
              className={`px-4 py-2 rounded-lg font-medium transition ${
                filter === 'lost'
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300'
              }`}
            >
              Lost ({bids.filter(b => b.status === 'ended' && !b.isLeading).length})
            </button>
          </div>
        </div>

        {/* Bids List */}
        {filteredBids.length === 0 ? (
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-12 text-center">
            <div className="text-6xl mb-4">📭</div>
            <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">No bids found</h3>
            <p className="text-gray-600 dark:text-gray-400 mb-6">
              {filter === 'all' 
                ? "You haven't placed any bids yet. Start bidding on auctions!"
                : `No ${filter} bids found.`}
            </p>
            {filter === 'all' && (
              <Link
                href="/auctions"
                className="inline-block bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition"
              >
                Browse Auctions
              </Link>
            )}
          </div>
        ) : (
          <div className="space-y-4">
            {filteredBids.map((auction) => (
              <div
                key={auction.auctionId}
                className="bg-white dark:bg-gray-800 rounded-lg shadow hover:shadow-lg transition"
              >
                <div className="p-6">
                  <div className="flex justify-between items-start mb-4">
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <h3 className="text-xl font-bold text-gray-900 dark:text-white">
                          {auction.variety} - {auction.quality}
                        </h3>
                        {getStatusBadge(auction)}
                      </div>
                      <div className="flex items-center gap-4 text-sm text-gray-600 dark:text-gray-400">
                        <span>📦 Lot: {auction.lotId}</span>
                        <span>⚖️ {auction.quantity} kg</span>
                        <span>🆔 Auction #{auction.auctionId}</span>
                      </div>
                    </div>
                    <Link
                      href={`/auctions/${auction.auctionId}`}
                      className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition text-sm font-medium"
                    >
                      View Auction →
                    </Link>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                    <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
                      <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">My Highest Bid</div>
                      <div className="text-lg font-bold text-gray-900 dark:text-white">
                        {formatAmount(auction.myHighestBid)} ETH
                      </div>
                      <div className="text-sm text-gray-600 dark:text-gray-400">
                        LKR {parseFloat(auction.myHighestBidLkr || '0').toLocaleString()}
                      </div>
                    </div>

                    <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
                      <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Current Highest Bid</div>
                      <div className="text-lg font-bold text-gray-900 dark:text-white">
                        {formatAmount(auction.currentBid)} ETH
                      </div>
                      <div className="text-sm text-gray-600 dark:text-gray-400">
                        {auction.bidCount} total bids
                      </div>
                    </div>

                    <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
                      <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">
                        {auction.status === 'active' ? 'Ends' : 'Ended'}
                      </div>
                      <div className="text-lg font-bold text-gray-900 dark:text-white">
                        {auction.status === 'active' 
                          ? formatDistanceToNow(new Date(auction.endTime), { addSuffix: true })
                          : formatDistanceToNow(new Date(auction.endTime), { addSuffix: true })}
                      </div>
                    </div>
                  </div>

                  {/* Bid History */}
                  <details className="group">
                    <summary className="cursor-pointer text-blue-600 hover:text-blue-700 font-medium flex items-center gap-2">
                      <span className="group-open:rotate-90 transition-transform">▶</span>
                      My Bid History ({auction.myBids.length} bids)
                    </summary>
                    <div className="mt-4 space-y-2">
                      {auction.myBids.map((bid) => (
                        <div
                          key={bid.id}
                          className="flex justify-between items-center bg-gray-50 dark:bg-gray-700 rounded-lg p-3"
                        >
                          <div>
                            <div className="font-medium text-gray-900 dark:text-white">
                              {formatAmount(bid.amount)} {bid.currency}
                            </div>
                            <div className="text-sm text-gray-600 dark:text-gray-400">
                              LKR {parseFloat(bid.amountLkr || '0').toLocaleString()}
                            </div>
                          </div>
                          <div className="text-right">
                            <div className="text-sm text-gray-600 dark:text-gray-400">
                              {formatDistanceToNow(new Date(bid.placedAt), { addSuffix: true })}
                            </div>
                            <div className="text-xs text-gray-500 dark:text-gray-500">
                              {new Date(bid.placedAt).toLocaleString()}
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </details>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
