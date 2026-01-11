'use client';

import { useState, useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { useAccount } from 'wagmi';
import { auctionApi } from '@/lib/api';
import { ethers } from 'ethers';
import { CONTRACT_ADDRESS, CONTRACT_ABI } from '@/config/contracts';
import { Package, Gavel, AlertCircle, CheckCircle, Plus } from 'lucide-react';
import Link from 'next/link';

interface Lot {
  lot_id: string;
  variety: string;
  quantity: number;
  quality: string;
  harvest_date: string;
  status: string;
  farmer_address: string;
  origin?: string;
}

export default function CreateAuctionPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const preSelectedLotId = searchParams.get('lotId');
  const { user } = useAuth();
  const { address: connectedAddress, isConnected } = useAccount();
  const [isLoading, setIsLoading] = useState(false);
  const [lotsLoading, setLotsLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  
  // Use connected wallet or stored wallet
  const walletAddress = user?.walletAddress || connectedAddress;
  
  // Available lots
  const [availableLots, setAvailableLots] = useState<Lot[]>([]);
  const [selectedLot, setSelectedLot] = useState<Lot | null>(null);

  // Auction details
  const [auctionData, setAuctionData] = useState({
    startPrice: '',
    reservePrice: '',
    duration: '3', // days
  });

  // Redirect if not farmer
  useEffect(() => {
    if (user && user.role !== 'farmer') {
      router.push('/dashboard');
    }
  }, [user, router]);

  // Fetch farmer's available lots
  useEffect(() => {
    if (walletAddress) {
      fetchAvailableLots();
    } else if (!isConnected) {
      setLotsLoading(false);
      setError('Please connect your MetaMask wallet to view your lots');
    }
  }, [walletAddress, isConnected]);

  // Pre-select lot if lotId is in query params
  useEffect(() => {
    if (preSelectedLotId && availableLots.length > 0) {
      const lot = availableLots.find(l => l.lot_id === preSelectedLotId);
      if (lot) {
        setSelectedLot(lot);
      }
    }
  }, [preSelectedLotId, availableLots]);

  const fetchAvailableLots = async () => {
    try {
      setLotsLoading(true);
      setError('');
      console.log('=== Fetching Lots for Create Auction ===');
      console.log('User wallet:', user?.walletAddress);
      console.log('Connected wallet:', connectedAddress);
      console.log('Using wallet:', walletAddress);
      
      if (!walletAddress) {
        setError('Please connect your MetaMask wallet');
        setLotsLoading(false);
        return;
      }
      
      // Fetch lots owned by this farmer that are available and compliance-passed
      const apiUrl = `http://localhost:3002/api/lots?farmer=${walletAddress.toLowerCase()}`;
      console.log('API URL:', apiUrl);
      
      const response = await fetch(apiUrl);
      
      console.log('Lots API response status:', response.status);
      
      if (!response.ok) {
        const errorText = await response.text();
        console.error('Failed to fetch lots:', errorText);
        throw new Error('Failed to fetch lots from server');
      }

      const data = await response.json();
      console.log('Lots API response:', data);
      
      // Handle different response formats
      let lots = [];
      if (data.success && data.lots) {
        lots = data.lots;
      } else if (Array.isArray(data)) {
        lots = data;
      } else if (data.lots) {
        lots = data.lots;
      }
      
      console.log('Raw lots from API:', lots);
      
      // Filter for available lots (not in auction yet)
      const availableLots = lots.filter((lot: Lot) => 
        lot.status === 'available' || lot.status === 'created'
      );
      
      console.log('Available lots after filtering:', availableLots);
      setAvailableLots(availableLots);
      
      if (availableLots.length === 0 && lots.length > 0) {
        const statusValues = Array.from(new Set(lots.map((l: Lot) => l.status))).join(', ');
        setError(`You have ${lots.length} lot(s), but none are available for auction. Status values found: ${statusValues}`);
        console.warn('No available lots. All lot statuses:', statusValues);
      } else if (availableLots.length === 0) {
        console.warn('No lots found at all for this farmer');
      }
    } catch (err: any) {
      console.error('Error fetching lots:', err);
      setError(err.message || 'Failed to load your lots');
    } finally {
      setLotsLoading(false);
    }
  };

  // Handle auction form changes
  const handleAuctionChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    setAuctionData({
      ...auctionData,
      [e.target.name]: e.target.value
    });
  };

  // Create auction for selected lot
  const createAuction = async () => {
    try {
      setIsLoading(true);
      setError('');
      setSuccess('');

      // Validation
      if (!selectedLot) {
        throw new Error('Please select a lot to auction');
      }

      if (!auctionData.startPrice || !auctionData.reservePrice || !auctionData.duration) {
        throw new Error('Please fill in all auction details');
      }

      if (!walletAddress) {
        throw new Error('Please connect your wallet');
      }

      // Clean and validate price inputs
      const cleanStartPrice = auctionData.startPrice.trim();
      const cleanReservePrice = auctionData.reservePrice.trim();

      // Validate price format
      const priceRegex = /^\d+(\.\d{1,18})?$/;
      if (!priceRegex.test(cleanStartPrice)) {
        throw new Error('Invalid start price format');
      }
      if (!priceRegex.test(cleanReservePrice)) {
        throw new Error('Invalid reserve price format');
      }

      const startPriceNum = parseFloat(cleanStartPrice);
      const reservePriceNum = parseFloat(cleanReservePrice);
      
      if (startPriceNum <= 0 || startPriceNum > 1000) {
        throw new Error('Start price must be between 0 and 1000 ETH');
      }
      if (reservePriceNum <= 0 || reservePriceNum > 1000) {
        throw new Error('Reserve price must be between 0 and 1000 ETH');
      }
      if (reservePriceNum < startPriceNum) {
        throw new Error('Reserve price must be >= start price');
      }

      // Convert to Wei
      const startPriceWei = ethers.parseEther(cleanStartPrice);
      const reservePriceWei = ethers.parseEther(cleanReservePrice);

      // Convert duration to seconds
      const durationSeconds = parseInt(auctionData.duration) * 24 * 60 * 60;

      // Create auction on blockchain
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);

      console.log('Creating auction...', {
        lotId: selectedLot.lot_id,
        startPrice: cleanStartPrice,
        reservePrice: cleanReservePrice,
        duration: durationSeconds
      });

      const tx = await contract.createAuction(
        selectedLot.lot_id,
        startPriceWei,
        reservePriceWei,
        durationSeconds
      );

      console.log('Transaction sent:', tx.hash);
      const receipt = await tx.wait();
      console.log('Transaction confirmed:', receipt.hash);

      // Calculate duration in seconds for backend
      const durationInSeconds = parseInt(auctionData.duration) * 24 * 60 * 60;

      // Save auction to backend
      const auctionResponse = await auctionApi.create({
        lotId: selectedLot.lot_id,
        farmerAddress: walletAddress,
        startPrice: cleanStartPrice,
        reservePrice: cleanReservePrice,
        duration: durationInSeconds, // Send duration in seconds, not days
      });

      if (!auctionResponse.data.success) {
        throw new Error(auctionResponse.data.error || 'Failed to create auction');
      }

      setSuccess(`✅ Auction created successfully for ${selectedLot.variety}!`);
      
      // Redirect to auctions page after 2 seconds
      setTimeout(() => {
        router.push('/auctions');
      }, 2000);

    } catch (err: any) {
      console.error('Error creating auction:', err);
      setError(err.message || 'Failed to create auction');
    } finally {
      setIsLoading(false);
    }
  };

  // Show wallet connection prompt if not connected
  if (!walletAddress) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4">
        <div className="max-w-4xl mx-auto">
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-12 text-center">
            <AlertCircle className="w-16 h-16 text-yellow-500 mx-auto mb-4" />
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
              Wallet Not Connected
            </h2>
            <p className="text-gray-600 dark:text-gray-400 mb-6">
              Please connect your MetaMask wallet to create an auction
            </p>
            <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-900 rounded-lg p-4 mb-6">
              <p className="text-sm text-blue-800 dark:text-blue-400">
                <strong>Debug Info:</strong><br />
                User wallet: {user?.walletAddress || 'Not set'}<br />
                Connected address: {connectedAddress || 'Not connected'}<br />
                Is connected: {isConnected ? 'Yes' : 'No'}
              </p>
            </div>
            <p className="text-sm text-gray-500 dark:text-gray-400 mb-8">
              👉 Click the "Connect Wallet" button in the header to get started
            </p>
            <Link
              href="/dashboard/farmer"
              className="inline-flex items-center space-x-2 px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors"
            >
              <span>← Back to Dashboard</span>
            </Link>
          </div>
        </div>
      </div>
    );
  }

  if (lotsLoading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4">
        <div className="max-w-4xl mx-auto">
          <div className="animate-pulse space-y-4">
            <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded w-1/3" />
            <div className="h-64 bg-gray-200 dark:bg-gray-700 rounded" />
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center space-x-3 mb-4">
            <Gavel className="w-10 h-10 text-blue-600 dark:text-blue-400" />
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                Create Auction
              </h1>
              <p className="text-gray-600 dark:text-gray-400">
                Select a lot and set auction parameters
              </p>
              {walletAddress && (
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                  Connected: {walletAddress.slice(0, 6)}...{walletAddress.slice(-4)}
                </p>
              )}
            </div>
          </div>
        </div>

        {/* Error Message */}
        {error && (
          <div className="mb-6 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-900 rounded-lg p-4">
            <div className="flex items-start space-x-3">
              <AlertCircle className="w-5 h-5 text-red-600 dark:text-red-400 mt-0.5 flex-shrink-0" />
              <p className="text-sm text-red-800 dark:text-red-400">{error}</p>
            </div>
          </div>
        )}

        {/* Success Message */}
        {success && (
          <div className="mb-6 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-900 rounded-lg p-4">
            <div className="flex items-start space-x-3">
              <CheckCircle className="w-5 h-5 text-green-600 dark:text-green-400 mt-0.5 flex-shrink-0" />
              <p className="text-sm text-green-800 dark:text-green-400">{success}</p>
            </div>
          </div>
        )}

        {/* No Lots Available */}
        {availableLots.length === 0 && (
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-12 text-center">
            <Package className="w-16 h-16 text-gray-400 mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
              No Lots Available
            </h3>
            <p className="text-gray-600 dark:text-gray-400 mb-6">
              You need to register a harvest before creating an auction
            </p>
            <Link
              href="/harvest/register"
              className="inline-flex items-center space-x-2 px-6 py-3 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors"
            >
              <Plus className="w-5 h-5" />
              <span>Register Harvest</span>
            </Link>
          </div>
        )}

        {/* Lot Selection */}
        {availableLots.length > 0 && (
          <div className="space-y-6">
            {/* Step 1: Select Lot */}
            <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
                  Step 1: Select Lot
                </h2>
                <Link
                  href="/harvest/register"
                  className="text-sm text-blue-600 dark:text-blue-400 hover:underline flex items-center space-x-1"
                >
                  <Plus className="w-4 h-4" />
                  <span>Register New Harvest</span>
                </Link>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {availableLots.map((lot) => (
                  <button
                    key={lot.lot_id}
                    onClick={() => setSelectedLot(lot)}
                    className={`p-4 rounded-lg border-2 text-left transition ${
                      selectedLot?.lot_id === lot.lot_id
                        ? 'border-blue-600 bg-blue-50 dark:bg-blue-900/20'
                        : 'border-gray-200 dark:border-gray-700 hover:border-blue-400'
                    }`}
                  >
                    <div className="flex items-start justify-between mb-2">
                      <div>
                        <h3 className="font-semibold text-gray-900 dark:text-white">
                          {lot.variety}
                        </h3>
                        <p className="text-sm text-gray-500 dark:text-gray-400">
                          Lot #{lot.lot_id}
                        </p>
                      </div>
                      {selectedLot?.lot_id === lot.lot_id && (
                        <CheckCircle className="w-5 h-5 text-blue-600 dark:text-blue-400" />
                      )}
                    </div>
                    <div className="space-y-1 text-sm">
                      <p className="text-gray-700 dark:text-gray-300">
                        <span className="font-medium">Quantity:</span> {lot.quantity} kg
                      </p>
                      <p className="text-gray-700 dark:text-gray-300">
                        <span className="font-medium">Quality:</span> Grade {lot.quality}
                      </p>
                      <p className="text-gray-700 dark:text-gray-300">
                        <span className="font-medium">Harvested:</span>{' '}
                        {new Date(lot.harvest_date).toLocaleDateString()}
                      </p>
                      {lot.origin && (
                        <p className="text-gray-700 dark:text-gray-300">
                          <span className="font-medium">Origin:</span> {lot.origin}
                        </p>
                      )}
                    </div>
                  </button>
                ))}
              </div>
            </div>

            {/* Step 2: Auction Details */}
            {selectedLot && (
              <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
                <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
                  Step 2: Set Auction Parameters
                </h2>

                <div className="space-y-6">
                  {/* Start Price */}
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                      Start Price (ETH) <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="number"
                      name="startPrice"
                      value={auctionData.startPrice}
                      onChange={handleAuctionChange}
                      placeholder="0.1"
                      required
                      min="0.001"
                      step="0.001"
                      className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                    />
                  </div>

                  {/* Reserve Price */}
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                      Reserve Price (ETH) <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="number"
                      name="reservePrice"
                      value={auctionData.reservePrice}
                      onChange={handleAuctionChange}
                      placeholder="0.2"
                      required
                      min="0.001"
                      step="0.001"
                      className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                    />
                    <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                      Minimum price you'll accept
                    </p>
                  </div>

                  {/* Duration */}
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                      Duration (days) <span className="text-red-500">*</span>
                    </label>
                    <select
                      name="duration"
                      value={auctionData.duration}
                      onChange={handleAuctionChange}
                      className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                    >
                      <option value="1">1 Day</option>
                      <option value="3">3 Days</option>
                      <option value="7">7 Days</option>
                      <option value="14">14 Days</option>
                      <option value="30">30 Days</option>
                    </select>
                  </div>
                </div>

                {/* Submit Button */}
                <div className="mt-8 flex space-x-4">
                  <button
                    type="button"
                    onClick={() => router.back()}
                    className="flex-1 px-6 py-3 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition"
                  >
                    Cancel
                  </button>
                  <button
                    type="button"
                    onClick={createAuction}
                    disabled={isLoading}
                    className="flex-1 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition disabled:bg-gray-400 disabled:cursor-not-allowed flex items-center justify-center space-x-2"
                  >
                    {isLoading ? (
                      <>
                        <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                        <span>Creating Auction...</span>
                      </>
                    ) : (
                      <>
                        <Gavel className="w-5 h-5" />
                        <span>Create Auction</span>
                      </>
                    )}
                  </button>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

