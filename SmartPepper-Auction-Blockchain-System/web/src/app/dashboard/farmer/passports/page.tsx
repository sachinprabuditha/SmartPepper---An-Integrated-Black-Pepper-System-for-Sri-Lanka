'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useRouter } from 'next/navigation';
import { useAccount } from 'wagmi';
import { Shield, Package, QrCode, Plus, Eye } from 'lucide-react';
import Link from 'next/link';

interface FarmerPassport {
  lotId: string; // e.g., "LOT-1733339456789"
  tokenId: string; // Same as lotId for now
  variety: string;
  quantity: number;
  origin: string;
  harvestDate: Date;
  createdAt: Date;
  isActive: boolean;
  processingStages: number;
  certifications: number;
}

export default function FarmerPassportsPage() {
  const { user, loading: authLoading } = useAuth();
  const { address: connectedAddress, isConnected } = useAccount();
  const router = useRouter();
  const [passports, setPassports] = useState<FarmerPassport[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Use connected wallet address or stored wallet address
  const walletAddress = user?.walletAddress || connectedAddress;

  useEffect(() => {
    if (!authLoading && (!user || user.role !== 'farmer')) {
      router.push('/login');
    }
  }, [user, authLoading, router]);

  useEffect(() => {
    if (walletAddress) {
      fetchMyPassports();
    } else if (user && !walletAddress) {
      setLoading(false);
      setError('No wallet address found. Please connect your MetaMask wallet.');
    }
  }, [user, walletAddress, connectedAddress]); // Re-fetch when wallet changes

  const fetchMyPassports = async () => {
    try {
      setLoading(true);
      setError(null);

      console.log('=== Fetching NFT Passports ===' );
      console.log('User wallet address (from auth):', user?.walletAddress);
      console.log('Connected wallet address (from MetaMask):', connectedAddress);
      console.log('Using wallet address:', walletAddress);
      console.log('User role:', user?.role);
      console.log('MetaMask connected:', isConnected);

      if (!walletAddress) {
        setError('No wallet address found. Please connect your MetaMask wallet.');
        setLoading(false);
        return;
      }

      // Fetch lots owned by this farmer
      const apiUrl = `http://localhost:3002/api/lots?farmer=${walletAddress}`;
      console.log('API URL:', apiUrl);
      
      const response = await fetch(apiUrl);
      console.log('API response status:', response.status);
      
      if (!response.ok) {
        const errorText = await response.text();
        console.error('API error response:', errorText);
        throw new Error('Failed to fetch passports');
      }

      const data = await response.json();
      console.log('API response data:', data);
      console.log('Number of lots returned:', data.lots?.length || 0);
      
      if (!data.success) {
        throw new Error(data.error || 'Failed to fetch lots');
      }

      const lots = data.lots || [];
      console.log('✅ Lots found:', lots.length);
      
      if (lots.length === 0) {
        console.warn('⚠️ No lots found for this farmer. Have you registered any harvests?');
      }
      
      // Transform lots to passport format
      // For now, show all lots as passports (they all have metadata generated during creation)
      const transformedPassports = lots.map((lot: any) => {
        console.log('📦 Processing lot:', {
          lot_id: lot.lot_id,
          farmer_address: lot.farmer_address,
          variety: lot.variety,
          quantity: lot.quantity
        });
        return {
          lotId: lot.lot_id,
          tokenId: lot.lot_id, // Use lot ID as token ID for display
          variety: lot.variety,
          quantity: lot.quantity,
          origin: lot.origin || lot.farm_location || 'N/A',
          harvestDate: lot.harvest_date,
          createdAt: lot.created_at,
          isActive: lot.status === 'available',
          processingStages: 0, // Can be updated when processing logs are added
          certifications: lot.organic_certified ? 1 : 0,
        };
      }) as FarmerPassport[];
      
      console.log('Transformed passports:', transformedPassports);
      setPassports(transformedPassports);
    } catch (err) {
      console.error('Error fetching passports:', err);
      setError(err instanceof Error ? err.message : 'Failed to load passports');
    } finally {
      setLoading(false);
    }
  };

  if (authLoading || loading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4">
        <div className="max-w-7xl mx-auto">
          <div className="animate-pulse space-y-4">
            <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded w-1/3" />
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {[1, 2, 3].map(i => (
                <div key={i} className="h-64 bg-gray-200 dark:bg-gray-700 rounded" />
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div className="flex items-center space-x-3">
            <Shield className="w-8 h-8 text-green-600 dark:text-green-400" />
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                My NFT Passports
              </h1>
              <p className="text-gray-600 dark:text-gray-400">
                Digital product passports for your pepper lots
              </p>
            </div>
          </div>
          <div className="flex items-center space-x-3">
            <button
              onClick={fetchMyPassports}
              disabled={loading}
              className="flex items-center space-x-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors disabled:bg-gray-400"
            >
              <svg 
                className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} 
                fill="none" 
                stroke="currentColor" 
                viewBox="0 0 24 24"
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
              <span>{loading ? 'Refreshing...' : 'Refresh'}</span>
            </button>
            <Link
              href="/harvest/register"
              className="flex items-center space-x-2 px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors"
            >
              <Plus className="w-5 h-5" />
              <span>Register Harvest</span>
            </Link>
          </div>
        </div>

        {/* Error State */}
        {error && (
          <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-900 rounded-lg p-4 mb-6">
            <p className="text-red-800 dark:text-red-400 mb-2">{error}</p>
            {!isConnected && (
              <p className="text-sm text-red-600 dark:text-red-300 mb-3">
                👉 Please connect your MetaMask wallet using the "Connect Wallet" button in the header.
              </p>
            )}
            <button
              onClick={() => window.location.reload()}
              className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white text-sm rounded-lg transition-colors"
            >
              Refresh Page
            </button>
          </div>
        )}

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500 dark:text-gray-400">Total Passports</p>
                <p className="text-3xl font-bold text-gray-900 dark:text-white mt-1">
                  {passports.length}
                </p>
              </div>
              <Package className="w-12 h-12 text-blue-500" />
            </div>
          </div>

          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500 dark:text-gray-400">Active Passports</p>
                <p className="text-3xl font-bold text-gray-900 dark:text-white mt-1">
                  {passports.filter(p => p.isActive).length}
                </p>
              </div>
              <Shield className="w-12 h-12 text-green-500" />
            </div>
          </div>

          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500 dark:text-gray-400">Total Certifications</p>
                <p className="text-3xl font-bold text-gray-900 dark:text-white mt-1">
                  {passports.reduce((sum, p) => sum + p.certifications, 0)}
                </p>
              </div>
              <QrCode className="w-12 h-12 text-purple-500" />
            </div>
          </div>
        </div>

        {/* Passports Grid */}
        {passports.length === 0 ? (
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-12 text-center">
            <Shield className="w-16 h-16 text-gray-400 mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
              No NFT Passports Yet
            </h3>
            <p className="text-gray-600 dark:text-gray-400 mb-6">
              Create your first lot to generate an NFT passport
            </p>
            <Link
              href="/harvest/register"
              className="inline-flex items-center space-x-2 px-6 py-3 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors"
            >
              <Plus className="w-5 h-5" />
              <span>Register Harvest</span>
            </Link>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {passports.map((passport) => (
              <div
                key={passport.lotId}
                className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 hover:shadow-lg transition-shadow"
              >
                {/* Header */}
                <div className="bg-gradient-to-r from-green-500 to-emerald-600 p-4 rounded-t-lg">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-2">
                      <Shield className="w-5 h-5 text-white" />
                      <span className="text-white font-semibold">NFT #{passport.tokenId}</span>
                    </div>
                    {passport.isActive && (
                      <span className="px-2 py-1 bg-white/20 rounded-full text-xs text-white">
                        Active
                      </span>
                    )}
                  </div>
                </div>

                {/* Content */}
                <div className="p-6 space-y-4">
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-1">
                      {passport.variety}
                    </h3>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                      Lot ID: #{passport.lotId}
                    </p>
                  </div>

                  <div className="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <p className="text-gray-500 dark:text-gray-400">Quantity</p>
                      <p className="font-semibold text-gray-900 dark:text-white">
                        {passport.quantity} kg
                      </p>
                    </div>
                    <div>
                      <p className="text-gray-500 dark:text-gray-400">Origin</p>
                      <p className="font-semibold text-gray-900 dark:text-white">
                        {passport.origin}
                      </p>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <p className="text-gray-500 dark:text-gray-400">Processing Stages</p>
                      <p className="font-semibold text-gray-900 dark:text-white">
                        {passport.processingStages}
                      </p>
                    </div>
                    <div>
                      <p className="text-gray-500 dark:text-gray-400">Certifications</p>
                      <p className="font-semibold text-gray-900 dark:text-white">
                        {passport.certifications}
                      </p>
                    </div>
                  </div>

                  <div className="pt-4 border-t border-gray-200 dark:border-gray-700">
                    <Link
                      href={`/dashboard/farmer/passports/${passport.lotId}`}
                      className="flex items-center justify-center space-x-2 w-full px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors"
                    >
                      <Eye className="w-4 h-4" />
                      <span>View Details</span>
                    </Link>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
