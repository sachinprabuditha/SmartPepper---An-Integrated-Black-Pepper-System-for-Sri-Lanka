'use client';

import { useAuth } from '@/contexts/AuthContext';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { Loader2 } from 'lucide-react';
import { auctionApi, lotApi, adminApi } from '@/lib/api';

export default function AdminDashboard() {
  const { user, logout, loading } = useAuth();
  const router = useRouter();
  const [navigatingTo, setNavigatingTo] = useState<string | null>(null);
  const [pendingSettlements, setPendingSettlements] = useState<any[]>([]);
  const [loadingSettlements, setLoadingSettlements] = useState(false);
  const [approvingSettlement, setApprovingSettlement] = useState<string | null>(null);
  const [stats, setStats] = useState({
    totalUsers: 0,
    pendingApprovals: 0,
    totalLots: 0,
    totalAuctions: 0,
    activeAuctions: 0,
    pendingCompliance: 0,
    totalRevenue: '0',
  });
  const [recentActivity, setRecentActivity] = useState([]);
  const [systemHealth, setSystemHealth] = useState({
    backend: { status: 'checking', percentage: 0, label: 'Checking...' },
    database: { status: 'checking', percentage: 0, label: 'Checking...' },
    blockchain: { status: 'checking', percentage: 0, label: 'Checking...' },
    websocket: { status: 'checking', percentage: 0, label: 'Checking...' },
  });

  const handleNavigation = (path: string) => {
    setNavigatingTo(path);
    router.push(path);
  };

  useEffect(() => {
    if (!loading && (!user || user.role !== 'admin')) {
      router.push('/login');
    }
  }, [user, loading, router]);

  useEffect(() => {
    if (user && user.role === 'admin') {
      loadDashboardData();
      loadPendingSettlements();
      checkSystemHealth();

      // Refresh health every 30 seconds
      const healthInterval = setInterval(checkSystemHealth, 30000);
      // Refresh settlements every minute
      const settlementsInterval = setInterval(loadPendingSettlements, 60000);
      return () => {
        clearInterval(healthInterval);
        clearInterval(settlementsInterval);
      };
    }
  }, [user]);

  const loadPendingSettlements = async () => {
    try {
      setLoadingSettlements(true);
      const response = await fetch('http://localhost:3002/api/admin/auctions/pending-settlement');
      if (response.ok) {
        const data = await response.json();
        setPendingSettlements(data.auctions || []);
      }
    } catch (error) {
      console.error('Failed to load pending settlements:', error);
    } finally {
      setLoadingSettlements(false);
    }
  };

  const handleApproveSettlement = async (auctionId: string) => {
    if (!confirm('Are you sure you want to approve this settlement? This will allow final payment release to the farmer.')) {
      return;
    }

    try {
      setApprovingSettlement(auctionId);
      const response = await fetch(`http://localhost:3002/api/admin/auctions/${auctionId}/approve-settlement`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ notes: 'Approved by admin from dashboard' })
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error || 'Failed to approve settlement');
      }

      alert('Settlement approved successfully! Farmer and buyer have been notified.');
      await loadPendingSettlements();
    } catch (error: any) {
      alert(`Failed to approve settlement: ${error.message}`);
    } finally {
      setApprovingSettlement(null);
    }
  };

  const checkSystemHealth = async () => {
    const startTime = Date.now();

    // Check Backend API
    try {
      const backendStart = Date.now();
      await auctionApi.getAll({ limit: 1 });
      const backendTime = Date.now() - backendStart;
      setSystemHealth((prev) => ({
        ...prev,
        backend: {
          status: backendTime < 500 ? 'healthy' : backendTime < 1000 ? 'warning' : 'error',
          percentage: 100,
          label: `${backendTime}ms`,
        },
      }));
    } catch (error) {
      setSystemHealth((prev) => ({
        ...prev,
        backend: { status: 'error', percentage: 0, label: 'Offline' },
      }));
    }

    // Check Database (via API)
    try {
      const dbStart = Date.now();
      await adminApi.getUsers({ limit: 1 });
      const dbTime = Date.now() - dbStart;
      setSystemHealth((prev) => ({
        ...prev,
        database: {
          status: dbTime < 500 ? 'healthy' : dbTime < 1000 ? 'warning' : 'error',
          percentage: dbTime < 500 ? 100 : dbTime < 1000 ? 80 : 60,
          label: `${dbTime}ms`,
        },
      }));
    } catch (error) {
      setSystemHealth((prev) => ({
        ...prev,
        database: { status: 'error', percentage: 0, label: 'Error' },
      }));
    }

    // Check Blockchain (via lot API that uses blockchain)
    try {
      const bcStart = Date.now();
      await lotApi.getAll({ limit: 1 });
      const bcTime = Date.now() - bcStart;
      setSystemHealth((prev) => ({
        ...prev,
        blockchain: {
          status: 'healthy',
          percentage: 100,
          label: 'Synced',
        },
      }));
    } catch (error) {
      setSystemHealth((prev) => ({
        ...prev,
        blockchain: { status: 'warning', percentage: 50, label: 'Limited' },
      }));
    }

    // Check WebSocket (simulated - check if WS would be available)
    const wsHealthy = typeof window !== 'undefined' && 'WebSocket' in window;
    setSystemHealth((prev) => ({
      ...prev,
      websocket: {
        status: wsHealthy ? 'healthy' : 'error',
        percentage: wsHealthy ? 100 : 0,
        label: wsHealthy ? 'Available' : 'Unavailable',
      },
    }));
  };

  const loadDashboardData = async () => {
    try {
      // Load system stats
      const lotsResponse = await lotApi.getAll({ limit: 100 });
      const auctionsResponse = await auctionApi.getAll({ limit: 100 });

      // Load user counts
      const usersResponse = await adminApi.getUsers({});
      const pendingUsersResponse = await adminApi.getPendingUsers();

      const lots = lotsResponse.data.lots || [];
      const auctions = auctionsResponse.data.auctions || [];
      const users = usersResponse.data.users || [];
      const pendingUsers = pendingUsersResponse.data.users || [];

      setStats({
        totalUsers: users.length,
        pendingApprovals: pendingUsers.length,
        totalLots: lots.length,
        totalAuctions: auctions.length,
        activeAuctions: auctions.filter((a: any) => a.status === 'active').length,
        pendingCompliance: lots.filter((l: any) => l.status === 'pending_compliance').length,
        totalRevenue: '0', // TODO: Calculate from settled auctions
      });

      // Load recent activity
      const activityResponse = await adminApi.getRecentActivity(10);
      if (activityResponse.data.success) {
        setRecentActivity(activityResponse.data.activities);
      }
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

        {/* Pending Approvals Banner */}
        {stats.pendingApprovals > 0 && (
          <div className="mb-6 bg-yellow-50 dark:bg-yellow-900/20 border-2 border-yellow-400 dark:border-yellow-700 rounded-lg p-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <div className="flex-shrink-0">
                  <svg className="h-6 w-6 text-yellow-600 dark:text-yellow-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                  </svg>
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-yellow-900 dark:text-yellow-200">
                    {stats.pendingApprovals} Exporter{stats.pendingApprovals > 1 ? 's' : ''} Pending Approval
                  </h3>
                  <p className="text-sm text-yellow-800 dark:text-yellow-300">
                    New exporter registrations require your review and approval
                  </p>
                </div>
              </div>
              <button
                onClick={() => handleNavigation('/dashboard/admin/users')}
                disabled={navigatingTo === '/dashboard/admin/users'}
                className="bg-yellow-600 hover:bg-yellow-700 text-white px-6 py-2 rounded-lg font-medium transition disabled:opacity-70 flex items-center gap-2"
              >
                {navigatingTo === '/dashboard/admin/users' ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    Loading...
                  </>
                ) : (
                  'Review Now'
                )}
              </button>
            </div>
          </div>
        )}

        {/* Pending Settlements Section */}
        {pendingSettlements.length > 0 && (
          <div className="mb-6 bg-green-50 dark:bg-green-900/20 border-2 border-green-400 dark:border-green-700 rounded-lg p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center space-x-3">
                <div className="flex-shrink-0">
                  <svg className="h-7 w-7 text-green-600 dark:text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <div>
                  <h3 className="text-xl font-bold text-green-900 dark:text-green-200">
                    💵 {pendingSettlements.length} Settlement{pendingSettlements.length > 1 ? 's' : ''} Awaiting Approval
                  </h3>
                  <p className="text-sm text-green-800 dark:text-green-300">
                    Escrow has been deposited. Review and approve to release payment to farmers.
                  </p>
                </div>
              </div>
              {loadingSettlements && <Loader2 className="w-5 h-5 animate-spin text-green-600" />}
            </div>

            <div className="space-y-3">
              {pendingSettlements.map((auction) => (
                <div key={auction.auctionId} className="bg-white dark:bg-gray-800 rounded-lg p-4 border border-green-200 dark:border-green-700">
                  <div className="flex items-center justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <span className="text-lg font-bold text-gray-900 dark:text-white">
                          Auction #{auction.auctionId}
                        </span>
                        {auction.lotDetails && (
                          <span className="px-2 py-1 bg-purple-100 dark:bg-purple-900 text-purple-800 dark:text-purple-200 text-xs font-semibold rounded">
                            {auction.lotDetails.variety} • {auction.lotDetails.quantity}kg • {auction.lotDetails.quality}
                          </span>
                        )}
                      </div>
                      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                        <div>
                          <div className="text-gray-600 dark:text-gray-400">Final Price</div>
                          <div className="font-semibold text-gray-900 dark:text-white">
                            {parseFloat(auction.finalPrice).toFixed(4)} ETH
                          </div>
                          <div className="text-xs text-gray-500">
                            ≈ LKR {parseFloat(auction.finalPriceLkr || 0).toLocaleString()}
                          </div>
                        </div>
                        <div>
                          <div className="text-gray-600 dark:text-gray-400">Lot ID</div>
                          <div className="font-mono text-sm text-gray-900 dark:text-white">{auction.lotId}</div>
                        </div>
                        <div>
                          <div className="text-gray-600 dark:text-gray-400">Winner</div>
                          <div className="font-mono text-xs text-gray-900 dark:text-white">
                            {auction.winnerAddress?.substring(0, 10)}...
                          </div>
                        </div>
                        <div>
                          <div className="text-gray-600 dark:text-gray-400">Farmer</div>
                          <div className="font-mono text-xs text-gray-900 dark:text-white">
                            {auction.farmerAddress?.substring(0, 10)}...
                          </div>
                        </div>
                      </div>
                    </div>
                    <button
                      onClick={() => handleApproveSettlement(auction.auctionId)}
                      disabled={approvingSettlement === auction.auctionId}
                      className="ml-4 bg-green-600 hover:bg-green-700 text-white px-6 py-3 rounded-lg font-medium transition disabled:opacity-70 flex items-center gap-2 whitespace-nowrap"
                    >
                      {approvingSettlement === auction.auctionId ? (
                        <>
                          <Loader2 className="w-4 h-4 animate-spin" />
                          Approving...
                        </>
                      ) : (
                        <>
                          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                          </svg>
                          Approve Settlement
                        </>
                      )}
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Quick Actions */}
        <div className="mb-8">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">Quick Actions</h2>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <button
              onClick={() => handleNavigation('/dashboard/admin/users')}
              disabled={navigatingTo === '/dashboard/admin/users'}
              className="bg-white rounded-lg p-6 border-2 border-gray-200 hover:border-purple-500 transition relative disabled:opacity-70 text-left w-full"
            >
              {stats.pendingApprovals > 0 && (
                <div className="absolute -top-2 -right-2 bg-red-600 text-white text-xs font-bold rounded-full h-8 w-8 flex items-center justify-center animate-pulse">
                  {stats.pendingApprovals}
                </div>
              )}
              {navigatingTo === '/dashboard/admin/users' && (
                <div className="absolute top-2 right-2">
                  <Loader2 className="w-5 h-5 animate-spin text-purple-600" />
                </div>
              )}
              <div className="text-3xl mb-2">👥</div>
              <div className="font-semibold">Manage Users</div>
              <div className="text-sm text-gray-600">
                {stats.pendingApprovals > 0 ? (
                  <span className="text-red-600 font-medium">{stats.pendingApprovals} pending approval</span>
                ) : (
                  'View & verify users'
                )}
              </div>
            </button>
            <button
              onClick={() => handleNavigation('/dashboard/admin/lots')}
              disabled={navigatingTo === '/dashboard/admin/lots'}
              className="bg-white rounded-lg p-6 border-2 border-gray-200 hover:border-purple-500 transition relative disabled:opacity-70 text-left w-full"
            >
              {navigatingTo === '/dashboard/admin/lots' && (
                <div className="absolute top-2 right-2">
                  <Loader2 className="w-5 h-5 animate-spin text-purple-600" />
                </div>
              )}
              <div className="text-3xl mb-2">📦</div>
              <div className="font-semibold">Manage Lots</div>
              <div className="text-sm text-gray-600">Review pepper lots</div>
            </button>
            <button
              onClick={() => handleNavigation('/dashboard/admin/auctions')}
              disabled={navigatingTo === '/dashboard/admin/auctions'}
              className="bg-white rounded-lg p-6 border-2 border-gray-200 hover:border-purple-500 transition relative disabled:opacity-70 text-left w-full"
            >
              {navigatingTo === '/dashboard/admin/auctions' && (
                <div className="absolute top-2 right-2">
                  <Loader2 className="w-5 h-5 animate-spin text-purple-600" />
                </div>
              )}
              <div className="text-3xl mb-2">🔨</div>
              <div className="font-semibold">Manage Auctions</div>
              <div className="text-sm text-gray-600">Monitor auctions</div>
            </button>
            <button
              onClick={() => handleNavigation('/dashboard/admin/compliance')}
              disabled={navigatingTo === '/dashboard/admin/compliance'}
              className="bg-white rounded-lg p-6 border-2 border-gray-200 hover:border-purple-500 transition relative disabled:opacity-70 text-left w-full"
            >
              {navigatingTo === '/dashboard/admin/compliance' && (
                <div className="absolute top-2 right-2">
                  <Loader2 className="w-5 h-5 animate-spin text-purple-600" />
                </div>
              )}
              <div className="text-3xl mb-2">✅</div>
              <div className="font-semibold">Compliance</div>
              <div className="text-sm text-gray-600">Review checks</div>
            </button>
          </div>
        </div>

        {/* Master Data & AI Management */}
        <div className="mb-8">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">Master Data & AI Management</h2>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <Link
              href="/dashboard/admin/knowledgebase"
              className="bg-white dark:bg-gray-800 rounded-xl p-6 border-2 border-gray-200 dark:border-gray-700 hover:border-purple-500 transition shadow-sm"
            >
              <div className="text-3xl mb-2">📚</div>
              <div className="font-semibold text-gray-900 dark:text-white">Knowledgebase</div>
              <div className="text-sm text-gray-600 dark:text-gray-400">RAG & AI Search</div>
            </Link>
            <Link
              href="/dashboard/admin/agriculture"
              className="bg-white dark:bg-gray-800 rounded-xl p-6 border-2 border-gray-200 dark:border-gray-700 hover:border-purple-500 transition shadow-sm"
            >
              <div className="text-3xl mb-2">🚜</div>
              <div className="font-semibold text-gray-900 dark:text-white">Agriculture Data</div>
              <div className="text-sm text-gray-600 dark:text-gray-400">Firestore Master Data</div>
            </Link>
          </div>
        </div>

        {/* Governance Section */}
        <div className="mb-8">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">Auction Governance</h2>
          <button
            onClick={() => handleNavigation('/dashboard/admin/governance')}
            disabled={navigatingTo === '/dashboard/admin/governance'}
            className="block w-full bg-gradient-to-r from-purple-600 to-purple-800 rounded-lg p-6 text-white hover:from-purple-700 hover:to-purple-900 transition shadow-lg disabled:opacity-70 text-left"
          >
            <div className="flex items-center justify-between">
              <div>
                <div className="text-2xl mb-2 flex items-center gap-2">
                  🛡️ Governance & Rule Management
                  {navigatingTo === '/dashboard/admin/governance' && (
                    <Loader2 className="w-6 h-6 animate-spin" />
                  )}
                </div>
                <div className="text-purple-100">
                  Define auction templates, set bid increments, approve emergency cancellations, and audit logs
                </div>
              </div>
              <div className="text-4xl">→</div>
            </div>
          </button>
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
            {recentActivity.length === 0 ? (
              <div className="text-center py-8 text-gray-500">
                <p className="text-sm">No recent activity</p>
              </div>
            ) : (
              <div className="space-y-4">
                {recentActivity.map((activity: any, index: number) => (
                  <div
                    key={index}
                    className={`flex items-center space-x-3 ${index < recentActivity.length - 1 ? 'pb-3 border-b border-gray-100' : ''
                      }`}
                  >
                    <div
                      className={`w-2 h-2 rounded-full ${activity.color === 'green'
                        ? 'bg-green-500'
                        : activity.color === 'blue'
                          ? 'bg-blue-500'
                          : activity.color === 'yellow'
                            ? 'bg-yellow-500'
                            : activity.color === 'orange'
                              ? 'bg-orange-500'
                              : activity.color === 'red'
                                ? 'bg-red-500'
                                : 'bg-purple-500'
                        }`}
                    ></div>
                    <div className="flex-1">
                      <p className="text-sm text-gray-900">{activity.description}</p>
                      <p className="text-xs text-gray-500">{activity.timeAgo}</p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* System Health */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">System Health</h3>
            <div className="space-y-4">
              <div>
                <div className="flex justify-between text-sm mb-1">
                  <span className="text-gray-600">Backend API</span>
                  <span className={`font-medium ${systemHealth.backend.status === 'healthy' ? 'text-green-600' :
                    systemHealth.backend.status === 'warning' ? 'text-yellow-600' :
                      systemHealth.backend.status === 'error' ? 'text-red-600' :
                        'text-gray-400'
                    }`}>
                    {systemHealth.backend.label}
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full transition-all ${systemHealth.backend.status === 'healthy' ? 'bg-green-600' :
                      systemHealth.backend.status === 'warning' ? 'bg-yellow-600' :
                        'bg-red-600'
                      }`}
                    style={{ width: `${systemHealth.backend.percentage}%` }}
                  ></div>
                </div>
              </div>
              <div>
                <div className="flex justify-between text-sm mb-1">
                  <span className="text-gray-600">Database</span>
                  <span className={`font-medium ${systemHealth.database.status === 'healthy' ? 'text-green-600' :
                    systemHealth.database.status === 'warning' ? 'text-yellow-600' :
                      systemHealth.database.status === 'error' ? 'text-red-600' :
                        'text-gray-400'
                    }`}>
                    {systemHealth.database.label}
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full transition-all ${systemHealth.database.status === 'healthy' ? 'bg-green-600' :
                      systemHealth.database.status === 'warning' ? 'bg-yellow-600' :
                        'bg-red-600'
                      }`}
                    style={{ width: `${systemHealth.database.percentage}%` }}
                  ></div>
                </div>
              </div>
              <div>
                <div className="flex justify-between text-sm mb-1">
                  <span className="text-gray-600">Blockchain Sync</span>
                  <span className={`font-medium ${systemHealth.blockchain.status === 'healthy' ? 'text-green-600' :
                    systemHealth.blockchain.status === 'warning' ? 'text-yellow-600' :
                      systemHealth.blockchain.status === 'error' ? 'text-red-600' :
                        'text-gray-400'
                    }`}>
                    {systemHealth.blockchain.label}
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full transition-all ${systemHealth.blockchain.status === 'healthy' ? 'bg-green-600' :
                      systemHealth.blockchain.status === 'warning' ? 'bg-yellow-600' :
                        'bg-red-600'
                      }`}
                    style={{ width: `${systemHealth.blockchain.percentage}%` }}
                  ></div>
                </div>
              </div>
              <div>
                <div className="flex justify-between text-sm mb-1">
                  <span className="text-gray-600">WebSocket</span>
                  <span className={`font-medium ${systemHealth.websocket.status === 'healthy' ? 'text-green-600' :
                    systemHealth.websocket.status === 'warning' ? 'text-yellow-600' :
                      systemHealth.websocket.status === 'error' ? 'text-red-600' :
                        'text-gray-400'
                    }`}>
                    {systemHealth.websocket.label}
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full transition-all ${systemHealth.websocket.status === 'healthy' ? 'bg-green-600' :
                      systemHealth.websocket.status === 'warning' ? 'bg-yellow-600' :
                        'bg-red-600'
                      }`}
                    style={{ width: `${systemHealth.websocket.percentage}%` }}
                  ></div>
                </div>
              </div>
            </div>
            <div className="mt-4 pt-4 border-t border-gray-200">
              <button
                onClick={checkSystemHealth}
                className="text-sm text-purple-600 hover:text-purple-700 font-medium"
              >
                🔄 Refresh Health Check
              </button>
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
    </div >
  );
}
