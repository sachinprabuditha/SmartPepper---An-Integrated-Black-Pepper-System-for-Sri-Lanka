'use client';

import { useAuth } from '@/contexts/AuthContext';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { auctionApi } from '@/lib/api';

export default function ExporterDashboard() {
  const { user, logout, loading } = useAuth();
  const router = useRouter();
  const [activeAuctions, setActiveAuctions] = useState([]);
  const [myBids, setMyBids] = useState([]);
  const [recentActivity, setRecentActivity] = useState<any[]>([]);
  const [stats, setStats] = useState({
    activeBids: 0,
    wonAuctions: 0,
    totalSpent: '0',
    totalSpentLkr: '0',
    pendingDeliveries: 0,
  });

  useEffect(() => {
    if (!loading && (!user || user.role !== 'exporter')) {
      router.push('/login');
    }
  }, [user, loading, router]);

  useEffect(() => {
    if (user) {
      loadDashboardData();
    }
  }, [user]);

  const loadDashboardData = async () => {
    try {
      // Load all active auctions
      const auctionsResponse = await auctionApi.getAll({ status: 'active' });
      setActiveAuctions(auctionsResponse.data.auctions || []);

      // Load user's bids and calculate stats
      if (user?.id) {
        try {
          const userBidsResponse = await auctionApi.getUserBids(user.id);
          const auctionsWithBids = userBidsResponse.data.auctions || [];
          
          // Calculate statistics
          let activeBids = 0;
          let wonAuctions = 0;
          let totalSpent = 0;
          let totalSpentLkr = 0;
          let pendingDeliveries = 0;
          const activity: any[] = [];

          for (const auction of auctionsWithBids) {
            // Count active bids (where auction is still running and user has placed bids)
            if (auction.status === 'active' && auction.myBids?.length > 0) {
              activeBids++;
              
              // Add to recent activity
              const latestBid = auction.myBids[0];
              activity.push({
                type: 'bid',
                status: auction.isLeading ? 'leading' : 'active',
                auctionId: auction.auctionId,
                lotId: auction.lotId,
                variety: auction.variety,
                amount: latestBid.amount,
                amountLkr: latestBid.amountLkr,
                timestamp: latestBid.placedAt,
              });
            }

            // Count won auctions and calculate spent amount
            if (auction.status === 'ended' && auction.isLeading) {
              wonAuctions++;
              // Database stores amounts in ETH already, not Wei
              totalSpent += parseFloat(auction.currentBid || '0');
              totalSpentLkr += parseFloat(auction.myHighestBidLkr || '0');
              
              // Assume delivery is pending if auction was won
              // TODO: Update this when payment/delivery status is tracked in DB
              pendingDeliveries++;
              
              // Add to recent activity
              activity.push({
                type: 'won',
                status: 'won',
                auctionId: auction.auctionId,
                lotId: auction.lotId,
                variety: auction.variety,
                amount: auction.currentBid,
                amountLkr: auction.myHighestBidLkr,
                timestamp: auction.endTime,
              });
            }
          }

          // Sort activity by timestamp (most recent first)
          activity.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
          setRecentActivity(activity.slice(0, 5)); // Keep only 5 most recent

          setStats({
            activeBids,
            wonAuctions,
            totalSpent: totalSpent.toFixed(4),
            totalSpentLkr: totalSpentLkr.toFixed(2),
            pendingDeliveries,
          });
        } catch (error) {
          console.error('Failed to load user bids:', error);
          // Keep placeholder stats if user bids fail to load
          setStats({
            activeBids: 0,
            wonAuctions: 0,
            totalSpent: '0',
            totalSpentLkr: '0',
            pendingDeliveries: 0,
          });
        }
      }
    } catch (error) {
      console.error('Failed to load dashboard data:', error);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!user) {
    return null;
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Page Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">🏢 Exporter Dashboard</h1>
          <p className="text-gray-600 dark:text-gray-400 mt-2">Welcome back, {user.name}! Browse auctions and manage your bids.</p>
        </div>
        {/* Quick Actions */}
        <div className="mb-8">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">⚡ Quick Actions</h2>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <Link
              href="/auctions"
              className="bg-gradient-to-r from-blue-500 to-blue-600 text-white rounded-lg p-6 hover:from-blue-600 hover:to-blue-700 transition shadow-lg"
            >
              <div className="text-3xl mb-2">🔨</div>
              <div className="font-semibold text-lg">Browse Auctions</div>
              <div className="text-sm opacity-90 mt-1">Find and bid on pepper lots</div>
            </Link>
            <Link
              href="/dashboard/exporter/bids"
              className="bg-white dark:bg-gray-800 border-2 border-gray-200 dark:border-gray-700 rounded-lg p-6 hover:border-blue-500 dark:hover:border-blue-500 transition"
            >
              <div className="text-3xl mb-2">💰</div>
              <div className="font-semibold text-lg text-gray-900 dark:text-white">My Bids</div>
              <div className="text-sm text-gray-600 dark:text-gray-400 mt-1">Track active & won bids</div>
            </Link>
            <Link
              href="/dashboard/exporter/won"
              className="bg-white dark:bg-gray-800 border-2 border-gray-200 dark:border-gray-700 rounded-lg p-6 hover:border-green-500 dark:hover:border-green-500 transition"
            >
              <div className="text-3xl mb-2">🏆</div>
              <div className="font-semibold text-lg text-gray-900 dark:text-white">Won Auctions</div>
              <div className="text-sm text-gray-600 dark:text-gray-400 mt-1">View won lots & payments</div>
            </Link>
            <Link
              href="/dashboard/exporter/profile"
              className="bg-white dark:bg-gray-800 border-2 border-gray-200 dark:border-gray-700 rounded-lg p-6 hover:border-purple-500 dark:hover:border-purple-500 transition"
            >
              <div className="text-3xl mb-2">👤</div>
              <div className="font-semibold text-lg text-gray-900 dark:text-white">My Profile</div>
              <div className="text-sm text-gray-600 dark:text-gray-400 mt-1">Update your information</div>
            </Link>
          </div>
        </div>

        {/* Stats */}
        <div className="mb-8">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">📊 Statistics</h2>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div className="bg-white dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
              <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Active Bids</div>
              <div className="text-3xl font-bold text-blue-600">{stats.activeBids}</div>
              <div className="text-xs text-gray-500 mt-1">Auctions you're bidding on</div>
            </div>
            <div className="bg-white dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
              <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Won Auctions</div>
              <div className="text-3xl font-bold text-green-600">{stats.wonAuctions}</div>
              <div className="text-xs text-gray-500 mt-1">Successfully acquired lots</div>
            </div>
            <div className="bg-white dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
              <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Total Spent</div>
              <div className="text-2xl font-bold text-gray-900 dark:text-white">{stats.totalSpent} ETH</div>
              <div className="text-sm text-gray-600 dark:text-gray-400 mt-1">≈ LKR {parseFloat(stats.totalSpentLkr).toLocaleString()}</div>
            </div>
            <div className="bg-white dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
              <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Pending Deliveries</div>
              <div className="text-3xl font-bold text-orange-600">{stats.pendingDeliveries}</div>
              <div className="text-xs text-gray-500 mt-1">Awaiting fulfillment</div>
            </div>
          </div>
        </div>

        {/* Recent Activity */}
        {recentActivity.length > 0 && (
          <div className="mb-8">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">🔔 Recent Activity</h2>
            <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 divide-y divide-gray-200 dark:divide-gray-700">
              {recentActivity.map((activity, index) => (
                <div key={index} className="p-4 hover:bg-gray-50 dark:hover:bg-gray-700 transition">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        {activity.status === 'leading' && (
                          <span className="px-2 py-1 text-xs font-semibold rounded-full bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200">
                            🏆 Leading
                          </span>
                        )}
                        {activity.status === 'active' && (
                          <span className="px-2 py-1 text-xs font-semibold rounded-full bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200">
                            💰 Active Bid
                          </span>
                        )}
                        {activity.status === 'won' && (
                          <span className="px-2 py-1 text-xs font-semibold rounded-full bg-yellow-100 dark:bg-yellow-900 text-yellow-800 dark:text-yellow-200">
                            ✅ Won
                          </span>
                        )}
                        <span className="text-sm font-medium text-gray-900 dark:text-white">
                          {activity.variety} - {activity.lotId}
                        </span>
                      </div>
                      <div className="flex items-center gap-4 text-sm text-gray-600 dark:text-gray-400">
                        <span className="font-medium">
                          {parseFloat(activity.amount || '0').toFixed(4)} ETH
                        </span>
                        <span>
                          ≈ LKR {parseFloat(activity.amountLkr || '0').toLocaleString()}
                        </span>
                        <span className="text-xs">
                          {new Date(activity.timestamp).toLocaleString()}
                        </span>
                      </div>
                    </div>
                    <Link
                      href={`/auctions/${activity.auctionId}`}
                      className="ml-4 text-blue-600 hover:text-blue-700 text-sm font-medium"
                    >
                      View →
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Active Auctions */}
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">🔨 Active Auctions</h2>
            <Link href="/auctions" className="text-sm text-blue-600 hover:text-blue-700">
              View All →
            </Link>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {activeAuctions.slice(0, 6).map((auction: any) => {
              // Database stores amounts in ETH already, not Wei
              const currentBidEth = parseFloat(auction.current_bid || auction.currentBid || '0');
              const reservePriceEth = parseFloat(auction.reserve_price || auction.reservePrice || '0');
              const bidCount = auction.bid_count || auction.bidCount || 0;
              
              return (
                <div 
                  key={auction.auction_id || auction.auctionId} 
                  className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 hover:shadow-lg transition"
                >
                  <div className="flex items-center justify-between mb-3">
                    <div>
                      <div className="text-sm font-medium text-gray-900 dark:text-white">
                        {auction.variety || 'Pepper Lot'}
                      </div>
                      <div className="text-xs text-gray-500">
                        Lot: {auction.lot_id || auction.lotId}
                      </div>
                    </div>
                    <span className="px-2 py-1 text-xs font-semibold rounded-full bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200">
                      🟢 Live
                    </span>
                  </div>
                  
                  <div className="space-y-2 mb-4">
                    <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-3">
                      <div className="text-xs text-gray-600 dark:text-gray-400 mb-1">Current Bid</div>
                      <div className="text-lg font-bold text-blue-600">
                        {currentBidEth.toFixed(4)} ETH
                      </div>
                      {auction.currency === 'LKR' && (
                        <div className="text-xs text-gray-600 dark:text-gray-400">
                          ≈ LKR {(currentBidEth * 322580.65).toFixed(2)}
                        </div>
                      )}
                    </div>
                    
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-600 dark:text-gray-400">Quality:</span>
                      <span className="font-medium text-gray-900 dark:text-white">
                        {auction.quality || 'N/A'}
                      </span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-600 dark:text-gray-400">Quantity:</span>
                      <span className="font-medium text-gray-900 dark:text-white">
                        {auction.quantity || 0} kg
                      </span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-600 dark:text-gray-400">Total Bids:</span>
                      <span className="font-medium text-gray-900 dark:text-white">
                        {bidCount} {bidCount === 1 ? 'bid' : 'bids'}
                      </span>
                    </div>
                  </div>
                  
                  <Link
                    href={`/auctions/${auction.auction_id || auction.auctionId}`}
                    className="block w-full text-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700 transition"
                  >
                    🔨 Place Bid
                  </Link>
                </div>
              );
            })}
            {activeAuctions.length === 0 && (
              <div className="col-span-full text-center py-12 text-gray-500 dark:text-gray-400">
                <div className="text-4xl mb-4">🔍</div>
                <p className="font-medium">No active auctions at the moment</p>
                <p className="text-sm mt-2">Check back soon for new pepper lots!</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
