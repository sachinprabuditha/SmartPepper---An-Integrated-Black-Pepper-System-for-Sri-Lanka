const logger = require('../utils/logger');

class AuctionWebSocket {
  constructor(io, redisClient) {
    this.io = io;
    this.redis = redisClient;
    this.auctionNamespace = io.of('/auction');
  }

  initialize() {
    this.auctionNamespace.on('connection', (socket) => {
      logger.info('WebSocket client connected', {
        socketId: socket.id,
        address: socket.handshake.address
      });

      // Join auction room
      socket.on('join_auction', async (data) => {
        try {
          const { auctionId, userAddress } = data;
          
          await socket.join(`auction_${auctionId}`);
          
          // Get current auction state from Redis
          const auctionState = await this.getAuctionState(auctionId);
          
          socket.emit('auction_joined', {
            auctionId,
            ...auctionState
          });

          // Notify others
          socket.to(`auction_${auctionId}`).emit('user_joined', {
            userAddress,
            timestamp: new Date()
          });

          logger.info('User joined auction', { auctionId, userAddress, socketId: socket.id });
        } catch (error) {
          logger.error('Error joining auction:', error);
          socket.emit('error', { message: 'Failed to join auction' });
        }
      });

      // Leave auction room
      socket.on('leave_auction', async (data) => {
        try {
          const { auctionId, userAddress } = data;
          
          await socket.leave(`auction_${auctionId}`);
          
          socket.to(`auction_${auctionId}`).emit('user_left', {
            userAddress,
            timestamp: new Date()
          });

          logger.info('User left auction', { auctionId, userAddress });
        } catch (error) {
          logger.error('Error leaving auction:', error);
        }
      });

      // Handle disconnection
      socket.on('disconnect', () => {
        logger.info('WebSocket client disconnected', { socketId: socket.id });
      });
    });

    logger.info('WebSocket server initialized on /auction namespace');
  }

  // Broadcast new bid to all clients in auction room
  async broadcastBid(auctionId, bidData) {
    try {
      // Update Redis cache
      await this.updateAuctionState(auctionId, {
        currentBid: bidData.amount,
        currentBidder: bidData.bidder,
        bidCount: bidData.bidCount,
        lastBidTime: bidData.timestamp
      });

      // Broadcast to all clients in room
      this.auctionNamespace.to(`auction_${auctionId}`).emit('new_bid', {
        auctionId,
        bidder: bidData.bidder,
        amount: bidData.amount,
        timestamp: bidData.timestamp,
        bidCount: bidData.bidCount
      });

      logger.info('Bid broadcasted', {
        auctionId,
        bidder: bidData.bidder,
        amount: bidData.amount
      });
    } catch (error) {
      logger.error('Error broadcasting bid:', error);
    }
  }

  // Broadcast auction ended
  async broadcastAuctionEnded(auctionId, winner, finalPrice) {
    try {
      await this.updateAuctionState(auctionId, {
        status: 'ended',
        winner,
        finalPrice
      });

      this.auctionNamespace.to(`auction_${auctionId}`).emit('auction_ended', {
        auctionId,
        winner,
        finalPrice,
        timestamp: new Date()
      });

      logger.info('Auction ended broadcast', { auctionId, winner, finalPrice });
    } catch (error) {
      logger.error('Error broadcasting auction end:', error);
    }
  }

  // Broadcast auction settled
  async broadcastAuctionSettled(auctionId, settlementData) {
    try {
      await this.updateAuctionState(auctionId, {
        status: 'settled',
        ...settlementData
      });

      this.auctionNamespace.to(`auction_${auctionId}`).emit('auction_settled', {
        auctionId,
        ...settlementData,
        timestamp: new Date()
      });

      logger.info('Auction settled broadcast', { auctionId });
    } catch (error) {
      logger.error('Error broadcasting settlement:', error);
    }
  }

  // Broadcast compliance status
  async broadcastComplianceStatus(auctionId, passed) {
    try {
      await this.updateAuctionState(auctionId, {
        compliancePassed: passed,
        status: passed ? 'active' : 'failed_compliance'
      });

      this.auctionNamespace.to(`auction_${auctionId}`).emit('compliance_update', {
        auctionId,
        passed,
        timestamp: new Date()
      });

      logger.info('Compliance status broadcasted', { auctionId, passed });
    } catch (error) {
      logger.error('Error broadcasting compliance:', error);
    }
  }

  // Get auction state from Redis
  async getAuctionState(auctionId) {
    try {
      const key = `auction:${auctionId}`;
      const state = await this.redis.get(key);
      
      return state ? JSON.parse(state) : {};
    } catch (error) {
      logger.error('Error getting auction state from Redis:', error);
      return {};
    }
  }

  // Update auction state in Redis
  async updateAuctionState(auctionId, updates) {
    try {
      const key = `auction:${auctionId}`;
      const currentState = await this.getAuctionState(auctionId);
      
      const newState = {
        ...currentState,
        ...updates,
        updatedAt: new Date().toISOString()
      };

      await this.redis.setEx(key, 86400, JSON.stringify(newState)); // 24 hour TTL
      
      return newState;
    } catch (error) {
      logger.error('Error updating auction state in Redis:', error);
      throw error;
    }
  }

  // Get active connections count for an auction
  getAuctionConnectionCount(auctionId) {
    const room = this.auctionNamespace.adapter.rooms.get(`auction_${auctionId}`);
    return room ? room.size : 0;
  }

  // Broadcast auction countdown
  async broadcastCountdown(auctionId, timeRemaining) {
    this.auctionNamespace.to(`auction_${auctionId}`).emit('countdown_update', {
      auctionId,
      timeRemaining,
      timestamp: new Date()
    });
  }
}

module.exports = AuctionWebSocket;
