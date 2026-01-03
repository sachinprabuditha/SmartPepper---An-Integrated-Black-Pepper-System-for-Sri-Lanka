const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { createServer } = require('http');
const { Server } = require('socket.io');
const redis = require('redis');
require('dotenv').config();

const logger = require('./utils/logger');
const db = require('./db/database');
const authRoutes = require('./routes/auth');
const auctionRoutes = require('./routes/auction');
const lotRoutes = require('./routes/lot');
const userRoutes = require('./routes/user');
const complianceRoutes = require('./routes/compliance');
const processingRoutes = require('./routes/processing');
const certificationsRoutes = require('./routes/certifications');
const adminRoutes = require('./routes/admin');
const governanceRoutes = require('./routes/governance');
const escrowRoutes = require('./routes/escrow');
const { startAuctionStatusMonitor } = require('./services/auctionStatusService');

// Load NFT routes with error handling
let nftPassportRoutes;
try {
  nftPassportRoutes = require('./routes/nftPassport');
  logger.info('NFT Passport routes loaded successfully');
} catch (err) {
  logger.error('Failed to load NFT Passport routes:', err);
  // Create a dummy router that returns errors
  const express = require('express');
  nftPassportRoutes = express.Router();
  nftPassportRoutes.all('*', (req, res) => {
    res.status(503).json({
      success: false,
      error: 'NFT Passport service not available'
    });
  });
}

const AuctionWebSocket = require('./websocket/auctionSocket');
const BlockchainService = require('./services/blockchainService');

const app = express();
const httpServer = createServer(app);

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.get('user-agent')
  });
  next();
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/auctions', auctionRoutes);
app.use('/api/lots', lotRoutes);
app.use('/api/users', userRoutes);
app.use('/api/compliance', complianceRoutes);
app.use('/api/processing', processingRoutes);
app.use('/api/certifications', certificationsRoutes);
app.use('/api/nft-passport', nftPassportRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/governance', governanceRoutes);
app.use('/api/escrow', escrowRoutes);
app.use('/api/traceability', require('./routes/traceability'));

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Error handling
app.use((err, req, res, next) => {
  logger.error('Error:', err);
  res.status(err.status || 500).json({
    error: {
      message: err.message || 'Internal server error',
      status: err.status || 500
    }
  });
});

// Initialize services
async function initialize() {
  let redisClient = null;
  let dbConnected = false;

  try {
    // Initialize database (optional for now)
    try {
      await db.connect();
      dbConnected = true;
      if (db.isMock) {
        logger.info('✅ Database: Using MOCK in-memory database (test data available)');
        logger.info('💡 To use PostgreSQL, set DB_PASSWORD in .env file');
      } else {
        logger.info('✅ Database: PostgreSQL connected');
      }
    } catch (dbError) {
      logger.warn('Database connection failed (continuing without DB):', dbError.message);
    }

    // Initialize Redis (optional for now)
    try {
      redisClient = redis.createClient({
        host: process.env.REDIS_HOST || 'localhost',
        port: process.env.REDIS_PORT || 6379
      });
      
      await redisClient.connect();
      logger.info('Redis connected');
    } catch (redisError) {
      logger.warn('Redis connection failed (continuing without Redis):', redisError.message);
      redisClient = null;
    }

    // Initialize blockchain service (optional for now)
    try {
      const blockchainService = new BlockchainService();
      await blockchainService.initialize();
      logger.info('Blockchain service initialized');
    } catch (blockchainError) {
      logger.warn('Blockchain service initialization failed (continuing without blockchain):', blockchainError.message);
    }

    // Start auction status monitor if database is connected
    if (dbConnected && !db.isMock) {
      startAuctionStatusMonitor();
      logger.info('✅ Auction status monitor started (checks every 60 seconds)');
    }

    // Initialize WebSocket
    const io = new Server(httpServer, {
      cors: {
        origin: '*',
        methods: ['GET', 'POST']
      }
    });
    
    // Make io available to routes
    app.set('io', io);
    
    if (redisClient) {
      const auctionSocket = new AuctionWebSocket(io, redisClient);
      auctionSocket.initialize();
      app.set('auctionSocket', auctionSocket); // Make available to routes
      logger.info('WebSocket server initialized');
    } else {
      logger.warn('WebSocket not initialized (Redis unavailable)');
    }

    // Start server
    const PORT = process.env.PORT || 3000;
    httpServer.listen(PORT, () => {
      logger.info(`🚀 Server running on port ${PORT}`);
      logger.info(`🌍 Environment: ${process.env.NODE_ENV}`);
      logger.info('📊 Services status:', {
        database: dbConnected ? (db.isMock ? 'MOCK (in-memory)' : 'PostgreSQL') : 'disabled',
        redis: redisClient !== null ? 'connected' : 'disabled',
        websocket: redisClient !== null ? 'enabled' : 'disabled'
      });
      logger.info('');
      logger.info('🎯 API Endpoints:');
      logger.info(`   - Health: http://localhost:${PORT}/health`);
      logger.info(`   - Auctions: http://localhost:${PORT}/api/auctions`);
      logger.info(`   - Lots: http://localhost:${PORT}/api/lots`);
      logger.info(`   - Users: http://localhost:${PORT}/api/users`);
      logger.info('');
    });

    // Graceful shutdown
    process.on('SIGTERM', async () => {
      logger.info('SIGTERM received, shutting down gracefully');
      httpServer.close();
      if (redisClient) await redisClient.quit();
      if (dbConnected) await db.disconnect();
      process.exit(0);
    });

  } catch (error) {
    logger.error('Failed to initialize server:', error);
    process.exit(1);
  }
}

initialize();

module.exports = app;
