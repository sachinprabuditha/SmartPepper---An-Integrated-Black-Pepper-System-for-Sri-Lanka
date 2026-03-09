'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import { useAccount, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther } from 'viem';
import { io, Socket } from 'socket.io-client';
import { auctionApi, lotApi } from '@/lib/api';
import { useAuctionStore, Auction, Bid } from '@/store/auctionStore';
import { PEPPER_AUCTION_ABI, CONTRACT_ADDRESS } from '@/config/contracts';
import { AuctionTimer } from '@/components/auction/AuctionTimer';
import { BidHistory } from '@/components/auction/BidHistory';
import { BidForm } from '@/components/auction/BidForm';
import { Loader2, CheckCircle, XCircle, User, Package, Calendar, Users, Wifi, DollarSign, ImageIcon, MapPin, Award, Sprout, Scale, TreeDeciduous } from 'lucide-react';
import toast from 'react-hot-toast';
import { exchangeRateService } from '@/services/exchangeRateService';

// Currency conversion helpers using live rates
function ethToLkr(ethAmount: number): number {
  return exchangeRateService.ethToLkr(ethAmount);
}

function lkrToEth(lkrAmount: number): number {
  return exchangeRateService.lkrToEth(lkrAmount);
}

function formatLkr(amount: number): string {
  return exchangeRateService.formatLkr(amount);
}

function formatEth(amount: number): string {
  return exchangeRateService.formatEth(amount);
}

// IPFS URL converter helper with multiple gateways for redundancy
const IPFS_GATEWAYS = [
  'http://localhost:8080/ipfs',
  'https://ipfs.io/ipfs',
  'https://cf-ipfs.com/ipfs',
  'https://gateway.pinata.cloud/ipfs',
  'https://dweb.link/ipfs',
];

function extractCID(url: string): string | null {
  if (!url) return null;
  
  // If it's an ipfs:// URL, extract CID
  if (url.startsWith('ipfs://')) {
    return url.replace('ipfs://', '');
  }
  
  // If it's just a CID
  if (url.startsWith('Qm') || url.startsWith('bafy')) {
    return url;
  }
  
  // If it's already a gateway URL, extract CID
  const match = url.match(/\/ipfs\/([a-zA-Z0-9]+)/);
  if (match) {
    return match[1];
  }
  
  return null;
}

function convertToGatewayUrl(url: string, gatewayIndex: number = 0): string {
  if (!url) return '';
  
  // If it's already a full HTTP URL and not IPFS, return as is
  if ((url.startsWith('http://') || url.startsWith('https://')) && !url.includes('/ipfs/')) {
    return url;
  }
  
  const cid = extractCID(url);
  if (cid) {
    // Use the specified gateway (with fallback to first one)
    const gateway = IPFS_GATEWAYS[gatewayIndex] || IPFS_GATEWAYS[0];
    return `${gateway}/${cid}`;
  }
  
  // Otherwise return as is
  return url;
}

// Get all possible gateway URLs for an image
function getAllGatewayUrls(url: string): string[] {
  const cid = extractCID(url);
  if (!cid) return [url];
  
  return IPFS_GATEWAYS.map(gateway => `${gateway}/${cid}`);
}

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

// IPFSImage component with automatic gateway fallback
function IPFSImage({ 
  photoUrl, 
  index, 
  onClick 
}: { 
  photoUrl: string; 
  index: number; 
  onClick: () => void;
}) {
  const [currentGatewayIndex, setCurrentGatewayIndex] = useState(0);
  const [hasError, setHasError] = useState(false);
  const allUrls = getAllGatewayUrls(photoUrl);
  const currentUrl = allUrls[currentGatewayIndex] || allUrls[0];

  const handleError = () => {
    console.error(`❌ Gateway ${currentGatewayIndex + 1}/${allUrls.length} failed:`, currentUrl);
    
    // Try next gateway
    if (currentGatewayIndex < allUrls.length - 1) {
      console.log(`🔄 Trying next gateway (${currentGatewayIndex + 2}/${allUrls.length})...`);
      setCurrentGatewayIndex(prev => prev + 1);
      setHasError(false);
    } else {
      console.error(`❌ All ${allUrls.length} gateways failed for photo ${index + 1}`);
      setHasError(true);
    }
  };

  const handleLoad = () => {
    console.log(`✅ Image ${index + 1} loaded successfully via gateway ${currentGatewayIndex + 1}`);
  };

  return (
    <div 
      className="relative aspect-square rounded-lg overflow-hidden bg-gray-100 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 hover:shadow-lg transition-shadow cursor-pointer group"
      onClick={onClick}
    >
      {hasError ? (
        <div className="w-full h-full flex items-center justify-center bg-gray-200 dark:bg-gray-700">
          <div className="text-center p-4">
            <XCircle className="w-8 h-8 mx-auto mb-2 text-gray-400" />
            <p className="text-xs text-gray-500 dark:text-gray-400">Failed to load</p>
          </div>
        </div>
      ) : (
        <>
          <img
            src={currentUrl}
            alt={`Lot photo ${index + 1}`}
            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-200"
            onError={handleError}
            onLoad={handleLoad}
          />
          <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors flex items-center justify-center">
            <span className="text-white opacity-0 group-hover:opacity-100 transition-opacity text-sm font-medium">
              Click to view
            </span>
          </div>
        </>
      )}
    </div>
  );
}

export default function AuctionDetailPage() {
  const params = useParams();
  const auctionId = params.id as string;
  const { address } = useAccount();
  
  const [auction, setAuction] = useState<Auction | null>(null);
  const [bids, setBids] = useState<Bid[]>([]);
  const [loading, setLoading] = useState(true);
  const [socket, setSocket] = useState<Socket | null>(null);
  const [connectedUsers, setConnectedUsers] = useState(0);
  const [wsConnected, setWsConnected] = useState(false);
  const [lotData, setLotData] = useState<any>(null);
  const [loadingLot, setLoadingLot] = useState(false);
  
  const { joinAuction, leaveAuction, connected } = useAuctionStore();

  // Initialize exchange rate service
  useEffect(() => {
    exchangeRateService.initialize();
    return () => {
      exchangeRateService.stopUpdates();
    };
  }, []);

  useEffect(() => {
    async function fetchAuction() {
      try {
        setLoading(true);
        const response = await auctionApi.getById(parseInt(auctionId));
        // Transform snake_case to camelCase
        const transformedAuction = toCamelCase(response.data.auction);
        const transformedBids = toCamelCase(response.data.bids || []);
        
        console.log('📊 Fetched auction:', transformedAuction);
        console.log('📊 Auction ID:', transformedAuction.auctionId, typeof transformedAuction.auctionId);
        
        setAuction(transformedAuction);
        setBids(transformedBids);
      } catch (error) {
        console.error('Failed to fetch auction:', error);
        toast.error('Failed to load auction details');
      } finally {
        setLoading(false);
      }
    }

    if (auctionId) {
      fetchAuction();
    }
  }, [auctionId]);

  // Fetch lot data when auction is loaded
  useEffect(() => {
    async function fetchLot() {
      if (!auction?.lotId) return;
      
      try {
        setLoadingLot(true);
        const response = await lotApi.getById(auction.lotId);
        const lot = response.data.lot;
        
        console.log('📦 Fetched lot data:', lot);
        console.log('� Farmer name:', lot.farmer_name);
        console.log('📍 Farm location:', lot.farm_location);
        console.log('�🖼️ Lot pictures raw:', lot.lot_pictures, 'Type:', typeof lot.lot_pictures);
        
        // Parse lot_pictures if it's a string
        if (lot.lot_pictures && typeof lot.lot_pictures === 'string') {
          try {
            lot.lot_pictures = JSON.parse(lot.lot_pictures);
            console.log('✅ Parsed lot_pictures:', lot.lot_pictures);
          } catch (e) {
            console.error('❌ Failed to parse lot_pictures:', e);
            lot.lot_pictures = [];
          }
        }
        
        // Ensure lot_pictures is an array
        if (!Array.isArray(lot.lot_pictures)) {
          console.warn('⚠️ lot_pictures is not an array, converting:', lot.lot_pictures);
          lot.lot_pictures = [];
        }
        
        console.log('🎯 Final lot_pictures:', lot.lot_pictures, 'Count:', lot.lot_pictures.length);
        
        setLotData(lot);
      } catch (error) {
        console.error('Failed to fetch lot details:', error);
      } finally {
        setLoadingLot(false);
      }
    }

    fetchLot();
  }, [auction?.lotId]);

  useEffect(() => {
    if (auction && address && connected) {
      joinAuction(auction.auctionId, address);
      
      return () => {
        leaveAuction(auction.auctionId, address);
      };
    }
  }, [auction, address, connected, joinAuction, leaveAuction]);

  // WebSocket connection for real-time updates
  useEffect(() => {
    if (!auction) return;

    const newSocket = io('http://localhost:3002/auction', {
      transports: ['websocket', 'polling'],
    });

    newSocket.on('connect', () => {
      console.log('✅ WebSocket connected:', newSocket.id);
      setWsConnected(true);
      
      // Join auction room
      newSocket.emit('join_auction', {
        auctionId: auction.auctionId,
        userAddress: address || 'anonymous',
      });
    });

    newSocket.on('auction_joined', (data) => {
      console.log('Joined auction room:', data);
      toast.success('Connected to live auction updates');
      
      // Update auction state from server
      if (data.currentBid) {
        setAuction(prev => prev ? {
          ...prev,
          currentBid: data.currentBid,
          currentBidder: data.currentBidder,
          bidCount: data.bidCount || prev.bidCount,
        } : null);
      }
    });

    newSocket.on('new_bid', (bidData) => {
      console.log('🔔 New bid received:', bidData);
      
      // Update auction state
      setAuction(prev => prev ? {
        ...prev,
        currentBid: bidData.amount,
        currentBidder: bidData.bidder,
        bidCount: (prev.bidCount || 0) + 1,
      } : null);

      // Add bid to history (prepend to top)
      setBids(prev => [{
        id: `${bidData.bidder}-${bidData.timestamp}`,
        auctionId: auction.auctionId,
        bidderAddress: bidData.bidder,
        amount: bidData.amount,
        placedAt: bidData.timestamp,
        blockchainTxHash: bidData.txHash || '',
      } as Bid, ...prev]);

      // Show notification
      const isOwnBid = bidData.bidder.toLowerCase() === address?.toLowerCase();
      if (isOwnBid) {
        toast.success('Your bid has been placed!');
      } else {
        toast(`New bid: ${(parseFloat(bidData.amount) / 1e18).toFixed(4)} ETH`, {
          icon: '📢',
        });
      }
    });

    newSocket.on('user_joined', (data) => {
      console.log('User joined auction:', data.userAddress);
      setConnectedUsers(prev => prev + 1);
    });

    newSocket.on('user_left', (data) => {
      console.log('User left auction:', data.userAddress);
      setConnectedUsers(prev => Math.max(0, prev - 1));
    });

    newSocket.on('auction_ended', (data) => {
      console.log('🏁 Auction ended:', data);
      setAuction(prev => prev ? { ...prev, status: 'ended' } : null);
      toast.success('Auction has ended!');
    });

    newSocket.on('error', (error) => {
      console.error('WebSocket error:', error);
      toast.error('Connection error - retrying...');
    });

    newSocket.on('disconnect', () => {
      console.log('❌ WebSocket disconnected');
      setWsConnected(false);
    });

    setSocket(newSocket);

    // Cleanup on unmount
    return () => {
      if (newSocket) {
        newSocket.emit('leave_auction', {
          auctionId: auction.auctionId,
          userAddress: address || 'anonymous',
        });
        newSocket.close();
      }
    };
  }, [auction, address]);

  if (loading) {
    return (
      <div className="container mx-auto px-4 py-12">
        <div className="flex justify-center items-center min-h-[400px]">
          <Loader2 className="w-12 h-12 animate-spin text-primary-600" />
        </div>
      </div>
    );
  }

  if (!auction) {
    return (
      <div className="container mx-auto px-4 py-12">
        <div className="card text-center py-12">
          <p className="text-xl text-gray-600 dark:text-gray-400">Auction not found</p>
        </div>
      </div>
    );
  }

  const isFarmer = address?.toLowerCase() === auction.farmerAddress.toLowerCase();
  const isActive = auction.status === 'active';
  const hasEnded = new Date(auction.endTime) <= new Date();

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="grid lg:grid-cols-3 gap-8">
        {/* Main Auction Details */}
        <div className="lg:col-span-2 space-y-6">
          {/* Header */}
          <div className="card">
            <div className="flex justify-between items-start mb-6">
              <div>
                <h1 className="text-3xl font-bold mb-2 dark:text-white">Auction #{auction.auctionId}</h1>
                <p className="text-gray-600 dark:text-gray-400">Lot ID: {auction.lotId}</p>
              </div>
              <div className="flex flex-col items-end gap-2">
                {isActive && (
                  <span className="badge-success flex items-center gap-2">
                    <span className="inline-block w-2 h-2 bg-green-500 rounded-full animate-pulse"></span>
                    Live Auction
                  </span>
                )}
                {/* WebSocket connection status */}
                {wsConnected && (
                  <div className="flex items-center gap-2 px-3 py-1 bg-green-50 border border-green-200 rounded-lg text-xs">
                    <Wifi className="w-3 h-3 text-green-600" />
                    <span className="text-green-700">Real-time updates active</span>
                  </div>
                )}
                {/* Connected viewers */}
                {connectedUsers > 0 && (
                  <div className="flex items-center gap-2 px-3 py-1 bg-blue-50 border border-blue-200 rounded-lg text-xs">
                    <Users className="w-3 h-3 text-blue-600" />
                    <span className="text-blue-700">{connectedUsers + 1} viewer{connectedUsers !== 0 ? 's' : ''}</span>
                  </div>
                )}
                {auction.status === 'ended' && <span className="badge-warning">Ended</span>}
                {auction.status === 'settled' && <span className="badge-info">Settled</span>}
              </div>
            </div>

            {/* Compliance Status */}
            <div className="flex items-center gap-3 mb-6 p-4 bg-gray-50 dark:bg-gray-900 rounded-lg">
              {auction.compliancePassed ? (
                <>
                  <CheckCircle className="w-6 h-6 text-green-600" />
                  <div>
                    <p className="font-semibold text-green-700 dark:text-green-400">Compliance Passed</p>
                    <p className="text-sm text-gray-600 dark:text-gray-400">All certifications verified</p>
                  </div>
                </>
              ) : (
                <>
                  <XCircle className="w-6 h-6 text-red-600" />
                  <div>
                    <p className="font-semibold text-red-700 dark:text-red-400">Compliance Pending</p>
                    <p className="text-sm text-gray-600 dark:text-gray-400">Awaiting certificate validation</p>
                  </div>
                </>
              )}
            </div>

            {/* Farmer Information */}
            {lotData && (
              <div className="mb-6 p-5 bg-gradient-to-br from-emerald-50 to-green-50 dark:from-emerald-900/20 dark:to-green-900/20 rounded-lg border border-emerald-200 dark:border-emerald-800">
                <div className="flex items-center gap-2 mb-4">
                  <User className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
                  <h3 className="text-lg font-semibold text-emerald-900 dark:text-emerald-100">Farmer Information</h3>
                </div>
                <div className="grid md:grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-emerald-700 dark:text-emerald-300 mb-1">Name</p>
                    <p className="font-medium text-emerald-900 dark:text-emerald-50">
                      {lotData.farmer_name || lotData.farmerName || 'Unknown Farmer'}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-emerald-700 dark:text-emerald-300 mb-1">Wallet Address</p>
                    <p className="font-mono text-xs text-emerald-900 dark:text-emerald-50 break-all">
                      {auction.farmerAddress}
                    </p>
                  </div>
                  {(lotData.farm_location || lotData.farmLocation) && (
                    <div className="md:col-span-2">
                      <div className="flex items-center gap-2">
                        <MapPin className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
                        <p className="text-sm text-emerald-700 dark:text-emerald-300">Farm Location</p>
                      </div>
                      <p className="font-medium text-emerald-900 dark:text-emerald-50 mt-1">
                        {lotData.farm_location || lotData.farmLocation}
                      </p>
                    </div>
                  )}
                  {lotData.origin && (
                    <div className="md:col-span-2">
                      <div className="flex items-center gap-2">
                        <MapPin className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
                        <p className="text-sm text-emerald-700 dark:text-emerald-300">Origin</p>
                      </div>
                      <p className="font-medium text-emerald-900 dark:text-emerald-50 mt-1">
                        {lotData.origin}
                      </p>
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* Lot Details */}
            {lotData && (
              <div className="mb-6 p-5 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
                <div className="flex items-center gap-2 mb-4">
                  <Package className="w-5 h-5 text-gray-600 dark:text-gray-400" />
                  <h3 className="text-lg font-semibold dark:text-white">Lot Details</h3>
                </div>
                <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
                  {lotData.variety && (
                    <div className="flex items-start gap-3 p-3 bg-gray-50 dark:bg-gray-900 rounded-lg">
                      <TreeDeciduous className="w-5 h-5 text-primary-600 mt-0.5" />
                      <div>
                        <p className="text-sm text-gray-500 dark:text-gray-400">Variety</p>
                        <p className="font-semibold text-gray-900 dark:text-white">{lotData.variety}</p>
                      </div>
                    </div>
                  )}
                  {lotData.quantity && (
                    <div className="flex items-start gap-3 p-3 bg-gray-50 dark:bg-gray-900 rounded-lg">
                      <Scale className="w-5 h-5 text-primary-600 mt-0.5" />
                      <div>
                        <p className="text-sm text-gray-500 dark:text-gray-400">Quantity</p>
                        <p className="font-semibold text-gray-900 dark:text-white">{lotData.quantity} kg</p>
                      </div>
                    </div>
                  )}
                  {lotData.quality && (
                    <div className="flex items-start gap-3 p-3 bg-gray-50 dark:bg-gray-900 rounded-lg">
                      <Award className="w-5 h-5 text-primary-600 mt-0.5" />
                      <div>
                        <p className="text-sm text-gray-500 dark:text-gray-400">Quality Grade</p>
                        <p className="font-semibold text-gray-900 dark:text-white">{lotData.quality}</p>
                      </div>
                    </div>
                  )}
                  {lotData.harvest_date && (
                    <div className="flex items-start gap-3 p-3 bg-gray-50 dark:bg-gray-900 rounded-lg">
                      <Calendar className="w-5 h-5 text-primary-600 mt-0.5" />
                      <div>
                        <p className="text-sm text-gray-500 dark:text-gray-400">Harvest Date</p>
                        <p className="font-semibold text-gray-900 dark:text-white">
                          {new Date(lotData.harvest_date).toLocaleDateString()}
                        </p>
                      </div>
                    </div>
                  )}
                  {lotData.organic_certified !== undefined && (
                    <div className="flex items-start gap-3 p-3 bg-gray-50 dark:bg-gray-900 rounded-lg">
                      <Sprout className="w-5 h-5 text-primary-600 mt-0.5" />
                      <div>
                        <p className="text-sm text-gray-500 dark:text-gray-400">Organic Certified</p>
                        <p className="font-semibold text-gray-900 dark:text-white">
                          {lotData.organic_certified ? '✓ Yes' : '✗ No'}
                        </p>
                      </div>
                    </div>
                  )}
                  {lotData.certificate_hash && (
                    <div className="flex items-start gap-3 p-3 bg-gray-50 dark:bg-gray-900 rounded-lg">
                      <CheckCircle className="w-5 h-5 text-green-600 mt-0.5" />
                      <div>
                        <p className="text-sm text-gray-500 dark:text-gray-400">Certificate</p>
                        <p className="font-semibold text-green-600">Verified</p>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* Lot Photos Gallery */}
            {lotData?.lot_pictures && lotData.lot_pictures.length > 0 && (
              <div className="mb-6">
                <div className="flex items-center gap-2 mb-3">
                  <ImageIcon className="w-5 h-5 text-gray-600 dark:text-gray-400" />
                  <h3 className="text-lg font-semibold dark:text-white">Lot Photos</h3>
                  <span className="text-sm text-gray-500 dark:text-gray-400">
                    ({lotData.lot_pictures.length} {lotData.lot_pictures.length === 1 ? 'photo' : 'photos'})
                  </span>
                </div>
                <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                  {lotData.lot_pictures.map((photoUrl: string, index: number) => (
                    <IPFSImage
                      key={index}
                      photoUrl={photoUrl}
                      index={index}
                      onClick={() => {
                        const allUrls = getAllGatewayUrls(photoUrl);
                        window.open(allUrls[0], '_blank');
                      }}
                    />
                  ))}
                </div>
              </div>
            )}
            {loadingLot && (
              <div className="mb-6 p-4 bg-gray-50 dark:bg-gray-900 rounded-lg text-center">
                <Loader2 className="w-5 h-5 animate-spin text-primary-600 mx-auto" />
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-2">Loading lot photos...</p>
              </div>
            )}

            {/* Auction Details */}
            <div className="grid md:grid-cols-2 gap-6">
              <div className="space-y-4">
                <div className="flex items-center gap-3">
                  <Calendar className="w-5 h-5 text-gray-500" />
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Start Time</p>
                    <p className="font-medium">{new Date(auction.startTime).toLocaleString()}</p>
                  </div>
                </div>

                <div className="flex items-center gap-3">
                  <Calendar className="w-5 h-5 text-gray-500" />
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">End Time</p>
                    <p className="font-medium">{new Date(auction.endTime).toLocaleString()}</p>
                  </div>
                </div>
              </div>

              <div className="space-y-4">
                <div className="flex items-center gap-3">
                  <Package className="w-5 h-5 text-gray-500" />
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Total Bids</p>
                    <p className="text-2xl font-bold text-primary-600">{auction.bidCount}</p>
                  </div>
                </div>
                
                <div className="flex items-center gap-3">
                  <Users className="w-5 h-5 text-gray-500" />
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Status</p>
                    <p className="font-medium capitalize">{auction.status}</p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Pricing Information - Dual Currency Display */}
          <div className="card">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-semibold dark:text-white">Pricing</h2>
              <div className="flex items-center gap-2 px-3 py-1 bg-blue-50 border border-blue-200 rounded-lg text-xs">
                <DollarSign className="w-3 h-3 text-blue-600" />
                <span className="text-blue-700">Dual Currency</span>
              </div>
            </div>
            <div className="grid md:grid-cols-3 gap-6">
              <div className="p-4 bg-gray-50 dark:bg-gray-900 rounded-lg">
                <p className="text-sm text-gray-500 dark:text-gray-400 mb-2">Start Price</p>
                <p className="text-2xl font-bold text-gray-700 dark:text-gray-300">
                  {formatEth(parseFloat(auction.startPrice))}
                </p>
                <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                  ≈ {formatLkr(ethToLkr(parseFloat(auction.startPrice)))}
                </p>
              </div>
              <div className="p-4 bg-gray-50 dark:bg-gray-900 rounded-lg">
                <p className="text-sm text-gray-500 dark:text-gray-400 mb-2">Reserve Price</p>
                <p className="text-2xl font-bold text-gray-700 dark:text-gray-300">
                  {formatEth(parseFloat(auction.reservePrice))}
                </p>
                <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                  ≈ {formatLkr(ethToLkr(parseFloat(auction.reservePrice)))}
                </p>
              </div>
              <div className="p-4 bg-gradient-to-br from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20 rounded-lg border border-green-200 dark:border-green-800">
                <p className="text-sm text-gray-600 dark:text-gray-400 mb-2">Current Bid</p>
                {auction.currentBid !== '0' ? (
                  <>
                    <p className="text-3xl font-bold text-green-600 dark:text-green-400">
                      {formatEth(parseFloat(auction.currentBid))}
                    </p>
                    <p className="text-sm text-gray-600 dark:text-gray-400 mt-1 font-medium">
                      ≈ {formatLkr(ethToLkr(parseFloat(auction.currentBid)))}
                    </p>
                  </>
                ) : (
                  <p className="text-2xl font-bold text-gray-400">No bids yet</p>
                )}
              </div>
            </div>
            
            {/* Currency Information Footer */}
            <div className="mt-4 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
              <p className="text-xs text-blue-700 dark:text-blue-300">
                <span className="font-semibold">Exchange Rate:</span> 1 ETH ≈ {formatLkr(exchangeRateService.getRates().ethToLkr)} • All blockchain transactions use ETH
              </p>
            </div>
          </div>

          {/* Bid History */}
          <div className="card">
            <h2 className="text-xl font-semibold mb-4">Bid History</h2>
            <BidHistory auctionId={auction.auctionId} bids={bids} />
          </div>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Timer */}
          {isActive && !hasEnded && (
            <div className="card">
              <h3 className="text-lg font-semibold mb-4">Time Remaining</h3>
              <AuctionTimer endTime={auction.endTime} />
            </div>
          )}

          {/* Bid Form */}
          {isActive && !hasEnded && !isFarmer && auction.auctionId && (
            <div className="card">
              <h3 className="text-lg font-semibold mb-4">Place Your Bid</h3>
              <BidForm 
                auctionId={Number(auction.auctionId)}
                currentBid={auction.currentBid || '0'}
                minimumBid={auction.startPrice || '0'}
              />
            </div>
          )}

          {/* Farmer Actions */}
          {isFarmer && (
            <div className="card">
              <h3 className="text-lg font-semibold mb-4">Farmer Actions</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
                You are the owner of this auction
              </p>
              {hasEnded && auction.status === 'active' && (
                <button className="btn-primary w-full">
                  End Auction
                </button>
              )}
              {auction.status === 'ended' && (
                <button className="btn-success w-full">
                  Settle Auction
                </button>
              )}
            </div>
          )}

          {/* Transaction Info */}
          {auction.blockchainTxHash && (
            <div className="card">
              <h3 className="text-lg font-semibold mb-4">Blockchain</h3>
              <div className="space-y-2">
                <p className="text-sm text-gray-500 dark:text-gray-400">Transaction Hash</p>
                <p className="font-mono text-xs break-all">{auction.blockchainTxHash}</p>
                <a
                  href={`https://sepolia.etherscan.io/tx/${auction.blockchainTxHash}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-primary-600 hover:underline text-sm"
                >
                  View on Etherscan →
                </a>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
