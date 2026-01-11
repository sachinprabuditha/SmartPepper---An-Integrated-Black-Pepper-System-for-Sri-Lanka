'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { Sprout, MapPin, Calendar, Package, Shield, AlertCircle, Wallet } from 'lucide-react';
import { ethers } from 'ethers';

export default function HarvestRegistrationPage() {
  const router = useRouter();
  const { user } = useAuth();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [walletConnected, setWalletConnected] = useState(false);
  const [connectedAddress, setConnectedAddress] = useState('');

  const [harvestData, setHarvestData] = useState({
    variety: '',
    quantity: '',
    quality: 'A',
    harvestDate: '',
    origin: '',
    farmLocation: '',
    organicCertified: false,
  });

  // Check wallet connection on mount
  useEffect(() => {
    checkWalletConnection();
  }, []);

  // Redirect if not farmer
  useEffect(() => {
    if (user && user.role !== 'farmer') {
      router.push('/dashboard');
    }
  }, [user, router]);

  const checkWalletConnection = async () => {
    if (typeof window.ethereum !== 'undefined') {
      try {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const accounts = await provider.listAccounts();
        if (accounts.length > 0) {
          const signer = await provider.getSigner();
          const address = await signer.getAddress();
          setConnectedAddress(address);
          setWalletConnected(true);
        }
      } catch (error) {
        console.error('Error checking wallet connection:', error);
      }
    }
  };

  const connectWallet = async () => {
    if (typeof window.ethereum === 'undefined') {
      setError('Please install MetaMask to connect your wallet');
      return;
    }

    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      await provider.send('eth_requestAccounts', []);
      const signer = await provider.getSigner();
      const address = await signer.getAddress();
      setConnectedAddress(address);
      setWalletConnected(true);
      setError('');
    } catch (error: any) {
      setError('Failed to connect wallet: ' + error.message);
    }
  };

  // Redirect if not farmer
  if (user && user.role !== 'farmer') {
    router.push('/dashboard');
    return null;
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value, type } = e.target;
    setHarvestData({
      ...harvestData,
      [name]: type === 'checkbox' ? (e.target as HTMLInputElement).checked : value
    });
  };

  const generateLotId = () => {
    const timestamp = Date.now().toString().slice(-6);
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
    return `LOT${timestamp}${random}`;
  };

  const registerHarvest = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      setIsLoading(true);
      setError('');
      setSuccess('');

      // Validation
      if (!harvestData.variety || !harvestData.quantity || !harvestData.harvestDate || !harvestData.origin) {
        throw new Error('Please fill in all required fields');
      }

      if (!walletConnected || !connectedAddress) {
        throw new Error('Please connect your wallet');
      }

      const farmerAddress = user?.walletAddress || connectedAddress;

      // Generate lot ID
      const lotId = generateLotId();

      // Step 1: Generate metadata for NFT
      const metadataResponse = await fetch('/api/nft-passport/metadata', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          lotData: {
            lotId,
            variety: harvestData.variety,
            quantity: harvestData.quantity,
            origin: harvestData.origin,
            harvestDate: harvestData.harvestDate,
            quality: harvestData.quality,
            farmerAddress: farmerAddress,
          },
          farmerData: {
            name: user?.name || 'Farmer',
            address: farmerAddress,
          }
        }),
      });

      if (!metadataResponse.ok) {
        const errorData = await metadataResponse.json().catch(() => ({}));
        throw new Error(errorData.error || 'Failed to generate metadata');
      }

      const metadataResult = await metadataResponse.json();
      const metadata = metadataResult.data;
      
      // For now, we'll use a JSON string as metadata URI (could be IPFS later)
      const metadataURI = `data:application/json;base64,${btoa(JSON.stringify(metadata))}`;

      // Step 2: Create lot on blockchain (which will auto-mint NFT passport)
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();

      // Get contract addresses from environment
      const auctionContractAddress = process.env.NEXT_PUBLIC_CONTRACT_ADDRESS;
      
      if (!auctionContractAddress) {
        throw new Error('Contract address not configured');
      }

      // PepperAuction ABI with updated createLot function
      const auctionABI = [
        "function createLot(string memory lotId, string memory variety, uint256 quantity, string memory quality, string memory harvestDate, bytes32 certificateHash, string memory origin, string memory metadataURI) external"
      ];

      const contract = new ethers.Contract(auctionContractAddress, auctionABI, signer);

      // Create certificate hash
      const certificateData = JSON.stringify({
        variety: harvestData.variety,
        quantity: harvestData.quantity,
        quality: harvestData.quality,
        harvestDate: harvestData.harvestDate,
        origin: harvestData.origin,
        farmLocation: harvestData.farmLocation,
        organicCertified: harvestData.organicCertified,
        farmer: farmerAddress,
        timestamp: Date.now(),
      });
      const certificateHash = ethers.keccak256(ethers.toUtf8Bytes(certificateData));

      console.log('Creating lot on blockchain...', {
        lotId,
        variety: harvestData.variety,
        quantity: harvestData.quantity,
        origin: harvestData.origin,
      });

      // Call blockchain
      const tx = await contract.createLot(
        lotId,
        harvestData.variety,
        ethers.parseUnits(harvestData.quantity.toString(), 0),
        harvestData.quality,
        harvestData.harvestDate,
        certificateHash,
        harvestData.origin,
        metadataURI
      );

      console.log('Transaction sent:', tx.hash);
      const receipt = await tx.wait();
      console.log('Transaction confirmed:', receipt.hash);

      // Step 3: Register in backend database
      const backendResponse = await fetch('/api/lots', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          lotId,
          variety: harvestData.variety,
          quantity: harvestData.quantity,
          quality: harvestData.quality,
          harvestDate: harvestData.harvestDate,
          farmerAddress: farmerAddress,
          certificateHash,
          origin: harvestData.origin,
          farmLocation: harvestData.farmLocation,
          organicCertified: harvestData.organicCertified,
          metadataURI,
        }),
      });

      if (!backendResponse.ok) {
        const errorData = await backendResponse.json();
        throw new Error(errorData.error || 'Failed to register in database');
      }

      const result = await backendResponse.json();
      console.log('Lot registered in database:', result);

      setSuccess(`✅ Harvest registered successfully! Lot ID: ${lotId}. NFT Passport created.`);
      
      // Redirect to passports page after 2 seconds
      setTimeout(() => {
        router.push('/dashboard/farmer/passports');
      }, 2000);

    } catch (err: any) {
      console.error('Error registering harvest:', err);
      setError(err.message || 'Failed to register harvest');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4">
      <div className="max-w-3xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center space-x-3 mb-4">
            <Sprout className="w-10 h-10 text-green-600 dark:text-green-400" />
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                Register Harvest
              </h1>
              <p className="text-gray-600 dark:text-gray-400">
                Record your harvest details on blockchain and create NFT passport
              </p>
            </div>
          </div>
        </div>

        {/* Info Card */}
        <div className="mb-6 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-900 p-4">
          <div className="flex items-start space-x-3">
            <Shield className="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5 flex-shrink-0" />
            <div className="flex-1">
              <h3 className="text-sm font-medium text-blue-900 dark:text-blue-300 mb-1">
                About Harvest Registration
              </h3>
              <p className="text-sm text-blue-800 dark:text-blue-400">
                This creates a blockchain record and NFT passport for your harvest. 
                After registration, you can create auctions for your lots from the dashboard.
              </p>
            </div>
          </div>
        </div>

        {/* Wallet Connection Card */}
        {!walletConnected && (
          <div className="mb-6 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg border border-yellow-200 dark:border-yellow-900 p-4">
            <div className="flex items-start justify-between">
              <div className="flex items-start space-x-3">
                <Wallet className="w-5 h-5 text-yellow-600 dark:text-yellow-400 mt-0.5 flex-shrink-0" />
                <div className="flex-1">
                  <h3 className="text-sm font-medium text-yellow-900 dark:text-yellow-300 mb-1">
                    Wallet Connection Required
                  </h3>
                  <p className="text-sm text-yellow-800 dark:text-yellow-400">
                    Connect your MetaMask wallet to register harvest on blockchain
                  </p>
                </div>
              </div>
              <button
                onClick={connectWallet}
                className="ml-4 px-4 py-2 bg-yellow-600 hover:bg-yellow-700 text-white rounded-lg text-sm font-medium transition-colors flex items-center space-x-2"
              >
                <Wallet className="w-4 h-4" />
                <span>Connect Wallet</span>
              </button>
            </div>
          </div>
        )}

        {/* Wallet Connected Status */}
        {walletConnected && (
          <div className="mb-6 bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-200 dark:border-green-900 p-4">
            <div className="flex items-start space-x-3">
              <Wallet className="w-5 h-5 text-green-600 dark:text-green-400 mt-0.5 flex-shrink-0" />
              <div className="flex-1">
                <h3 className="text-sm font-medium text-green-900 dark:text-green-300 mb-1">
                  Wallet Connected
                </h3>
                <p className="text-sm text-green-800 dark:text-green-400 font-mono">
                  {connectedAddress}
                </p>
              </div>
            </div>
          </div>
        )}

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
              <Shield className="w-5 h-5 text-green-600 dark:text-green-400 mt-0.5 flex-shrink-0" />
              <p className="text-sm text-green-800 dark:text-green-400">{success}</p>
            </div>
          </div>
        )}

        {/* Form */}
        <form onSubmit={registerHarvest} className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
          <div className="space-y-6">
            {/* Pepper Variety */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                <Package className="w-4 h-4 inline mr-1" />
                Pepper Variety <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                name="variety"
                value={harvestData.variety}
                onChange={handleChange}
                placeholder="e.g., Ceylon Black Pepper, Kampot Pepper"
                required
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
              />
            </div>

            {/* Quantity */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Quantity (kg) <span className="text-red-500">*</span>
              </label>
              <input
                type="number"
                name="quantity"
                value={harvestData.quantity}
                onChange={handleChange}
                placeholder="1000"
                required
                min="1"
                step="0.01"
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
              />
            </div>

            {/* Quality Grade */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Quality Grade <span className="text-red-500">*</span>
              </label>
              <select
                name="quality"
                value={harvestData.quality}
                onChange={handleChange}
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
              >
                <option value="A">A - Premium</option>
                <option value="B">B - High Quality</option>
                <option value="C">C - Standard</option>
              </select>
            </div>

            {/* Harvest Date */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                <Calendar className="w-4 h-4 inline mr-1" />
                Harvest Date <span className="text-red-500">*</span>
              </label>
              <input
                type="date"
                name="harvestDate"
                value={harvestData.harvestDate}
                onChange={handleChange}
                required
                max={new Date().toISOString().split('T')[0]}
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
              />
            </div>

            {/* Origin (for NFT) */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                <MapPin className="w-4 h-4 inline mr-1" />
                Origin/Region <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                name="origin"
                value={harvestData.origin}
                onChange={handleChange}
                placeholder="e.g., Matale District, Sri Lanka"
                required
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
              />
            </div>

            {/* Farm Location */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Farm Location (Optional)
              </label>
              <input
                type="text"
                name="farmLocation"
                value={harvestData.farmLocation}
                onChange={handleChange}
                placeholder="GPS coordinates or address"
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
              />
            </div>

            {/* Organic Certified */}
            <div className="flex items-center space-x-3">
              <input
                type="checkbox"
                name="organicCertified"
                checked={harvestData.organicCertified}
                onChange={handleChange}
                className="w-4 h-4 text-green-600 border-gray-300 rounded focus:ring-green-500"
              />
              <label className="text-sm font-medium text-gray-700 dark:text-gray-300">
                Organic Certified
              </label>
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
              type="submit"
              disabled={isLoading || !walletConnected}
              className="flex-1 px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition disabled:bg-gray-400 disabled:cursor-not-allowed flex items-center justify-center space-x-2"
            >
              {isLoading ? (
                <>
                  <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                  <span>Registering...</span>
                </>
              ) : !walletConnected ? (
                <>
                  <Wallet className="w-5 h-5" />
                  <span>Connect Wallet to Continue</span>
                </>
              ) : (
                <>
                  <Shield className="w-5 h-5" />
                  <span>Register Harvest & Create NFT</span>
                </>
              )}
            </button>
          </div>
        </form>

        {/* Info Footer */}
        <div className="mt-6 text-center text-sm text-gray-600 dark:text-gray-400">
          <p>
            After registration, you can find your lot in{' '}
            <button
              onClick={() => router.push('/dashboard/farmer/passports')}
              className="text-green-600 dark:text-green-400 hover:underline"
            >
              My NFT Passports
            </button>
            {' '}and create auctions for it.
          </p>
        </div>
      </div>
    </div>
  );
}
