const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { createServer } = require('http');
const { Server } = require('socket.io');
const redis = require('redis');
require('dotenv').config();

const logger = require('./utils/logger');
const db = require('./db/database');
const auctionRoutes = require('./routes/auction');
const lotRoutes = require('./routes/lot');
const userRoutes = require('./routes/user');
const complianceRoutes = require('./routes/compliance');
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
app.use('/api/auctions', auctionRoutes);
app.use('/api/lots', lotRoutes);
app.use('/api/users', userRoutes);
app.use('/api/compliance', complianceRoutes);

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
  try {
    // Initialize database
    await db.connect();
    logger.info('Database connected');

    // Initialize Redis
    const redisClient = redis.createClient({
      host: process.env.REDIS_HOST || 'localhost',
      port: process.env.REDIS_PORT || 6379
    });
    
    await redisClient.connect();
    logger.info('Redis connected');

    // Initialize blockchain service
    const blockchainService = new BlockchainService();
    await blockchainService.initialize();
    logger.info('Blockchain service initialized');

    // Initialize WebSocket
    const io = new Server(httpServer, {
      cors: {
        origin: '*',
        methods: ['GET', 'POST']
      }
    });
    
    const auctionSocket = new AuctionWebSocket(io, redisClient);
    auctionSocket.initialize();
    logger.info('WebSocket server initialized');

    // Start server
    const PORT = process.env.PORT || 3000;
    httpServer.listen(PORT, () => {
      logger.info(`Server running on port ${PORT}`);
      logger.info(`Environment: ${process.env.NODE_ENV}`);
    });

    // Graceful shutdown
    process.on('SIGTERM', async () => {
      logger.info('SIGTERM received, shutting down gracefully');
      httpServer.close();
      await redisClient.quit();
      await db.disconnect();
      process.exit(0);
    });

  } catch (error) {
    logger.error('Failed to initialize server:', error);
    process.exit(1);
  }
}

initialize();

module.exports = app;
