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
    { id: 4, auction_id: 3, bidder_address: '0x90F79bf6EB2c4f870365E785982E1f101E93b906', amount: '2500000000000000000', timestamp: new Date(Date.now() - 900000).toISOString() },
    { id: 5, auction_id: 3, bidder_address: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8', amount: '2300000000000000000', timestamp: new Date(Date.now() - 1200000).toISOString() },
    { id: 6, auction_id: 3, bidder_address: '0x90F79bf6EB2c4f870365E785982E1f101E93b906', amount: '2200000000000000000', timestamp: new Date(Date.now() - 1500000).toISOString() },
    { id: 7, auction_id: 1, bidder_address: '0x90F79bf6EB2c4f870365E785982E1f101E93b906', amount: '1000000000000000000', timestamp: new Date(Date.now() - 3600000).toISOString() }
  ],
  nft_passports: [
    { id: 1, token_id: 1, owner_address: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266', lot_id: 'LOT001', variety: 'Red Bell Pepper', quantity: 500, created_at: new Date(Date.now() - 86400000).toISOString() },
    { id: 2, token_id: 2, owner_address: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266', lot_id: 'LOT002', variety: 'Green Chili', quantity: 300, created_at: new Date(Date.now() - 43200000).toISOString() },
    { id: 3, token_id: 3, owner_address: '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC', lot_id: 'LOT003', variety: 'Yellow Bell Pepper', quantity: 800, created_at: new Date(Date.now() - 129600000).toISOString() },
    { id: 4, token_id: 4, owner_address: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266', lot_id: 'LOT004', variety: 'Black Pepper', quantity: 1000, created_at: new Date(Date.now() - 259200000).toISOString() }
  ],
  users: [
    { 
      id: 1, 
      wallet_address: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266', 
      user_type: 'farmer',
      role: 'farmer',
      name: 'Rajesh Kumar', 
      email: 'rajesh.kumar@example.com',
      phone: '+94771234567',
      verified: true,
      created_at: new Date(Date.now() - 2592000000).toISOString(), // 30 days ago
      updated_at: new Date(Date.now() - 86400000).toISOString() // 1 day ago
    },
    { 
      id: 2, 
      wallet_address: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8', 
      user_type: 'exporter',
      role: 'exporter',
      name: 'Ceylon Spice Exports Ltd', 
      email: 'contact@ceylonspices.lk',
      phone: '+94112345678',
      verified: true,
      created_at: new Date(Date.now() - 2160000000).toISOString(), // 25 days ago
      updated_at: new Date(Date.now() - 172800000).toISOString() // 2 days ago
    },
    { 
      id: 3, 
      wallet_address: '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC', 
      user_type: 'farmer',
      role: 'farmer',
      name: 'Priya Fernando', 
      email: 'priya.fernando@example.com',
      phone: '+94777654321',
      verified: false,
      created_at: new Date(Date.now() - 1296000000).toISOString(), // 15 days ago
      updated_at: new Date(Date.now() - 259200000).toISOString() // 3 days ago
    },
    { 
      id: 4, 
      wallet_address: '0x90F79bf6EB2c4f870365E785982E1f101E93b906', 
      user_type: 'exporter',
      role: 'exporter',
      name: 'Global Pepper Trading', 
      email: 'info@globalpepper.com',
      phone: '+94115678901',
      verified: true,
      created_at: new Date(Date.now() - 864000000).toISOString(), // 10 days ago
      updated_at: new Date(Date.now() - 432000000).toISOString() // 5 days ago
    },
    { 
      id: 5, 
      wallet_address: '0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65', 
      user_type: 'admin',
      role: 'admin',
      name: 'Admin User', 
      email: 'admin@smartpepper.lk',
      phone: '+94112223333',
      verified: true,
      created_at: new Date(Date.now() - 5184000000).toISOString(), // 60 days ago
      updated_at: new Date(Date.now() - 3600000).toISOString() // 1 hour ago
    }
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
      if (sql.includes('where wallet_address')) {
        const address = params[0];
        const user = mockData.users.find(u => 
          u.wallet_address && u.wallet_address.toLowerCase() === address.toLowerCase()
        );
        return { rows: user ? [user] : [] };
      }
      if (sql.includes('where id')) {
        const id = params[0];
        const user = mockData.users.find(u => u.id.toString() === id.toString());
        if (user) {
          // Transform field names for consistency
          const transformedUser = {
            ...user,
            walletAddress: user.wallet_address,
            createdAt: user.created_at,
            updatedAt: user.updated_at
          };
          return { rows: [transformedUser] };
        }
        return { rows: [] };
      }
      // Return all users with proper field mapping
      const users = mockData.users.map(u => ({
        id: u.id,
        walletAddress: u.wallet_address,
        role: u.user_type || u.role,
        name: u.name,
        email: u.email,
        phone: u.phone,
        verified: u.verified,
        createdAt: u.created_at,
        updatedAt: u.updated_at
      }));
      return { rows: users };
    }
    
    // NFT Passports
    if (sql.includes('from nft_passports')) {
      if (sql.includes('where owner_address')) {
        const address = params[0];
        const count = mockData.nft_passports.filter(p => 
          p.owner_address && p.owner_address.toLowerCase() === address.toLowerCase()
        ).length;
        return { rows: [{ count }] };
      }
      return { rows: mockData.nft_passports };
    }
    
    // Count queries
    if (sql.includes('count(*)')) {
      if (sql.includes('from auctions')) {
        if (sql.includes('where farmer_address')) {
          const address = params[0];
          const count = mockData.auctions.filter(a => 
            a.farmer_address && a.farmer_address.toLowerCase() === address.toLowerCase()
          ).length;
          return { rows: [{ count }] };
        }
        return { rows: [{ count: mockData.auctions.length }] };
      }
      if (sql.includes('from bids')) {
        if (sql.includes('where bidder_address')) {
          const address = params[0];
          const count = mockData.bids.filter(b => 
            b.bidder_address && b.bidder_address.toLowerCase() === address.toLowerCase()
          ).length;
          return { rows: [{ count }] };
        }
        return { rows: [{ count: mockData.bids.length }] };
      }
      if (sql.includes('from nft_passports')) {
        if (sql.includes('where owner_address')) {
          const address = params[0];
          const count = mockData.nft_passports.filter(p => 
            p.owner_address && p.owner_address.toLowerCase() === address.toLowerCase()
          ).length;
          return { rows: [{ count }] };
        }
        return { rows: [{ count: mockData.nft_passports.length }] };
      }
      if (sql.includes('from users')) {
        return { rows: [{ count: mockData.users.length }] };
      }
    }
  }
  
  // INSERT queries
  if (sql.startsWith('insert')) {
    logger.info('Mock INSERT (data not persisted):', { sql, params });
    return { rows: [{ id: Date.now() }], rowCount: 1 };
  }
  
  // UPDATE queries
  if (sql.startsWith('update')) {
    if (sql.includes('update users')) {
      const id = params[params.length - 1];
      const userIndex = mockData.users.findIndex(u => u.id.toString() === id.toString());
      
      if (userIndex !== -1) {
        const user = mockData.users[userIndex];
        let paramIndex = 0;
        if (sql.includes('name =') && params[paramIndex] !== undefined) user.name = params[paramIndex++];
        if (sql.includes('email =') && params[paramIndex] !== undefined) user.email = params[paramIndex++];
        if (sql.includes('phone =') && params[paramIndex] !== undefined) user.phone = params[paramIndex++];
        if (sql.includes('user_type =') && params[paramIndex] !== undefined) {
          user.user_type = params[paramIndex];
          user.role = params[paramIndex];
          paramIndex++;
        }
        if (sql.includes('verified =') && params[paramIndex] !== undefined) user.verified = params[paramIndex++];
        user.updated_at = new Date().toISOString();
        
        logger.info('Mock UPDATE (data persisted in memory):', { id, user });
        return { rows: [user], rowCount: 1 };
      }
      return { rows: [], rowCount: 0 };
    }
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
