/**
 * Mock Database for Development
 * Provides in-memory data storage when PostgreSQL is not available
 */

const logger = require('../utils/logger');

// In-memory data store
const mockData = {
  auctions: [
    {
      id: 1,
      lot_id: 'LOT001',
      auction_id: 1,
      farmer_address: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
      start_price: '1000000000000000000', // 1 ETH
      reserve_price: '2000000000000000000', // 2 ETH
      current_bid: '1500000000000000000', // 1.5 ETH
      current_bidder: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
      start_time: new Date(Date.now() - 3600000).toISOString(), // 1 hour ago
      end_time: new Date(Date.now() + 7200000).toISOString(), // 2 hours from now
      status: 'active',
      compliance_passed: true,
      bid_count: 3,
      variety: 'Red Bell Pepper',
      quantity: 500,
      quality: 'Grade A',
      harvest_date: '2025-11-20',
      certificate_hash: '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
      created_at: new Date(Date.now() - 86400000).toISOString()
    },
    {
      id: 2,
      lot_id: 'LOT002',
      auction_id: 2,
      farmer_address: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
      start_price: '500000000000000000', // 0.5 ETH
      reserve_price: '1000000000000000000', // 1 ETH
      current_bid: '0',
      current_bidder: null,
      start_time: new Date(Date.now() + 3600000).toISOString(), // 1 hour from now
      end_time: new Date(Date.now() + 10800000).toISOString(), // 3 hours from now
      status: 'pending',
      compliance_passed: true,
      bid_count: 0,
      variety: 'Green Chili',
      quantity: 300,
      quality: 'Grade A',
      harvest_date: '2025-11-21',
      certificate_hash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
      created_at: new Date(Date.now() - 43200000).toISOString()
    },
    {
      id: 3,
      lot_id: 'LOT003',
      auction_id: 3,
      farmer_address: '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC',
      start_price: '2000000000000000000', // 2 ETH
      reserve_price: '3000000000000000000', // 3 ETH
      current_bid: '2500000000000000000', // 2.5 ETH
      current_bidder: '0x90F79bf6EB2c4f870365E785982E1f101E93b906',
      start_time: new Date(Date.now() - 7200000).toISOString(), // 2 hours ago
      end_time: new Date(Date.now() + 1800000).toISOString(), // 30 min from now
      status: 'active',
      compliance_passed: true,
      bid_count: 7,
      variety: 'Yellow Bell Pepper',
      quantity: 800,
      quality: 'Premium',
      harvest_date: '2025-11-19',
      certificate_hash: '0xfedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210',
      created_at: new Date(Date.now() - 129600000).toISOString()
    }
  ],
  bids: [
    { id: 1, auction_id: 1, bidder_address: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8', amount: '1500000000000000000', timestamp: new Date(Date.now() - 1800000).toISOString() },
    { id: 2, auction_id: 1, bidder_address: '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC', amount: '1200000000000000000', timestamp: new Date(Date.now() - 2400000).toISOString() },
    { id: 3, auction_id: 1, bidder_address: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8', amount: '1100000000000000000', timestamp: new Date(Date.now() - 3000000).toISOString() },
    { id: 4, auction_id: 3, bidder_address: '0x90F79bf6EB2c4f870365E785982E1f101E93b906', amount: '2500000000000000000', timestamp: new Date(Date.now() - 900000).toISOString() }
  ],
  users: [
    { id: 1, address: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266', role: 'farmer', name: 'Test Farmer 1', created_at: new Date().toISOString() },
    { id: 2, address: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8', role: 'buyer', name: 'Test Buyer 1', created_at: new Date().toISOString() },
    { id: 3, address: '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC', role: 'farmer', name: 'Test Farmer 2', created_at: new Date().toISOString() }
  ]
};

/**
 * Simple SQL parser for mock queries
 */
function executeMockQuery(text, params = []) {
  const sql = text.toLowerCase().trim();
  
  // SELECT queries
  if (sql.startsWith('select')) {
    // Auctions
    if (sql.includes('from auctions') || sql.includes('from lots')) {
      if (sql.includes('where')) {
        // Handle WHERE clauses
        if (sql.includes('auction_id') || sql.includes('id')) {
          const id = params[0] || parseInt(sql.match(/\d+/)?.[0]);
          const auction = mockData.auctions.find(a => a.id === id || a.auction_id === id);
          return { rows: auction ? [auction] : [] };
        }
        if (sql.includes('status')) {
          const status = params[0] || 'active';
          const filtered = mockData.auctions.filter(a => a.status === status);
          return { rows: filtered };
        }
      }
      // Return all auctions
      return { rows: mockData.auctions };
    }
    
    // Bids
    if (sql.includes('from bids')) {
      if (sql.includes('where auction_id')) {
        const auctionId = params[0];
        const filtered = mockData.bids.filter(b => b.auction_id === auctionId);
        return { rows: filtered };
      }
      return { rows: mockData.bids };
    }
    
    // Users
    if (sql.includes('from users')) {
      if (sql.includes('where address')) {
        const address = params[0];
        const user = mockData.users.find(u => u.address.toLowerCase() === address.toLowerCase());
        return { rows: user ? [user] : [] };
      }
      return { rows: mockData.users };
    }
  }
  
  // INSERT queries
  if (sql.startsWith('insert')) {
    logger.info('Mock INSERT (data not persisted):', { sql, params });
    return { rows: [{ id: Date.now() }], rowCount: 1 };
  }
  
  // UPDATE queries
  if (sql.startsWith('update')) {
    logger.info('Mock UPDATE (data not persisted):', { sql, params });
    return { rows: [], rowCount: 1 };
  }
  
  // DELETE queries
  if (sql.startsWith('delete')) {
    logger.info('Mock DELETE (data not persisted):', { sql, params });
    return { rows: [], rowCount: 1 };
  }
  
  // Default empty result
  logger.warn('Unhandled mock query:', sql);
  return { rows: [] };
}

module.exports = {
  query: async (text, params) => {
    logger.info('Mock DB Query:', { sql: text.substring(0, 100), hasParams: !!params });
    return executeMockQuery(text, params);
  },
  
  connect: async () => {
    logger.info('Mock DB: Connection successful (in-memory mode)');
    return true;
  },
  
  disconnect: async () => {
    logger.info('Mock DB: Disconnected');
    return true;
  },
  
  // Flag to indicate this is mock mode
  isMock: true,
  
  // Helper to add data (for testing)
  addAuction: (auction) => {
    mockData.auctions.push({ id: mockData.auctions.length + 1, ...auction });
  },
  
  addBid: (bid) => {
    mockData.bids.push({ id: mockData.bids.length + 1, ...bid });
  }
};
