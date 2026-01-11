'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import { useAccount, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther } from 'viem';
import { io, Socket } from 'socket.io-client';
import { auctionApi } from '@/lib/api';
import { useAuctionStore, Auction, Bid } from '@/store/auctionStore';
import { PEPPER_AUCTION_ABI, CONTRACT_ADDRESS } from '@/config/contracts';
import { AuctionTimer } from '@/components/auction/AuctionTimer';
import { BidHistory } from '@/components/auction/BidHistory';
import { BidForm } from '@/components/auction/BidForm';
import { Loader2, CheckCircle, XCircle, User, Package, Calendar, Users, Wifi, DollarSign } from 'lucide-react';
import toast from 'react-hot-toast';

// Currency conversion constants
const LKR_TO_ETH_RATE = 0.0000031; // 1 LKR ≈ 0.0000031 ETH
const ETH_TO_LKR_RATE = 322580.65; // 1 ETH ≈ 322,580 LKR

// Currency conversion helpers
function ethToLkr(ethAmount: number): number {
  return ethAmount * ETH_TO_LKR_RATE;
}

function formatLkr(amount: number): string {
  return new Intl.NumberFormat('en-LK', {
    style: 'currency',
    currency: 'LKR',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
}

function formatEth(amount: number): string {
  return `${amount.toFixed(4)} ETH`;
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
  
  const { joinAuction, leaveAuction, connected } = useAuctionStore();

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
        bidderAddress: bidData.bidder,
        amount: bidData.amount,
        timestamp: bidData.timestamp,
        auctionId: auction.auctionId,
      } as Bid, ...prev]);

      // Show notification
      const isOwnBid = bidData.bidder.toLowerCase() === address?.toLowerCase();
      if (isOwnBid) {
        toast.success('Your bid has been placed!');
      } else {
        toast.info(`New bid: ${(parseFloat(bidData.amount) / 1e18).toFixed(4)} ETH`);
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

            {/* Auction Details */}
            <div className="grid md:grid-cols-2 gap-6">
              <div className="space-y-4">
                <div className="flex items-center gap-3">
                  <User className="w-5 h-5 text-gray-500" />
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Farmer</p>
                    <p className="font-mono text-sm">{auction.farmerAddress}</p>
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
                <span className="font-semibold">Exchange Rate:</span> 1 ETH ≈ {formatLkr(ETH_TO_LKR_RATE)} • All blockchain transactions use ETH
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
