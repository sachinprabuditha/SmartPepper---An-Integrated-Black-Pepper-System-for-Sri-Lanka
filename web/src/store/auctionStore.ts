import { create } from 'zustand';
import { io, Socket } from 'socket.io-client';

export interface Auction {
  id: number;
  auctionId: number;
  lotId: string;
  farmerAddress: string;
  startPrice: string;
  reservePrice: string;
  currentBid: string;
  currentBidderAddress: string | null;
  startTime: string;
  endTime: string;
  status: string;
  compliancePassed: boolean;
  bidCount: number;
  blockchainTxHash: string;
  createdAt: string;
}

export interface Bid {
  id: string;
  auctionId: number;
  bidderAddress: string;
  amount: string;
  timestamp: string;
  blockchainTxHash: string;
}

export interface PepperLot {
  id: string;
  lotId: string;
  farmerAddress: string;
  variety: string;
  quantity: string;
  quality: string;
  harvestDate: string;
  certificateHash: string;
  certificateIpfsUrl: string;
  status: string;
  blockchainTxHash: string;
  createdAt: string;
}

interface AuctionState {
  auctions: Auction[];
  currentAuction: Auction | null;
  bids: Record<number, Bid[]>;
  socket: Socket | null;
  connected: boolean;
  activeUsers: Record<number, number>;
  
  // Actions
  setAuctions: (auctions: Auction[]) => void;
  setCurrentAuction: (auction: Auction | null) => void;
  addBid: (auctionId: number, bid: Bid) => void;
  setBids: (auctionId: number, bids: Bid[]) => void;
  updateAuction: (auctionId: number, updates: Partial<Auction>) => void;
  connectWebSocket: (url: string) => void;
  disconnectWebSocket: () => void;
  joinAuction: (auctionId: number, userAddress: string) => void;
  leaveAuction: (auctionId: number, userAddress: string) => void;
}

export const useAuctionStore = create<AuctionState>((set, get) => ({
  auctions: [],
  currentAuction: null,
  bids: {},
  socket: null,
  connected: false,
  activeUsers: {},

  setAuctions: (auctions) => set({ auctions }),
  
  setCurrentAuction: (auction) => set({ currentAuction: auction }),
  
  addBid: (auctionId, bid) => set((state) => ({
    bids: {
      ...state.bids,
      [auctionId]: [bid, ...(state.bids[auctionId] || [])],
    },
  })),
  
  setBids: (auctionId, bids) => set((state) => ({
    bids: {
      ...state.bids,
      [auctionId]: bids,
    },
  })),
  
  updateAuction: (auctionId, updates) => set((state) => ({
    auctions: state.auctions.map((auction) =>
      auction.auctionId === auctionId ? { ...auction, ...updates } : auction
    ),
    currentAuction:
      state.currentAuction?.auctionId === auctionId
        ? { ...state.currentAuction, ...updates }
        : state.currentAuction,
  })),

  connectWebSocket: (url) => {
    const socket = io(`${url}/auction`, {
      transports: ['websocket'],
      reconnection: true,
      reconnectionDelay: 1000,
      reconnectionAttempts: 5,
    });

    socket.on('connect', () => {
      console.log('WebSocket connected');
      set({ connected: true });
    });

    socket.on('disconnect', () => {
      console.log('WebSocket disconnected');
      set({ connected: false });
    });

    socket.on('new_bid', (data) => {
      const { auctionId, bidder, amount, timestamp, bidCount } = data;
      
      const bid: Bid = {
        id: `${auctionId}-${timestamp}`,
        auctionId,
        bidderAddress: bidder,
        amount,
        timestamp,
        blockchainTxHash: '',
      };

      get().addBid(auctionId, bid);
      get().updateAuction(auctionId, {
        currentBid: amount,
        currentBidderAddress: bidder,
        bidCount,
      });
    });

    socket.on('auction_ended', (data) => {
      const { auctionId } = data;
      get().updateAuction(auctionId, { status: 'ended' });
    });

    socket.on('auction_settled', (data) => {
      const { auctionId } = data;
      get().updateAuction(auctionId, { status: 'settled' });
    });

    socket.on('compliance_update', (data) => {
      const { auctionId, passed } = data;
      get().updateAuction(auctionId, {
        compliancePassed: passed,
        status: passed ? 'active' : 'failed_compliance',
      });
    });

    socket.on('user_joined', (data) => {
      console.log('User joined:', data);
    });

    socket.on('user_left', (data) => {
      console.log('User left:', data);
    });

    socket.on('countdown_update', (data) => {
      // Handle countdown updates
    });

    set({ socket });
  },

  disconnectWebSocket: () => {
    const { socket } = get();
    if (socket) {
      socket.disconnect();
      set({ socket: null, connected: false });
    }
  },

  joinAuction: (auctionId, userAddress) => {
    const { socket } = get();
    if (socket && socket.connected) {
      socket.emit('join_auction', { auctionId, userAddress });
    }
  },

  leaveAuction: (auctionId, userAddress) => {
    const { socket } = get();
    if (socket && socket.connected) {
      socket.emit('leave_auction', { auctionId, userAddress });
    }
  },
}));
