'use client';

import { useAuth } from '@/contexts/AuthContext';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { useAccount } from 'wagmi';
import Link from 'next/link';
import { lotApi, auctionApi } from '@/lib/api';

// Helper function to convert snake_case to camelCase
function toCamelCase(obj: any): any {
  if (Array.isArray(obj)) {
    return obj.map(toCamelCase);
  } else if (obj !== null && typeof obj === 'object') {
    return Object.keys(obj).reduce((acc, key) => {
      const camelKey = key.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
      acc[camelKey] = toCamelCase(obj[key]);
      return acc;
    }, {} as any);
  }
  return obj;
}

export default function FarmerDashboard() {
  const { user, logout, loading } = useAuth();
  const { address: connectedAddress } = useAccount();
  const router = useRouter();
  const [lots, setLots] = useState([]);
  const [auctions, setAuctions] = useState([]);
  const [dataLoading, setDataLoading] = useState(true);
  const [stats, setStats] = useState({
    totalLots: 0,
    activeAuctions: 0,
    totalRevenue: '0',
    pendingSettlements: 0,
    pendingCompliance: 0,
  });

  // Use connected wallet address or stored wallet address
  const farmerAddress = user?.walletAddress || connectedAddress;

  useEffect(() => {
    if (!loading && (!user || user.role !== 'farmer')) {
      router.push('/login');
    }
  }, [user, loading, router]);

  useEffect(() => {
    console.log('Dashboard Effect - User:', user);
    console.log('Dashboard Effect - Connected Address:', connectedAddress);
    console.log('Dashboard Effect - Final Farmer Address:', farmerAddress);
    
    if (user && farmerAddress) {
      loadDashboardData();
    } else {
      console.warn('Cannot load data - Missing user or farmer address');
    }
  }, [user, farmerAddress]);

  const loadDashboardData = async () => {
    if (!farmerAddress) {
      console.warn('No farmer address available');
      setDataLoading(false);
      return;
    }

    try {
      setDataLoading(true);
      console.log('Loading dashboard data for farmer:', farmerAddress);
      console.log('User object:', user);
      
      // Load farmer's lots
      const lotsResponse = await lotApi.getAll({ farmer: farmerAddress, limit: 5 });
      console.log('Lots API called with:', { farmer: farmerAddress });
      console.log('Lots response:', lotsResponse.data);
      console.log('Lots count:', lotsResponse.data.count);
      console.log('Lots array length:', lotsResponse.data.lots?.length);
      const transformedLots = toCamelCase(lotsResponse.data.lots || []);
      console.log('Transformed lots:', transformedLots);
      setLots(transformedLots);

      // Load farmer's auctions (all statuses for display)
      const auctionsResponse = await auctionApi.getAll({ farmer: farmerAddress, limit: 10 });
      console.log('Auctions API called with:', { farmer: farmerAddress });
      console.log('Auctions response:', auctionsResponse.data);
      console.log('Auctions count:', auctionsResponse.data.count);
      console.log('Auctions array length:', auctionsResponse.data.auctions?.length);
      console.log('Raw auctions data:', auctionsResponse.data.auctions);
      const transformedAuctions = toCamelCase(auctionsResponse.data.auctions || []);
      console.log('Transformed auctions:', transformedAuctions);
      console.log('First auction (if exists):', transformedAuctions[0]);
      setAuctions(transformedAuctions);

      // Get active auctions count from separate query
      const activeAuctionsResponse = await auctionApi.getAll({ 
        farmer: farmerAddress, 
        status: 'active',
        limit: 1000 
      });
      
      // Calculate stats
      const totalLots = lotsResponse.data.count || 0;
      const activeAuctionsCount = activeAuctionsResponse.data.count || 0;
      
      // Get all auctions and filter for compliance_passed = false
      const allAuctionsForCompliance = await auctionApi.getAll({ 
        farmer: farmerAddress,
        limit: 1000
      });
      const allAuctionsData = toCamelCase(allAuctionsForCompliance.data.auctions || []);
      
      // Count auctions where compliance_passed = false
      const pendingComplianceCount = allAuctionsData.filter((auction: any) => 
        auction.compliancePassed === false
      ).length;
      
      console.log('Pending compliance breakdown:', {
        total_auctions: allAuctionsData.length,
        pending_compliance: pendingComplianceCount,
        auctions_with_compliance_false: allAuctionsData.filter((a: any) => !a.compliancePassed).map((a: any) => a.auctionId)
      });
      
      // Calculate total revenue from settled auctions
      const settledAuctionsResponse = await auctionApi.getAll({ 
        farmer: farmerAddress, 
        status: 'settled',
        limit: 1000
      });
      const settledAuctions = toCamelCase(settledAuctionsResponse.data.auctions || []);
      const totalRevenue = settledAuctions.reduce((sum: number, auction: any) => {
        return sum + (parseFloat(auction.currentBid || '0') / 1e18);
      }, 0).toFixed(4);
      
      // Get ended but not settled auctions count
      // This includes both auctions with status='ended' AND active auctions past their end_time
      const endedAuctionsResponse = await auctionApi.getAll({ 
        farmer: farmerAddress, 
        status: 'ended',
        limit: 1000
      });
      
      // Also check for active auctions that have passed their end time
      const allActiveAuctionsResponse = await auctionApi.getAll({ 
        farmer: farmerAddress, 
        status: 'active',
        limit: 1000
      });
      const allActiveAuctions = toCamelCase(allActiveAuctionsResponse.data.auctions || []);
      const expiredActiveAuctions = allActiveAuctions.filter((auction: any) => {
        return new Date(auction.endTime) < new Date();
      });
      
      const totalPendingSettlements = (endedAuctionsResponse.data.count || 0) + expiredActiveAuctions.length;
      
      setStats({
        totalLots,
        activeAuctions: activeAuctionsCount,
        totalRevenue,
        pendingSettlements: totalPendingSettlements,
        pendingCompliance: pendingComplianceCount,
      });
      
      console.log('Stats calculated:', {
        totalLots,
        activeAuctions: activeAuctionsCount,
        totalRevenue,
        pendingSettlements: totalPendingSettlements,
        pendingCompliance: pendingComplianceCount,
        endedAuctions: endedAuctionsResponse.data.count,
        expiredActiveAuctions: expiredActiveAuctions.length,
      });
    } catch (error) {
      console.error('Failed to load dashboard data:', error);
    } finally {
      setDataLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600"></div>
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
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">🌾 Farmer Dashboard</h1>
          <p className="text-gray-600 dark:text-gray-400 mt-2">Welcome back, {user.name}! Manage your pepper lots and auctions.</p>
          {!farmerAddress && (
            <div className="mt-4 p-4 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
              <p className="text-yellow-800 dark:text-yellow-200 text-sm">
                ⚠️ Please connect your wallet to view your lots and auctions. Your wallet address: <span className="font-mono">{connectedAddress || 'Not connected'}</span>
              </p>
            </div>
          )}
        </div>
        {/* Quick Actions */}
        <div className="mb-8">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">Quick Actions</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Link
              href="/create"
              className="bg-gradient-to-r from-green-500 to-green-600 text-white rounded-lg p-6 hover:from-green-600 hover:to-green-700 transition"
            >
              <div className="text-3xl mb-2">🌶️</div>
              <div className="font-semibold">Create New Auction</div>
              <div className="text-sm opacity-90">List your pepper lots</div>
            </Link>
            <Link
              href="/auctions"
              className="bg-white dark:bg-gray-800 border-2 border-gray-200 dark:border-gray-700 rounded-lg p-6 hover:border-green-500 dark:hover:border-green-500 transition"
            >
              <div className="text-3xl mb-2">📊</div>
              <div className="font-semibold dark:text-white">View All Auctions</div>
              <div className="text-sm text-gray-600 dark:text-gray-400">Track active bids</div>
            </Link>
            <Link
              href="/dashboard/farmer/profile"
              className="bg-white dark:bg-gray-800 border-2 border-gray-200 dark:border-gray-700 rounded-lg p-6 hover:border-green-500 dark:hover:border-green-500 transition"
            >
              <div className="text-3xl mb-2">👤</div>
              <div className="font-semibold dark:text-white">My Profile</div>
              <div className="text-sm text-gray-600 dark:text-gray-400">Update your information</div>
            </Link>
          </div>
        </div>

        {/* Stats */}
        <div className="mb-8">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">Statistics</h2>
          <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
            <div className="bg-white dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
              <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Total Lots</div>
              <div className="text-3xl font-bold text-gray-900 dark:text-white">{stats.totalLots}</div>
            </div>
            <div className="bg-white dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
              <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Pending Compliance</div>
              <div className="text-3xl font-bold text-yellow-600">{stats.pendingCompliance}</div>
            </div>
            <div className="bg-white dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
              <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Active Auctions</div>
              <div className="text-3xl font-bold text-green-600">{stats.activeAuctions}</div>
            </div>
            <div className="bg-white dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
              <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Total Revenue</div>
              <div className="text-3xl font-bold text-gray-900 dark:text-white">{stats.totalRevenue} ETH</div>
            </div>
            <div className="bg-white dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
              <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Pending Settlements</div>
              <div className="text-3xl font-bold text-orange-600">{stats.pendingSettlements}</div>
            </div>
          </div>
        </div>

        {/* Recent Lots */}
        <div className="mb-8">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Recent Lots</h2>
            <Link href="/dashboard/farmer/lots" className="text-sm text-green-600 hover:text-green-700">
              View All →
            </Link>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
            <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
              <thead className="bg-gray-50 dark:bg-gray-700">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">Lot ID</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">Variety</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">Quantity</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">Status</th>
                </tr>
              </thead>
              <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                {dataLoading ? (
                  [1, 2, 3].map((i) => (
                    <tr key={i} className="animate-pulse">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-24"></div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-32"></div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-16"></div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="h-6 bg-gray-200 dark:bg-gray-700 rounded-full w-20"></div>
                      </td>
                    </tr>
                  ))
                ) : lots.length > 0 ? (
                  lots.map((lot: any) => (
                    <tr key={lot.lotId}>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-white">
                        {lot.lotId}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600 dark:text-gray-300">
                        {lot.variety}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600 dark:text-gray-300">
                        {lot.quantity} kg
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                          lot.status === 'created' ? 'bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-300' :
                          lot.status === 'pending_compliance' ? 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-300' :
                          lot.status === 'approved' ? 'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-300' :
                          lot.status === 'auctioned' ? 'bg-purple-100 dark:bg-purple-900/30 text-purple-800 dark:text-purple-300' :
                          lot.status === 'rejected' ? 'bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-300' :
                          'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300'
                        }`}>
                          {lot.status.replace(/_/g, ' ').replace(/\b\w/g, (l: string) => l.toUpperCase())}
                        </span>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={4} className="px-6 py-8 text-center text-gray-500 dark:text-gray-400">
                      No lots yet. <Link href="/create" className="text-green-600 hover:text-green-700">Create your first lot</Link>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Recent Auctions */}
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Recent Auctions</h2>
            <Link href="/auctions" className="text-sm text-green-600 hover:text-green-700">
              View All →
            </Link>
          </div>
          {dataLoading ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {[1, 2, 3].map((i) => (
                <div key={i} className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 animate-pulse">
                  <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-3/4 mb-4"></div>
                  <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded w-full mb-2"></div>
                  <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded w-2/3"></div>
                </div>
              ))}
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {auctions.length > 0 ? (
                auctions.slice(0, 6).map((auction: any) => (
                  <div key={auction.auctionId} className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
                    <div className="flex items-center justify-between mb-3">
                      <span className="text-sm font-medium text-gray-900 dark:text-white">
                        Lot: {auction.lotId}
                      </span>
                      <span className={`px-2 py-1 text-xs font-semibold rounded-full ${
                        auction.status === 'active' ? 'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-300' :
                        auction.status === 'ended' ? 'bg-orange-100 dark:bg-orange-900/30 text-orange-800 dark:text-orange-300' :
                        auction.status === 'settled' ? 'bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-300' :
                        auction.status === 'created' ? 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300' :
                        'bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-300'
                      }`}>
                        {auction.status.replace(/_/g, ' ').toUpperCase()}
                      </span>
                    </div>
                    <div className="space-y-2 text-sm mb-4">
                      <div className="flex justify-between items-center">
                        <span className="text-gray-600 dark:text-gray-400">Start Price:</span>
                        <span className="font-medium text-gray-900 dark:text-white">{(parseFloat(auction.startPrice || '0') / 1e18).toFixed(4)} ETH</span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-gray-600 dark:text-gray-400">Current Bid:</span>
                        <span className="font-medium text-green-600 dark:text-green-400">{(parseFloat(auction.currentBid || '0') / 1e18).toFixed(4)} ETH</span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-gray-600 dark:text-gray-400">Total Bids:</span>
                        <span className="font-medium text-gray-900 dark:text-white">{auction.bidCount || 0}</span>
                      </div>
                    </div>
                    <Link
                      href={`/auctions/${auction.auctionId}`}
                      className="block w-full text-center px-4 py-2 bg-green-600 text-white text-sm font-medium rounded-lg hover:bg-green-700 transition"
                    >
                      View Details
                    </Link>
                  </div>
                ))
              ) : (
                <div className="col-span-full bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-12 text-center">
                  <p className="text-gray-500 dark:text-gray-400 mb-2">No auctions yet</p>
                  <Link href="/create" className="text-green-600 hover:text-green-700 font-medium">
                    Create your first auction →
                  </Link>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
