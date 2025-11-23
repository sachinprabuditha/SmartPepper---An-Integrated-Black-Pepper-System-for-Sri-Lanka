'use client';

import { useAuth } from '@/contexts/AuthContext';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { auctionApi, lotApi, userApi } from '@/lib/api';

export default function AdminDashboard() {
  const { user, logout, loading } = useAuth();
  const router = useRouter();
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalLots: 0,
    totalAuctions: 0,
    activeAuctions: 0,
    pendingCompliance: 0,
    totalRevenue: '0',
  });
  const [recentActivity, setRecentActivity] = useState([]);

  useEffect(() => {
    if (!loading && (!user || user.role !== 'admin')) {
      router.push('/login');
    }
  }, [user, loading, router]);

  useEffect(() => {
    if (user && user.role === 'admin') {
      loadDashboardData();
    }
  }, [user]);

  const loadDashboardData = async () => {
    try {
      // Load system stats
      const lotsResponse = await lotApi.getAll({ limit: 100 });
      const auctionsResponse = await auctionApi.getAll({ limit: 100 });

      const lots = lotsResponse.data.lots || [];
      const auctions = auctionsResponse.data.auctions || [];

      setStats({
        totalUsers: 0, // TODO: Need users count API
        totalLots: lots.length,
        totalAuctions: auctions.length,
        activeAuctions: auctions.filter((a: any) => a.status === 'active').length,
        pendingCompliance: lots.filter((l: any) => l.status === 'pending_compliance').length,
        totalRevenue: '0', // TODO: Calculate from settled auctions
      });
    } catch (error) {
      console.error('Failed to load dashboard data:', error);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600"></div>
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
          <h1 className="text-3xl font-bold text-purple-900 dark:text-purple-300">⚙️ Admin Dashboard</h1>
          <p className="text-gray-600 dark:text-gray-400 mt-2">SmartPepper System Management - Monitor and control all platform activities</p>
        </div>

        {/* Quick Actions */}
        <div className="mb-8">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">Quick Actions</h2>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <Link
              href="/dashboard/admin/users"
              className="bg-white rounded-lg p-6 border-2 border-gray-200 hover:border-purple-500 transition"
            >
              <div className="text-3xl mb-2">👥</div>
              <div className="font-semibold">Manage Users</div>
              <div className="text-sm text-gray-600">View & verify users</div>
            </Link>
            <Link
              href="/dashboard/admin/lots"
              className="bg-white rounded-lg p-6 border-2 border-gray-200 hover:border-purple-500 transition"
            >
              <div className="text-3xl mb-2">📦</div>
              <div className="font-semibold">Manage Lots</div>
              <div className="text-sm text-gray-600">Review pepper lots</div>
            </Link>
            <Link
              href="/dashboard/admin/auctions"
              className="bg-white rounded-lg p-6 border-2 border-gray-200 hover:border-purple-500 transition"
            >
              <div className="text-3xl mb-2">🔨</div>
              <div className="font-semibold">Manage Auctions</div>
              <div className="text-sm text-gray-600">Monitor auctions</div>
            </Link>
            <Link
              href="/dashboard/admin/compliance"
              className="bg-white rounded-lg p-6 border-2 border-gray-200 hover:border-purple-500 transition"
            >
              <div className="text-3xl mb-2">✅</div>
              <div className="font-semibold">Compliance</div>
              <div className="text-sm text-gray-600">Review checks</div>
            </Link>
          </div>
        </div>

        {/* System Stats */}
        <div className="mb-8">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">System Overview</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-6 gap-4">
            <div className="bg-white rounded-lg p-6 border border-gray-200 shadow-sm">
              <div className="text-sm text-gray-600 mb-1">Total Users</div>
              <div className="text-3xl font-bold text-gray-900">{stats.totalUsers}</div>
              <div className="text-xs text-green-600 mt-1">↑ Active</div>
            </div>
            <div className="bg-white rounded-lg p-6 border border-gray-200 shadow-sm">
              <div className="text-sm text-gray-600 mb-1">Total Lots</div>
              <div className="text-3xl font-bold text-blue-600">{stats.totalLots}</div>
              <div className="text-xs text-gray-500 mt-1">All time</div>
            </div>
            <div className="bg-white rounded-lg p-6 border border-gray-200 shadow-sm">
              <div className="text-sm text-gray-600 mb-1">Total Auctions</div>
              <div className="text-3xl font-bold text-purple-600">{stats.totalAuctions}</div>
              <div className="text-xs text-gray-500 mt-1">All time</div>
            </div>
            <div className="bg-white rounded-lg p-6 border border-gray-200 shadow-sm">
              <div className="text-sm text-gray-600 mb-1">Active Auctions</div>
              <div className="text-3xl font-bold text-green-600">{stats.activeAuctions}</div>
              <div className="text-xs text-green-600 mt-1">↑ Live now</div>
            </div>
            <div className="bg-white rounded-lg p-6 border border-gray-200 shadow-sm">
              <div className="text-sm text-gray-600 mb-1">Pending Compliance</div>
              <div className="text-3xl font-bold text-orange-600">{stats.pendingCompliance}</div>
              <div className="text-xs text-orange-600 mt-1">⚠ Needs review</div>
            </div>
            <div className="bg-white rounded-lg p-6 border border-gray-200 shadow-sm">
              <div className="text-sm text-gray-600 mb-1">Total Revenue</div>
              <div className="text-2xl font-bold text-gray-900">{stats.totalRevenue} ETH</div>
              <div className="text-xs text-gray-500 mt-1">Platform fees</div>
            </div>
          </div>
        </div>

        {/* Charts & Analytics */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          {/* Recent Activity */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Recent Activity</h3>
            <div className="space-y-4">
              <div className="flex items-center space-x-3 pb-3 border-b border-gray-100">
                <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                <div className="flex-1">
                  <p className="text-sm text-gray-900">New auction created</p>
                  <p className="text-xs text-gray-500">5 minutes ago</p>
                </div>
              </div>
              <div className="flex items-center space-x-3 pb-3 border-b border-gray-100">
                <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                <div className="flex-1">
                  <p className="text-sm text-gray-900">User registered</p>
                  <p className="text-xs text-gray-500">12 minutes ago</p>
                </div>
              </div>
              <div className="flex items-center space-x-3 pb-3 border-b border-gray-100">
                <div className="w-2 h-2 bg-yellow-500 rounded-full"></div>
                <div className="flex-1">
                  <p className="text-sm text-gray-900">Compliance check pending</p>
                  <p className="text-xs text-gray-500">1 hour ago</p>
                </div>
              </div>
              <div className="flex items-center space-x-3">
                <div className="w-2 h-2 bg-purple-500 rounded-full"></div>
                <div className="flex-1">
                  <p className="text-sm text-gray-900">Auction settled</p>
                  <p className="text-xs text-gray-500">2 hours ago</p>
                </div>
              </div>
            </div>
          </div>

          {/* System Health */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">System Health</h3>
            <div className="space-y-4">
              <div>
                <div className="flex justify-between text-sm mb-1">
                  <span className="text-gray-600">Blockchain Sync</span>
                  <span className="text-green-600 font-medium">100%</span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div className="bg-green-600 h-2 rounded-full" style={{ width: '100%' }}></div>
                </div>
              </div>
              <div>
                <div className="flex justify-between text-sm mb-1">
                  <span className="text-gray-600">Database</span>
                  <span className="text-green-600 font-medium">Healthy</span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div className="bg-green-600 h-2 rounded-full" style={{ width: '95%' }}></div>
                </div>
              </div>
              <div>
                <div className="flex justify-between text-sm mb-1">
                  <span className="text-gray-600">WebSocket</span>
                  <span className="text-green-600 font-medium">Connected</span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div className="bg-green-600 h-2 rounded-full" style={{ width: '100%' }}></div>
                </div>
              </div>
              <div>
                <div className="flex justify-between text-sm mb-1">
                  <span className="text-gray-600">Redis Cache</span>
                  <span className="text-green-600 font-medium">Online</span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div className="bg-green-600 h-2 rounded-full" style={{ width: '98%' }}></div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Management Links */}
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">System Management</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Link
              href="/dashboard/admin/settings"
              className="p-4 border border-gray-200 rounded-lg hover:border-purple-500 hover:bg-purple-50 transition"
            >
              <div className="font-medium text-gray-900">⚙️ System Settings</div>
              <div className="text-sm text-gray-600">Configure platform settings</div>
            </Link>
            <Link
              href="/dashboard/admin/reports"
              className="p-4 border border-gray-200 rounded-lg hover:border-purple-500 hover:bg-purple-50 transition"
            >
              <div className="font-medium text-gray-900">📊 Reports</div>
              <div className="text-sm text-gray-600">View analytics & reports</div>
            </Link>
            <Link
              href="/dashboard/admin/logs"
              className="p-4 border border-gray-200 rounded-lg hover:border-purple-500 hover:bg-purple-50 transition"
            >
              <div className="font-medium text-gray-900">📝 Activity Logs</div>
              <div className="text-sm text-gray-600">Review system logs</div>
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
