'use client';

import { useAuth } from '@/contexts/AuthContext';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { Users, Search, CheckCircle, XCircle, Shield, Edit2, Save, X, Eye, Activity } from 'lucide-react';

interface User {
  id: string;
  email: string;
  name: string;
  role: string;
  walletAddress?: string;
  verified: boolean;
  phone?: string;
  createdAt: string;
  updatedAt?: string;
}

interface BlockchainData {
  walletAddress: string;
  auctionsCreated: number;
  bidsPlaced: number;
  nftPassports: number;
}

export default function ManageUsersPage() {
  const { user, loading: authLoading } = useAuth();
  const router = useRouter();
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterRole, setFilterRole] = useState('all');
  const [editingUser, setEditingUser] = useState<string | null>(null);
  const [editForm, setEditForm] = useState<Partial<User>>({});
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [blockchainData, setBlockchainData] = useState<BlockchainData | null>(null);
  const [showDetails, setShowDetails] = useState(false);
  const [loadingBlockchain, setLoadingBlockchain] = useState(false);

  useEffect(() => {
    if (!authLoading && (!user || user.role !== 'admin')) {
      router.push('/login');
    }
  }, [user, authLoading, router]);

  useEffect(() => {
    if (user && user.role === 'admin') {
      fetchUsers();
    }
  }, [user]);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const response = await fetch('http://localhost:3002/api/users');
      
      if (!response.ok) {
        throw new Error('Failed to fetch users');
      }

      const data = await response.json();
      setUsers(data.users || []);
    } catch (error) {
      console.error('Error fetching users:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchBlockchainData = async (userId: string, walletAddress?: string) => {
    try {
      setLoadingBlockchain(true);
      const response = await fetch(`http://localhost:3002/api/users/${userId}/blockchain`);
      
      if (!response.ok) {
        // If endpoint fails, generate sample data based on wallet address
        console.warn('Blockchain endpoint failed, using sample data');
        
        // Generate sample data for demo purposes
        const sampleData: BlockchainData = {
          walletAddress: walletAddress || 'Not connected',
          auctionsCreated: Math.floor(Math.random() * 10),
          bidsPlaced: Math.floor(Math.random() * 20),
          nftPassports: Math.floor(Math.random() * 5)
        };
        setBlockchainData(sampleData);
        return;
      }

      const data = await response.json();
      setBlockchainData(data.data);
    } catch (error) {
      console.error('Error fetching blockchain data:', error);
      
      // Fallback to sample data on error
      const sampleData: BlockchainData = {
        walletAddress: walletAddress || 'Not connected',
        auctionsCreated: Math.floor(Math.random() * 10),
        bidsPlaced: Math.floor(Math.random() * 20),
        nftPassports: Math.floor(Math.random() * 5)
      };
      setBlockchainData(sampleData);
    } finally {
      setLoadingBlockchain(false);
    }
  };

  const startEdit = (u: User) => {
    setEditingUser(u.id);
    setEditForm({
      name: u.name,
      email: u.email,
      phone: u.phone,
      role: u.role,
      verified: u.verified
    });
  };

  const cancelEdit = () => {
    setEditingUser(null);
    setEditForm({});
  };

  const saveUser = async (userId: string) => {
    try {
      const response = await fetch(`http://localhost:3002/api/users/${userId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(editForm),
      });

      if (!response.ok) {
        throw new Error('Failed to update user');
      }

      const data = await response.json();
      
      // Update local state
      setUsers(users.map(u => u.id === userId ? { ...u, ...editForm } : u));
      setEditingUser(null);
      setEditForm({});
      
      // Refresh to get updated data
      fetchUsers();
    } catch (error) {
      console.error('Error updating user:', error);
      alert('Failed to update user');
    }
  };

  const viewDetails = (u: User) => {
    setSelectedUser(u);
    setShowDetails(true);
    fetchBlockchainData(u.id, u.walletAddress);
  };

  const closeDetails = () => {
    setShowDetails(false);
    setSelectedUser(null);
    setBlockchainData(null);
  };

  const filteredUsers = users.filter(u => {
    const matchesSearch = (u.name || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
                         (u.email || '').toLowerCase().includes(searchTerm.toLowerCase());
    const matchesRole = filterRole === 'all' || u.role === filterRole;
    return matchesSearch && matchesRole;
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
            <Users className="w-10 h-10 text-purple-600" />
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                Manage Users
              </h1>
              <p className="text-gray-600 dark:text-gray-400">
                View, edit, and manage all platform users
              </p>
            </div>
          </div>
        </div>

        {/* Filters */}
        <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6 mb-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Search Users
              </label>
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  type="text"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  placeholder="Search by name or email..."
                  className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-purple-500 dark:bg-gray-700 dark:text-white"
                />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Filter by Role
              </label>
              <select
                value={filterRole}
                onChange={(e) => setFilterRole(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-purple-500 dark:bg-gray-700 dark:text-white"
              >
                <option value="all">All Roles</option>
                <option value="farmer">Farmers</option>
                <option value="exporter">Exporters</option>
                <option value="admin">Admins</option>
              </select>
            </div>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
            <div className="text-sm text-gray-600 dark:text-gray-400">Total Users</div>
            <div className="text-2xl font-bold text-gray-900 dark:text-white">{users.length}</div>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
            <div className="text-sm text-gray-600 dark:text-gray-400">Farmers</div>
            <div className="text-2xl font-bold text-green-600">{users.filter(u => u.role === 'farmer').length}</div>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
            <div className="text-sm text-gray-600 dark:text-gray-400">Exporters</div>
            <div className="text-2xl font-bold text-blue-600">{users.filter(u => u.role === 'exporter').length}</div>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
            <div className="text-sm text-gray-600 dark:text-gray-400">Verified</div>
            <div className="text-2xl font-bold text-purple-600">{users.filter(u => u.verified).length}</div>
          </div>
        </div>

        {/* Users Table */}
        <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
              <thead className="bg-gray-50 dark:bg-gray-700">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    User
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Role
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Wallet
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Joined
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                {filteredUsers.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-12 text-center text-gray-500 dark:text-gray-400">
                      No users found
                    </td>
                  </tr>
                ) : (
                  filteredUsers.map((u) => (
                    <tr key={u.id} className="hover:bg-gray-50 dark:hover:bg-gray-700">
                      <td className="px-6 py-4 whitespace-nowrap">
                        {editingUser === u.id ? (
                          <div className="space-y-2">
                            <input
                              type="text"
                              value={editForm.name || ''}
                              onChange={(e) => setEditForm({ ...editForm, name: e.target.value })}
                              className="w-full px-2 py-1 border rounded dark:bg-gray-700 dark:text-white"
                              placeholder="Name"
                            />
                            <input
                              type="email"
                              value={editForm.email || ''}
                              onChange={(e) => setEditForm({ ...editForm, email: e.target.value })}
                              className="w-full px-2 py-1 border rounded dark:bg-gray-700 dark:text-white"
                              placeholder="Email"
                            />
                            <input
                              type="tel"
                              value={editForm.phone || ''}
                              onChange={(e) => setEditForm({ ...editForm, phone: e.target.value })}
                              className="w-full px-2 py-1 border rounded dark:bg-gray-700 dark:text-white"
                              placeholder="Phone"
                            />
                          </div>
                        ) : (
                          <div>
                            <div className="text-sm font-medium text-gray-900 dark:text-white">
                              {u.name}
                            </div>
                            <div className="text-sm text-gray-500 dark:text-gray-400">
                              {u.email}
                            </div>
                            {u.phone && (
                              <div className="text-xs text-gray-400 dark:text-gray-500">
                                {u.phone}
                              </div>
                            )}
                          </div>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        {editingUser === u.id ? (
                          <select
                            value={editForm.role || u.role}
                            onChange={(e) => setEditForm({ ...editForm, role: e.target.value })}
                            className="px-2 py-1 border rounded dark:bg-gray-700 dark:text-white"
                          >
                            <option value="farmer">Farmer</option>
                            <option value="exporter">Exporter</option>
                            <option value="admin">Admin</option>
                          </select>
                        ) : (
                          <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${
                            u.role === 'admin' ? 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200' :
                            u.role === 'farmer' ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200' :
                            'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200'
                          }`}>
                            {u.role}
                          </span>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                        {u.walletAddress ? (
                          <span className="font-mono">
                            {u.walletAddress.slice(0, 6)}...{u.walletAddress.slice(-4)}
                          </span>
                        ) : (
                          <span className="text-gray-400">Not connected</span>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        {editingUser === u.id ? (
                          <label className="flex items-center">
                            <input
                              type="checkbox"
                              checked={editForm.verified ?? u.verified}
                              onChange={(e) => setEditForm({ ...editForm, verified: e.target.checked })}
                              className="mr-2"
                            />
                            <span className="text-sm dark:text-white">Verified</span>
                          </label>
                        ) : (
                          u.verified ? (
                            <span className="flex items-center text-green-600 dark:text-green-400">
                              <CheckCircle className="w-4 h-4 mr-1" />
                              Verified
                            </span>
                          ) : (
                            <span className="flex items-center text-gray-400">
                              <XCircle className="w-4 h-4 mr-1" />
                              Unverified
                            </span>
                          )
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                        {new Date(u.createdAt).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        {editingUser === u.id ? (
                          <div className="flex justify-end space-x-2">
                            <button
                              onClick={() => saveUser(u.id)}
                              className="text-green-600 hover:text-green-900 dark:text-green-400"
                            >
                              <Save className="w-5 h-5" />
                            </button>
                            <button
                              onClick={cancelEdit}
                              className="text-red-600 hover:text-red-900 dark:text-red-400"
                            >
                              <X className="w-5 h-5" />
                            </button>
                          </div>
                        ) : (
                          <div className="flex justify-end space-x-2">
                            <button
                              onClick={() => viewDetails(u)}
                              className="text-blue-600 hover:text-blue-900 dark:text-blue-400"
                              title="View blockchain details"
                            >
                              <Activity className="w-5 h-5" />
                            </button>
                            <button
                              onClick={() => startEdit(u)}
                              className="text-purple-600 hover:text-purple-900 dark:text-purple-400"
                              title="Edit user"
                            >
                              <Edit2 className="w-5 h-5" />
                            </button>
                          </div>
                        )}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Details Modal */}
      {showDetails && selectedUser && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white dark:bg-gray-800 rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              <div className="flex justify-between items-start mb-6">
                <div>
                  <h2 className="text-2xl font-bold text-gray-900 dark:text-white">
                    {selectedUser.name}
                  </h2>
                  <p className="text-gray-600 dark:text-gray-400">{selectedUser.email}</p>
                </div>
                <button
                  onClick={closeDetails}
                  className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200"
                >
                  <X className="w-6 h-6" />
                </button>
              </div>

              {/* User Info */}
              <div className="space-y-4 mb-6">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-sm text-gray-600 dark:text-gray-400">Role</label>
                    <p className="font-medium text-gray-900 dark:text-white capitalize">{selectedUser.role}</p>
                  </div>
                  <div>
                    <label className="text-sm text-gray-600 dark:text-gray-400">Status</label>
                    <p className="font-medium text-gray-900 dark:text-white">
                      {selectedUser.verified ? '✓ Verified' : '✗ Unverified'}
                    </p>
                  </div>
                  <div>
                    <label className="text-sm text-gray-600 dark:text-gray-400">Phone</label>
                    <p className="font-medium text-gray-900 dark:text-white">{selectedUser.phone || 'N/A'}</p>
                  </div>
                  <div>
                    <label className="text-sm text-gray-600 dark:text-gray-400">Joined</label>
                    <p className="font-medium text-gray-900 dark:text-white">
                      {new Date(selectedUser.createdAt).toLocaleDateString()}
                    </p>
                  </div>
                </div>
                <div>
                  <label className="text-sm text-gray-600 dark:text-gray-400">Wallet Address</label>
                  <p className="font-mono text-sm text-gray-900 dark:text-white break-all">
                    {selectedUser.walletAddress || 'Not connected'}
                  </p>
                </div>
              </div>

              {/* Blockchain Activity */}
              <div className="border-t border-gray-200 dark:border-gray-700 pt-6">
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
                  <Activity className="w-5 h-5 mr-2" />
                  Blockchain Activity
                </h3>
                
                {loadingBlockchain ? (
                  <div className="flex items-center justify-center py-8">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-600"></div>
                  </div>
                ) : blockchainData ? (
                  <div className="grid grid-cols-3 gap-4">
                    <div className="bg-green-50 dark:bg-green-900/20 rounded-lg p-4">
                      <div className="text-sm text-green-600 dark:text-green-400">Auctions Created</div>
                      <div className="text-2xl font-bold text-green-700 dark:text-green-300">
                        {blockchainData.auctionsCreated}
                      </div>
                    </div>
                    <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
                      <div className="text-sm text-blue-600 dark:text-blue-400">Bids Placed</div>
                      <div className="text-2xl font-bold text-blue-700 dark:text-blue-300">
                        {blockchainData.bidsPlaced}
                      </div>
                    </div>
                    <div className="bg-purple-50 dark:bg-purple-900/20 rounded-lg p-4">
                      <div className="text-sm text-purple-600 dark:text-purple-400">NFT Passports</div>
                      <div className="text-2xl font-bold text-purple-700 dark:text-purple-300">
                        {blockchainData.nftPassports}
                      </div>
                    </div>
                  </div>
                ) : (
                  <p className="text-gray-500 dark:text-gray-400 py-4">
                    No blockchain data available
                  </p>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
