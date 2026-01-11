/**
 * Auction Latency Performance Tests
 * 
 * Research Requirement: Bid updates must propagate in <300ms
 * 
 * This test suite validates WebSocket real-time performance by:
 * 1. Simulating multiple concurrent auction participants
 * 2. Measuring time from bid placement to update reception
 * 3. Calculating p50, p95, p99 latencies and max latency
 * 4. Ensuring 95th percentile stays below 300ms threshold
 */

const io = require('socket.io-client');
const { performance } = require('perf_hooks');

// Configuration
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3002';
const TEST_AUCTION_ID = 1;
const NUM_PARTICIPANTS = 10;
const NUM_BIDS_PER_PARTICIPANT = 5;
const LATENCY_THRESHOLD_MS = 300;

// Metrics storage
const metrics = {
  auction_latency_ms: [],
  connection_times_ms: [],
  errors: [],
  disconnections: 0
};

/**
 * Calculate percentile from sorted array
 */
function percentile(arr, p) {
  if (arr.length === 0) return 0;
  const sorted = [...arr].sort((a, b) => a - b);
  const index = Math.ceil((p / 100) * sorted.length) - 1;
  return sorted[Math.max(0, index)];
}

/**
 * Calculate statistics from latency measurements
 */
function calculateStats(latencies) {
  if (latencies.length === 0) {
    return {
      count: 0,
      min: 0,
      max: 0,
      avg: 0,
      median: 0,
      p95: 0,
      p99: 0
    };
  }

  const sum = latencies.reduce((a, b) => a + b, 0);
  
  return {
    count: latencies.length,
    min: Math.min(...latencies),
    max: Math.max(...latencies),
    avg: sum / latencies.length,
    median: percentile(latencies, 50),
    p95: percentile(latencies, 95),
    p99: percentile(latencies, 99)
  };
}

/**
 * Create a WebSocket client that joins an auction
 */
function createAuctionClient(clientId) {
  return new Promise((resolve, reject) => {
    const connectStart = performance.now();
    
    const socket = io(`${BACKEND_URL}/auction`, {
      transports: ['websocket'],
      reconnection: true,
      reconnectionDelay: 500,
      reconnectionAttempts: 3,
      timeout: 5000
    });

    socket.on('connect', () => {
      const connectTime = performance.now() - connectStart;
      metrics.connection_times_ms.push(connectTime);
      
      console.log(`✓ Client ${clientId} connected in ${connectTime.toFixed(2)}ms`);
      
      // Join auction room
      socket.emit('join_auction', {
        auctionId: TEST_AUCTION_ID,
        userAddress: `0xTest${clientId.toString().padStart(40, '0')}`
      });
      
      resolve(socket);
    });

    socket.on('auction_joined', (data) => {
      console.log(`✓ Client ${clientId} joined auction ${TEST_AUCTION_ID}`);
    });

    socket.on('connect_error', (error) => {
      metrics.errors.push({
        clientId,
        type: 'connection_error',
        message: error.message
      });
      reject(error);
    });

    socket.on('disconnect', (reason) => {
      metrics.disconnections++;
      console.log(`⚠ Client ${clientId} disconnected: ${reason}`);
    });

    // Timeout after 10 seconds
    setTimeout(() => {
      if (!socket.connected) {
        reject(new Error(`Client ${clientId} connection timeout`));
      }
    }, 10000);
  });
}

/**
 * Test bid propagation latency
 */
async function testBidLatency(clients) {
  console.log('\n📊 Testing bid propagation latency...\n');

  for (let bidRound = 0; bidRound < NUM_BIDS_PER_PARTICIPANT; bidRound++) {
    const bidder = clients[bidRound % clients.length];
    const listeners = clients.filter(c => c !== bidder);

    // Prepare listeners
    const latencyPromises = listeners.map(listener => {
      return new Promise((resolve) => {
        const startTime = performance.now();
        
        listener.once('new_bid', (data) => {
          const latency = performance.now() - startTime;
          metrics.auction_latency_ms.push(latency);
          resolve(latency);
        });
      });
    });

    // Place bid
    const bidAmount = (1.0 + bidRound * 0.1).toFixed(2);
    const bidData = {
      auctionId: TEST_AUCTION_ID,
      amount: bidAmount,
      bidder: `0xBidder${bidRound}`,
      timestamp: Date.now(),
      bidCount: bidRound + 1
    };

    console.log(`🔨 Bid #${bidRound + 1}: ${bidAmount} ETH`);
    
    // Simulate backend broadcasting bid
    bidder.emit('place_bid', bidData);

    // Wait for all listeners to receive update
    const latencies = await Promise.all(latencyPromises);
    
    const avgLatency = latencies.reduce((a, b) => a + b, 0) / latencies.length;
    const maxLatency = Math.max(...latencies);
    
    console.log(`   ⏱  Avg: ${avgLatency.toFixed(2)}ms | Max: ${maxLatency.toFixed(2)}ms`);
    
    // Wait a bit before next bid
    await new Promise(resolve => setTimeout(resolve, 100));
  }
}

/**
 * Test concurrent bid storm (stress test)
 */
async function testConcurrentBids(clients) {
  console.log('\n🌪️  Testing concurrent bid storm...\n');

  const stormSize = 20;
  const bidPromises = [];

  for (let i = 0; i < stormSize; i++) {
    const bidder = clients[i % clients.length];
    const listeners = clients.filter(c => c !== bidder);

    const bidPromise = new Promise((resolve) => {
      const latencies = [];
      let receivedCount = 0;

      listeners.forEach(listener => {
        const startTime = performance.now();
        
        listener.once(`storm_bid_${i}`, (data) => {
          const latency = performance.now() - startTime;
          latencies.push(latency);
          metrics.auction_latency_ms.push(latency);
          receivedCount++;

          if (receivedCount === listeners.length) {
            resolve(latencies);
          }
        });
      });

      // Place bid after small delay
      setTimeout(() => {
        bidder.emit('place_bid', {
          auctionId: TEST_AUCTION_ID,
          amount: (2.0 + i * 0.01).toFixed(2),
          bidder: `0xStorm${i}`,
          timestamp: Date.now(),
          eventId: `storm_bid_${i}`
        });
      }, i * 10); // Stagger bids by 10ms
    });

    bidPromises.push(bidPromise);
  }

  await Promise.all(bidPromises);
  console.log(`✓ Completed ${stormSize} concurrent bids`);
}

/**
 * Print test results
 */
function printResults() {
  console.log('\n' + '='.repeat(60));
  console.log('📈 PERFORMANCE TEST RESULTS');
  console.log('='.repeat(60));

  // Connection metrics
  const connStats = calculateStats(metrics.connection_times_ms);
  console.log('\n🔌 Connection Performance:');
  console.log(`   Count:      ${connStats.count}`);
  console.log(`   Average:    ${connStats.avg.toFixed(2)}ms`);
  console.log(`   Min:        ${connStats.min.toFixed(2)}ms`);
  console.log(`   Max:        ${connStats.max.toFixed(2)}ms`);

  // Latency metrics
  const latencyStats = calculateStats(metrics.auction_latency_ms);
  console.log('\n⚡ Bid Propagation Latency:');
  console.log(`   Measurements: ${latencyStats.count}`);
  console.log(`   Average:      ${latencyStats.avg.toFixed(2)}ms`);
  console.log(`   Median (p50): ${latencyStats.median.toFixed(2)}ms`);
  console.log(`   p95:          ${latencyStats.p95.toFixed(2)}ms`);
  console.log(`   p99:          ${latencyStats.p99.toFixed(2)}ms`);
  console.log(`   Max:          ${latencyStats.max.toFixed(2)}ms`);

  // Threshold validation
  const passed = latencyStats.p95 < LATENCY_THRESHOLD_MS;
  console.log('\n🎯 Requirement Validation:');
  console.log(`   Threshold:    ${LATENCY_THRESHOLD_MS}ms (p95)`);
  console.log(`   Actual:       ${latencyStats.p95.toFixed(2)}ms`);
  console.log(`   Status:       ${passed ? '✅ PASSED' : '❌ FAILED'}`);

  // Error summary
  if (metrics.errors.length > 0) {
    console.log('\n⚠️  Errors:');
    metrics.errors.forEach(err => {
      console.log(`   - Client ${err.clientId}: ${err.type} - ${err.message}`);
    });
  }

  if (metrics.disconnections > 0) {
    console.log(`\n⚠️  Disconnections: ${metrics.disconnections}`);
  }

  console.log('\n' + '='.repeat(60));

  return passed;
}

/**
 * Main test execution
 */
async function runTests() {
  console.log('🚀 Starting Auction Latency Performance Tests\n');
  console.log(`Configuration:`);
  console.log(`   Backend:      ${BACKEND_URL}`);
  console.log(`   Auction ID:   ${TEST_AUCTION_ID}`);
  console.log(`   Participants: ${NUM_PARTICIPANTS}`);
  console.log(`   Bids/Client:  ${NUM_BIDS_PER_PARTICIPANT}`);
  console.log(`   Threshold:    ${LATENCY_THRESHOLD_MS}ms\n`);

  let clients = [];

  try {
    // Step 1: Connect all clients
    console.log(`📡 Connecting ${NUM_PARTICIPANTS} participants...\n`);
    
    const connectionPromises = [];
    for (let i = 0; i < NUM_PARTICIPANTS; i++) {
      connectionPromises.push(createAuctionClient(i + 1));
    }
    
    clients = await Promise.all(connectionPromises);
    console.log(`\n✅ All ${clients.length} clients connected\n`);

    // Step 2: Test sequential bid latency
    await testBidLatency(clients);

    // Step 3: Test concurrent bid storm
    await testConcurrentBids(clients);

    // Step 4: Print results
    const passed = printResults();

    // Clean up
    console.log('\n🧹 Cleaning up...');
    clients.forEach(socket => socket.close());

    process.exit(passed ? 0 : 1);

  } catch (error) {
    console.error('\n❌ Test failed:', error);
    
    // Clean up on error
    clients.forEach(socket => {
      if (socket) socket.close();
    });

    process.exit(1);
  }
}

// Run tests if executed directly
if (require.main === module) {
  runTests();
}

module.exports = { runTests, calculateStats, percentile };
