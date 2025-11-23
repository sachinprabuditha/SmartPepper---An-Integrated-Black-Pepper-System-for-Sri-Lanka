'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { lotApi, auctionApi } from '@/lib/api';
import { ethers } from 'ethers';
import { CONTRACT_ADDRESS, CONTRACT_ABI } from '@/config/contracts';

export default function CreateAuctionPage() {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(false);
  const [currentStep, setCurrentStep] = useState(1);
  const [error, setError] = useState('');
  const [walletAddress, setWalletAddress] = useState('');
  
  // Lot details
  const [lotData, setLotData] = useState({
    lotId: '',
    variety: '',
    quantity: '',
    quality: 'A',
    harvestDate: '',
  });

  // Auction details
  const [auctionData, setAuctionData] = useState({
    startPrice: '',
    reservePrice: '',
    duration: '3', // days
  });

  // Connect wallet
  const connectWallet = async () => {
    try {
      if (typeof window.ethereum === 'undefined') {
        setError('Please install MetaMask to create auctions');
        return;
      }

      const provider = new ethers.BrowserProvider(window.ethereum);
      const accounts = await provider.send('eth_requestAccounts', []);
      setWalletAddress(accounts[0]);
      setError('');
    } catch (err: any) {
      setError('Failed to connect wallet: ' + err.message);
    }
  };

  // Generate unique lot ID
  const generateLotId = () => {
    const timestamp = Date.now().toString().slice(-6);
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
    return `LOT${timestamp}${random}`;
  };

  // Handle lot form changes
  const handleLotChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    setLotData({
      ...lotData,
      [e.target.name]: e.target.value
    });
  };

  // Handle auction form changes
  const handleAuctionChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    setAuctionData({
      ...auctionData,
      [e.target.name]: e.target.value
    });
  };

  // Step 1: Create lot on blockchain and backend
  const createLot = async () => {
    try {
      setIsLoading(true);
      setError('');

      // Validation
      if (!lotData.variety || !lotData.quantity || !lotData.harvestDate) {
        throw new Error('Please fill in all lot details');
      }

      if (!walletAddress) {
        throw new Error('Please connect your wallet first');
      }

      // Generate lot ID if not provided
      const lotId = lotData.lotId || generateLotId();

      // Register lot on blockchain
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);

      // Create certificate hash (simplified - in production, upload to IPFS)
      const certificateData = JSON.stringify({
        variety: lotData.variety,
        quantity: lotData.quantity,
        quality: lotData.quality,
        harvestDate: lotData.harvestDate,
        farmer: walletAddress,
      });
      const certificateHash = ethers.keccak256(ethers.toUtf8Bytes(certificateData));

      // Register lot on smart contract
      const tx = await contract.createLot(
        lotId,
        lotData.variety,
        ethers.parseUnits(lotData.quantity, 0), // Convert to wei-like units
        lotData.quality,
        lotData.harvestDate,
        certificateHash
      );

      await tx.wait();

      // Save lot to backend
      const lotResponse = await lotApi.create({
        lotId,
        farmerAddress: walletAddress,
        variety: lotData.variety,
        quantity: lotData.quantity,
        quality: lotData.quality,
        harvestDate: lotData.harvestDate,
        certificateHash,
        certificateIpfsUrl: '', // TODO: Implement IPFS upload
        txHash: tx.hash,
      });

      if (!lotResponse.data.success) {
        throw new Error(lotResponse.data.error || 'Failed to create lot');
      }

      // Update lot ID and move to next step
      setLotData({ ...lotData, lotId });
      setCurrentStep(2);
    } catch (err: any) {
      console.error('Error creating lot:', err);
      setError(err.message || 'Failed to create lot');
    } finally {
      setIsLoading(false);
    }
  };

  // Step 2: Create auction on blockchain and backend
  const createAuction = async () => {
    try {
      setIsLoading(true);
      setError('');

      // Validation
      if (!auctionData.startPrice || !auctionData.reservePrice || !auctionData.duration) {
        throw new Error('Please fill in all auction details');
      }

      // Clean and validate price inputs
      const cleanStartPrice = auctionData.startPrice.trim();
      const cleanReservePrice = auctionData.reservePrice.trim();

      // Validate price format (must be valid number with max 18 decimals for ETH)
      const priceRegex = /^\d+(\.\d{1,18})?$/;
      if (!priceRegex.test(cleanStartPrice)) {
        throw new Error('Invalid start price format. Use numbers with up to 18 decimal places.');
      }
      if (!priceRegex.test(cleanReservePrice)) {
        throw new Error('Invalid reserve price format. Use numbers with up to 18 decimal places.');
      }

      // Limit to reasonable ETH amounts (e.g., max 1000 ETH)
      const startPriceNum = parseFloat(cleanStartPrice);
      const reservePriceNum = parseFloat(cleanReservePrice);
      
      if (startPriceNum <= 0 || startPriceNum > 1000) {
        throw new Error('Start price must be between 0 and 1000 ETH');
      }
      if (reservePriceNum <= 0 || reservePriceNum > 1000) {
        throw new Error('Reserve price must be between 0 and 1000 ETH');
      }

      // Convert to Wei - parseEther handles the conversion
      let startPriceWei, reservePriceWei;
      try {
        startPriceWei = ethers.parseEther(cleanStartPrice);
        reservePriceWei = ethers.parseEther(cleanReservePrice);
      } catch (parseError: any) {
        throw new Error('Invalid price format: ' + parseError.message);
      }

      if (reservePriceWei < startPriceWei) {
        throw new Error('Reserve price must be greater than or equal to start price');
      }

      // Create auction on blockchain
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);

      // Duration in seconds (days * 24 * 60 * 60)
      const durationSeconds = parseInt(auctionData.duration) * 24 * 60 * 60;

      const tx = await contract.createAuction(
        lotData.lotId,
        startPriceWei,
        reservePriceWei,
        durationSeconds
      );

      await tx.wait();

      // Save auction to backend
      const auctionResponse = await auctionApi.create({
        lotId: lotData.lotId,
        farmerAddress: walletAddress,
        startPrice: startPriceWei.toString(),
        reservePrice: reservePriceWei.toString(),
        duration: durationSeconds,
      });

      if (!auctionResponse.data.success) {
        throw new Error(auctionResponse.data.error || 'Failed to create auction');
      }

      // Success! Redirect to auction page
      setCurrentStep(3);
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

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-3xl mx-auto px-4">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Create New Auction</h1>
          <p className="mt-2 text-gray-600">
            List your pepper lot for auction on the blockchain
          </p>
        </div>

        {/* Progress Steps */}
        <div className="mb-8">
          <div className="flex items-center justify-between">
            <div className={`flex-1 ${currentStep >= 1 ? 'text-green-600' : 'text-gray-400'}`}>
              <div className="flex items-center">
                <div className={`w-8 h-8 rounded-full flex items-center justify-center ${
                  currentStep >= 1 ? 'bg-green-600 text-white' : 'bg-gray-300'
                }`}>
                  {currentStep > 1 ? '✓' : '1'}
                </div>
                <span className="ml-2 font-medium">Lot Details</span>
              </div>
            </div>
            <div className="flex-1 mx-4 h-1 bg-gray-300">
              <div 
                className={`h-full ${currentStep >= 2 ? 'bg-green-600' : 'bg-gray-300'}`}
                style={{ width: currentStep >= 2 ? '100%' : '0%', transition: 'width 0.3s' }}
              />
            </div>
            <div className={`flex-1 ${currentStep >= 2 ? 'text-green-600' : 'text-gray-400'}`}>
              <div className="flex items-center">
                <div className={`w-8 h-8 rounded-full flex items-center justify-center ${
                  currentStep >= 2 ? 'bg-green-600 text-white' : 'bg-gray-300'
                }`}>
                  {currentStep > 2 ? '✓' : '2'}
                </div>
                <span className="ml-2 font-medium">Auction Settings</span>
              </div>
            </div>
          </div>
        </div>

        {/* Error Message */}
        {error && (
          <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-red-600">{error}</p>
          </div>
        )}

        {/* Wallet Connection */}
        {!walletAddress && (
          <div className="mb-6 p-6 bg-white rounded-lg shadow-sm border border-gray-200">
            <h2 className="text-lg font-semibold mb-2">Connect Wallet</h2>
            <p className="text-gray-600 mb-4">
              You need to connect your wallet to create an auction
            </p>
            <button
              onClick={connectWallet}
              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
            >
              Connect MetaMask
            </button>
          </div>
        )}

        {walletAddress && (
          <div className="mb-6 p-4 bg-green-50 border border-green-200 rounded-lg">
            <p className="text-sm text-green-800">
              <span className="font-medium">Connected:</span> {walletAddress}
            </p>
          </div>
        )}

        {/* Step 1: Lot Details Form */}
        {currentStep === 1 && walletAddress && (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h2 className="text-xl font-semibold mb-4">Pepper Lot Details</h2>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Lot ID (Optional - auto-generated if empty)
                </label>
                <input
                  type="text"
                  name="lotId"
                  value={lotData.lotId}
                  onChange={handleLotChange}
                  placeholder="LOT123456789"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Pepper Variety <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  name="variety"
                  value={lotData.variety}
                  onChange={handleLotChange}
                  placeholder="e.g., Kampot Black Pepper"
                  required
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Quantity (kg) <span className="text-red-500">*</span>
                </label>
                <input
                  type="number"
                  name="quantity"
                  value={lotData.quantity}
                  onChange={handleLotChange}
                  placeholder="1000"
                  required
                  min="1"
                  step="0.01"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Quality Grade <span className="text-red-500">*</span>
                </label>
                <select
                  name="quality"
                  value={lotData.quality}
                  onChange={handleLotChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="A">A - Premium</option>
                  <option value="B">B - High Quality</option>
                  <option value="C">C - Standard</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Harvest Date <span className="text-red-500">*</span>
                </label>
                <input
                  type="date"
                  name="harvestDate"
                  value={lotData.harvestDate}
                  onChange={handleLotChange}
                  required
                  max={new Date().toISOString().split('T')[0]}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
            </div>

            <div className="mt-6 flex justify-end">
              <button
                onClick={createLot}
                disabled={isLoading}
                className="px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition disabled:bg-gray-400 disabled:cursor-not-allowed"
              >
                {isLoading ? 'Creating Lot...' : 'Create Lot & Continue'}
              </button>
            </div>
          </div>
        )}

        {/* Step 2: Auction Settings Form */}
        {currentStep === 2 && (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h2 className="text-xl font-semibold mb-4">Auction Settings</h2>
            
            <div className="mb-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <p className="text-sm text-blue-800">
                <span className="font-medium">Lot Created:</span> {lotData.lotId}
              </p>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Starting Price (ETH) <span className="text-red-500">*</span>
                </label>
                <input
                  type="number"
                  name="startPrice"
                  value={auctionData.startPrice}
                  onChange={handleAuctionChange}
                  placeholder="0.1"
                  required
                  min="0.001"
                  max="1000"
                  step="0.001"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
                <p className="mt-1 text-sm text-gray-500">
                  Enter price in ETH (e.g., 0.1 for small lots, 1.5 for larger lots)
                </p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Reserve Price (ETH) <span className="text-red-500">*</span>
                </label>
                <input
                  type="number"
                  name="reservePrice"
                  value={auctionData.reservePrice}
                  onChange={handleAuctionChange}
                  placeholder="0.5"
                  required
                  min="0.001"
                  max="1000"
                  step="0.001"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
                <p className="mt-1 text-sm text-gray-500">
                  Minimum price you're willing to accept (must be ≥ starting price)
                </p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Auction Duration (days) <span className="text-red-500">*</span>
                </label>
                <select
                  name="duration"
                  value={auctionData.duration}
                  onChange={handleAuctionChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="1">1 Day</option>
                  <option value="3">3 Days</option>
                  <option value="7">7 Days</option>
                  <option value="14">14 Days</option>
                  <option value="30">30 Days</option>
                </select>
              </div>

              {/* Price Summary */}
              <div className="p-4 bg-gray-50 rounded-lg">
                <h3 className="font-medium text-gray-900 mb-2">Summary</h3>
                <div className="space-y-1 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-600">Lot:</span>
                    <span className="font-medium">{lotData.lotId}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Variety:</span>
                    <span className="font-medium">{lotData.variety}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Quantity:</span>
                    <span className="font-medium">{lotData.quantity} kg</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Starting Price:</span>
                    <span className="font-medium">{auctionData.startPrice || '0'} ETH</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Reserve Price:</span>
                    <span className="font-medium">{auctionData.reservePrice || '0'} ETH</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="mt-6 flex justify-between">
              <button
                onClick={() => setCurrentStep(1)}
                className="px-6 py-3 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition"
              >
                Back
              </button>
              <button
                onClick={createAuction}
                disabled={isLoading}
                className="px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition disabled:bg-gray-400 disabled:cursor-not-allowed"
              >
                {isLoading ? 'Creating Auction...' : 'Create Auction'}
              </button>
            </div>
          </div>
        )}

        {/* Step 3: Success */}
        {currentStep === 3 && (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 text-center">
            <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg className="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <h2 className="text-2xl font-bold text-gray-900 mb-2">Auction Created Successfully!</h2>
            <p className="text-gray-600 mb-6">
              Your pepper lot has been registered on the blockchain and the auction is now live.
            </p>
            <div className="p-4 bg-green-50 rounded-lg mb-6">
              <p className="text-sm text-green-800">
                <span className="font-medium">Lot ID:</span> {lotData.lotId}
              </p>
            </div>
            <p className="text-sm text-gray-500">
              Redirecting to auctions page...
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
