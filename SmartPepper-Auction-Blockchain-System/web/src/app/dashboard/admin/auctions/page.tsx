'use client';

import { useAuth } from '@/contexts/AuthContext';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { Gavel, Search, Clock, CheckCircle, PlayCircle, StopCircle } from 'lucide-react';

interface Auction {
  auction_id: number;
  lot_id: string;
  farmer_address: string;
  farmer_name?: string;
  reserve_price: string;
  current_price: string;
  highest_bidder?: string;
  start_time: string;
  end_time: string;
  status: string;
  total_bids?: number;
  variety?: string;
  quantity?: number;
  quality?: string;
  origin?: string;
}

export default function ManageAuctionsPage() {
  const { user, loading: authLoading } = useAuth();
  const router = useRouter();
  const [auctions, setAuctions] = useState<Auction[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');

  useEffect(() => {
    if (!authLoading && (!user || user.role !== 'admin')) {
      router.push('/login');
    }
  }, [user, authLoading, router]);

  useEffect(() => {
    if (user && user.role === 'admin') {
      fetchAuctions();
    }
  }, [user]);

  const fetchAuctions = async () => {
    try {
      setLoading(true);
      const response = await fetch('http://localhost:3002/api/auctions');
      
      if (!response.ok) {
        throw new Error('Failed to fetch auctions');
      }

      const data = await response.json();
      setAuctions(data.auctions || []);
    } catch (error) {
      console.error('Error fetching auctions:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'created':
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200';
      case 'active':
        return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200';
      case 'ended':
        return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200';
      case 'settled':
        return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200';
      case 'cancelled':
        return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200';
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200';
    }
  };

  const getTimeRemaining = (endTime: string) => {
    const now = new Date().getTime();
    const end = new Date(endTime).getTime();
    const diff = end - now;
    
    if (diff <= 0) return 'Ended';
    
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));
    const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    
    if (days > 0) return `${days}d ${hours}h`;
    return `${hours}h`;
  };

  const filteredAuctions = auctions.filter(auction => {
    const matchesSearch = (auction.auction_id?.toString() || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
                         (auction.lot_id || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
                         (auction.farmer_name || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
                         (auction.farmer_address || '').toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = filterStatus === 'all' || auction.status === filterStatus;
    return matchesSearch && matchesStatus;
  });

  if (authLoading || loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <button
            onClick={() => router.push('/dashboard/admin')}
            className="text-purple-600 hover:text-purple-700 mb-4"
          >
            ← Back to Dashboard
          </button>
          <div className="flex items-center space-x-3 mb-4">
            <Gavel className="w-10 h-10 text-purple-600" />
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                Manage Auctions
              </h1>
              <p className="text-gray-600 dark:text-gray-400">
                Monitor and manage all auctions
              </p>
            </div>
          </div>
        </div>

        {/* Filters */}
        <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6 mb-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Search Auctions
              </label>
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  type="text"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  placeholder="Search by auction ID, lot ID, farmer name or address..."
                  className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-purple-500 dark:bg-gray-700 dark:text-white"
                />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Filter by Status
              </label>
              <select
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-purple-500 dark:bg-gray-700 dark:text-white"
              >
                <option value="all">All Status</option>
                <option value="created">Created</option>
                <option value="active">Active</option>
                <option value="ended">Ended</option>
                <option value="settled">Settled</option>
                <option value="cancelled">Cancelled</option>
              </select>
            </div>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-5 gap-4 mb-6">
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
            <div className="text-sm text-gray-600 dark:text-gray-400">Total Auctions</div>
            <div className="text-2xl font-bold text-gray-900 dark:text-white">{auctions.length}</div>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
            <div className="text-sm text-gray-600 dark:text-gray-400">Active</div>
            <div className="text-2xl font-bold text-blue-600">{auctions.filter(a => a.status === 'active').length}</div>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
            <div className="text-sm text-gray-600 dark:text-gray-400">Ended</div>
            <div className="text-2xl font-bold text-yellow-600">{auctions.filter(a => a.status === 'ended').length}</div>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
            <div className="text-sm text-gray-600 dark:text-gray-400">Settled</div>
            <div className="text-2xl font-bold text-green-600">{auctions.filter(a => a.status === 'settled').length}</div>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
            <div className="text-sm text-gray-600 dark:text-gray-400">Total Bids</div>
            <div className="text-2xl font-bold text-purple-600">
              {auctions.reduce((sum, a) => sum + (a.total_bids || 0), 0)}
            </div>
          </div>
        </div>

        {/* Auctions Table */}
        <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
              <thead className="bg-gray-50 dark:bg-gray-700">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Auction
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Lot Details
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Price
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Time
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                {filteredAuctions.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-12 text-center text-gray-500 dark:text-gray-400">
                      No auctions found
                    </td>
                  </tr>
                ) : (
                  filteredAuctions.map((auction) => (
                    <tr key={auction.auction_id} className="hover:bg-gray-50 dark:hover:bg-gray-700">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div>
                          <div className="text-sm font-medium text-gray-900 dark:text-white">
                            Auction #{auction.auction_id}
                          </div>
                          <div className="text-sm text-gray-500 dark:text-gray-400">
                            {auction.farmer_name || 'Unknown Farmer'}
                          </div>
                          <div className="text-xs text-gray-400 dark:text-gray-500 font-mono">
                            {auction.farmer_address?.slice(0, 6)}...{auction.farmer_address?.slice(-4)}
                          </div>
                          <div className="text-xs text-gray-400 dark:text-gray-500">
                            {auction.total_bids || 0} bids
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-sm text-gray-900 dark:text-white">
                          <div><strong>Lot:</strong> {auction.lot_id}</div>
                          {auction.variety && (
                            <div className="text-gray-600 dark:text-gray-400">
                              {auction.variety}
                            </div>
                          )}
                          {auction.quantity && (
                            <div className="text-gray-600 dark:text-gray-400">
                              {auction.quantity} kg
                            </div>
                          )}
                          {auction.quality && (
                            <div className="text-xs text-gray-500 dark:text-gray-400">
                              Quality: {auction.quality}
                            </div>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm">
                          <div className="text-gray-900 dark:text-white">
                            <strong>Current:</strong> {parseFloat(auction.current_price || '0').toFixed(4)} ETH
                          </div>
                          <div className="text-gray-500 dark:text-gray-400">
                            Reserve: {parseFloat(auction.reserve_price || '0').toFixed(4)} ETH
                          </div>
                          {auction.highest_bidder && auction.highest_bidder !== '0x0000000000000000000000000000000000000000' && (
                            <div className="text-xs text-gray-400 dark:text-gray-500 font-mono">
                              {auction.highest_bidder.slice(0, 6)}...{auction.highest_bidder.slice(-4)}
                            </div>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm">
                          <div className="text-gray-900 dark:text-white flex items-center">
                            <Clock className="w-4 h-4 mr-1" />
                            {getTimeRemaining(auction.end_time)}
                          </div>
                          <div className="text-gray-500 dark:text-gray-400">
                            Ends: {new Date(auction.end_time).toLocaleDateString()}
                          </div>
                          <div className="text-xs text-gray-400 dark:text-gray-500">
                            {new Date(auction.end_time).toLocaleTimeString()}
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${getStatusColor(auction.status)}`}>
                          {auction.status === 'active' && <PlayCircle className="w-3 h-3 mr-1" />}
                          {auction.status === 'ended' && <StopCircle className="w-3 h-3 mr-1" />}
                          {auction.status === 'settled' && <CheckCircle className="w-3 h-3 mr-1" />}
                          {auction.status.toUpperCase()}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm">
                        <button
                          onClick={() => router.push(`/auctions/${auction.auction_id}`)}
                          className="text-purple-600 hover:text-purple-900 dark:text-purple-400 dark:hover:text-purple-300"
                        >
                          View Details
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
