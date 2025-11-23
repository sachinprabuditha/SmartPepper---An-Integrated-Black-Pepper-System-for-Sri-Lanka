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
  const [stats, setStats] = useState({
    activeBids: 0,
    wonAuctions: 0,
    totalSpent: '0',
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

      // TODO: Load user's bids (need API endpoint)
      // For now, using placeholder
      setStats({
        activeBids: 0,
        wonAuctions: 0,
        totalSpent: '0',
        pendingDeliveries: 0,
      });
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
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">Quick Actions</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Link
              href="/auctions"
              className="bg-gradient-to-r from-blue-500 to-blue-600 text-white rounded-lg p-6 hover:from-blue-600 hover:to-blue-700 transition"
            >
              <div className="text-3xl mb-2">🔨</div>
              <div className="font-semibold">Browse Auctions</div>
              <div className="text-sm opacity-90">Find and bid on lots</div>
            </Link>
            <Link
              href="/dashboard/exporter/bids"
              className="bg-white border-2 border-gray-200 rounded-lg p-6 hover:border-blue-500 transition"
            >
              <div className="text-3xl mb-2">💰</div>
              <div className="font-semibold">My Bids</div>
              <div className="text-sm text-gray-600">Track your bids</div>
            </Link>
            <Link
              href="/dashboard/exporter/profile"
              className="bg-white border-2 border-gray-200 rounded-lg p-6 hover:border-blue-500 transition"
            >
              <div className="text-3xl mb-2">👤</div>
              <div className="font-semibold">My Profile</div>
              <div className="text-sm text-gray-600">Update your information</div>
            </Link>
          </div>
        </div>

        {/* Stats */}
        <div className="mb-8">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Statistics</h2>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div className="bg-white rounded-lg p-6 border border-gray-200">
              <div className="text-sm text-gray-600 mb-1">Active Bids</div>
              <div className="text-3xl font-bold text-blue-600">{stats.activeBids}</div>
            </div>
            <div className="bg-white rounded-lg p-6 border border-gray-200">
              <div className="text-sm text-gray-600 mb-1">Won Auctions</div>
              <div className="text-3xl font-bold text-green-600">{stats.wonAuctions}</div>
            </div>
            <div className="bg-white rounded-lg p-6 border border-gray-200">
              <div className="text-sm text-gray-600 mb-1">Total Spent</div>
              <div className="text-3xl font-bold text-gray-900">{stats.totalSpent} ETH</div>
            </div>
            <div className="bg-white rounded-lg p-6 border border-gray-200">
              <div className="text-sm text-gray-600 mb-1">Pending Deliveries</div>
              <div className="text-3xl font-bold text-orange-600">{stats.pendingDeliveries}</div>
            </div>
          </div>
        </div>

        {/* Active Auctions */}
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900">Active Auctions</h2>
            <Link href="/auctions" className="text-sm text-blue-600 hover:text-blue-700">
              View All →
            </Link>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {activeAuctions.slice(0, 6).map((auction: any) => (
              <div key={auction.auction_id || auction.auctionId} className="bg-white rounded-lg border border-gray-200 p-4 hover:shadow-lg transition">
                <div className="flex items-center justify-between mb-3">
                  <span className="text-sm font-medium text-gray-900">
                    {auction.lot_id || auction.lotId}
                  </span>
                  <span className="px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800">
                    Active
                  </span>
                </div>
                <div className="space-y-2 mb-4">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600">Current Bid:</span>
                    <span className="font-medium text-gray-900">
                      {(parseFloat(auction.current_bid || auction.currentBid || '0') / 1e18).toFixed(4)} ETH
                    </span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600">Reserve Price:</span>
                    <span className="font-medium text-gray-900">
                      {(parseFloat(auction.reserve_price || auction.reservePrice || '0') / 1e18).toFixed(4)} ETH
                    </span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600">Total Bids:</span>
                    <span className="font-medium text-gray-900">
                      {auction.bid_count || auction.bidCount || 0}
                    </span>
                  </div>
                </div>
                <Link
                  href={`/auctions/${auction.auction_id || auction.auctionId}`}
                  className="block w-full text-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700"
                >
                  Place Bid
                </Link>
              </div>
            ))}
            {activeAuctions.length === 0 && (
              <div className="col-span-full text-center py-12 text-gray-500">
                <div className="text-4xl mb-4">🔍</div>
                <p>No active auctions at the moment</p>
                <p className="text-sm mt-2">Check back soon for new pepper lots!</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
