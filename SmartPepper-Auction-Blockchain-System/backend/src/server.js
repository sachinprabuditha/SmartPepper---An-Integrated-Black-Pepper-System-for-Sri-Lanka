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
const notificationsRoutes = require('./routes/notifications');
const qualityGradingRoutes = require('./routes/qualityGrading');
const pepperVarietiesRoutes = require('./routes/pepperVarieties');
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
app.use('/api/notifications', notificationsRoutes);
app.use('/api/compliance', complianceRoutes);
app.use('/api/processing', processingRoutes);
app.use('/api/certifications', certificationsRoutes);
app.use('/api/nft-passport', nftPassportRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/governance', governanceRoutes);
app.use('/api/escrow', escrowRoutes);
app.use('/api/traceability', require('./routes/traceability'));
app.use('/api/quality-grading', qualityGradingRoutes);
app.use('/api/pepper-varieties', pepperVarietiesRoutes);

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
        logger.info('💡 To use Firebase, set FIREBASE_PROJECT_ID or FIREBASE_SERVICE_ACCOUNT in .env file');
      } else if (db.isFirebase) {
        logger.info('✅ Database: Firebase Firestore connected');
      } else {
        logger.info('✅ Database: Connected');
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
      logger.info('✅ Redis connected - Real-time WebSocket features enabled');
    } catch (redisError) {
      logger.info('ℹ️  Redis not configured - WebSocket real-time updates disabled (optional)');
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

    // Initialize Exchange Rate Service (real-time rates from CoinGecko API)
    try {
      const exchangeRateService = require('./services/exchangeRateService');
      const currencyConverter = require('./utils/currencyConverter');
      
      await exchangeRateService.initialize();
      currencyConverter.setExchangeRateService(exchangeRateService);
      
      logger.info('✅ Exchange Rate Service initialized (CoinGecko API)');
      
      const status = exchangeRateService.getStatus();
      logger.info('💱 Live exchange rates:', {
        ethToUsd: status.rates.ethToUsd,
        ethToLkr: status.rates.ethToLkr,
        updateInterval: status.updateInterval
      });
    } catch (exchangeRateError) {
      logger.warn('⚠️ Exchange Rate Service initialization failed (using fallback rates):', exchangeRateError.message);
    }

    // Initialize auction finalization service
    try {
      const auctionFinalizationService = require('./services/auctionFinalizationService');
      await auctionFinalizationService.initialize();
      logger.info('✅ Auction Finalization Service initialized');
    } catch (finalizationError) {
      logger.warn('⚠️ Auction Finalization Service initialization failed:', finalizationError.message);
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

    // Make io available to routes and services
    app.set('io', io);
    global.io = io; // Make available to finalization service

    // Initialize WebSocket (works with or without Redis)
    const auctionSocket = new AuctionWebSocket(io, redisClient);
    auctionSocket.initialize();
    app.set('auctionSocket', auctionSocket); // Make available to routes

    if (redisClient) {
      logger.info('✅ WebSocket server initialized with Redis caching');
    } else {
      logger.info('✅ WebSocket server initialized (without Redis caching)');
      logger.info('💡 For Redis caching, set REDIS_HOST and REDIS_PORT in .env');
    }

    // Start server
    const PORT = process.env.PORT || 3000;
    httpServer.listen(PORT, () => {
      logger.info(`🚀 Server running on port ${PORT}`);
      logger.info(`🌍 Environment: ${process.env.NODE_ENV}`);
      logger.info('📊 Services status:', {
        database: dbConnected ? (db.isMock ? 'MOCK (in-memory)' : (db.isFirebase ? 'Firebase Firestore' : 'Connected')) : 'disabled',
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
