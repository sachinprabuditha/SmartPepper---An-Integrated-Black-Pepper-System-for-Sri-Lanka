/**
 * Smart Contract Gas Cost Analysis
 * 
 * Measures gas consumption for critical contract operations:
 * 1. createLot - Minting NFT passport
 * 2. createAuction - Starting auction
 * 3. placeBid - Placing bids
 * 4. settleAuction - Settlement & NFT transfer
 * 
 * Calculates estimated costs in ETH at various gas prices
 */

const { ethers } = require('hardhat');

// Gas price scenarios (in gwei)
const GAS_PRICES = {
  low: 20,      // Low network usage
  medium: 50,   // Average
  high: 100,    // High network usage
  extreme: 200  // Network congestion
};

const metrics = {
  operations: [],
  totalGas: 0
};

/**
 * Format gas cost in ETH
 */
function formatCost(gasUsed, gasPriceGwei) {
  const costWei = gasUsed * gasPriceGwei * 1e9;
  const costEth = ethers.formatEther(costWei);
  return parseFloat(costEth).toFixed(6);
}

/**
 * Print gas costs for an operation
 */
function printGasCosts(operation, gasUsed) {
  console.log(`\n${operation}:`);
  console.log(`   Gas Used:     ${gasUsed.toLocaleString()}`);
  console.log(`   Costs (ETH):`);
  
  Object.entries(GAS_PRICES).forEach(([scenario, gwei]) => {
    const cost = formatCost(gasUsed, gwei);
    console.log(`     ${scenario.padEnd(8)} (${gwei} gwei): ${cost} ETH`);
  });
  
  metrics.operations.push({
    operation,
    gasUsed: gasUsed.toString(),
    costs: Object.entries(GAS_PRICES).reduce((acc, [scenario, gwei]) => {
      acc[scenario] = formatCost(gasUsed, gwei);
      return acc;
    }, {})
  });
  
  metrics.totalGas += Number(gasUsed);
}

/**
 * Test createLot operation
 */
async function testCreateLot(contract, signer) {
  console.log('\n📦 Testing createLot()...');
  
  const lotId = `LOT-${Date.now()}`;
  const variety = 'Black Pepper';
  const quantity = 500;
  const quality = 'Premium';
  const harvestDate = '2025-12-01';
  const certificateHash = ethers.keccak256(ethers.toUtf8Bytes('test-cert'));
  const origin = 'Kerala, India';
  const metadataURI = 'ipfs://QmTest123';
  
  // Estimate gas
  const estimatedGas = await contract.createLot.estimateGas(
    lotId,
    variety,
    quantity,
    quality,
    harvestDate,
    certificateHash,
    origin,
    metadataURI
  );
  
  // Execute transaction
  const tx = await contract.createLot(
    lotId,
    variety,
    quantity,
    quality,
    harvestDate,
    certificateHash,
    origin,
    metadataURI
  );
  
  const receipt = await tx.wait();
  const actualGas = receipt.gasUsed;
  
  console.log(`   Estimated:    ${estimatedGas.toLocaleString()}`);
  console.log(`   Actual:       ${actualGas.toLocaleString()}`);
  console.log(`   Difference:   ${(Number(actualGas) - Number(estimatedGas)).toLocaleString()}`);
  
  printGasCosts('createLot', actualGas);
  
  return lotId;
}

/**
 * Test createAuction operation
 */
async function testCreateAuction(contract, lotId) {
  console.log('\n🔨 Testing createAuction()...');
  
  const startPrice = ethers.parseEther('1.0');
  const reservePrice = ethers.parseEther('0.8');
  const duration = 3600; // 1 hour
  
  // Estimate gas
  const estimatedGas = await contract.createAuction.estimateGas(
    lotId,
    startPrice,
    reservePrice,
    duration,
    true // compliance passed
  );
  
  // Execute transaction
  const tx = await contract.createAuction(
    lotId,
    startPrice,
    reservePrice,
    duration,
    true
  );
  
  const receipt = await tx.wait();
  const actualGas = receipt.gasUsed;
  
  console.log(`   Estimated:    ${estimatedGas.toLocaleString()}`);
  console.log(`   Actual:       ${actualGas.toLocaleString()}`);
  
  printGasCosts('createAuction', actualGas);
  
  // Get auction ID from event
  const event = receipt.logs.find(log => {
    try {
      return contract.interface.parseLog(log)?.name === 'AuctionCreated';
    } catch {
      return false;
    }
  });
  
  const auctionId = event ? contract.interface.parseLog(event).args[0] : 0;
  return auctionId;
}

/**
 * Test placeBid operation
 */
async function testPlaceBid(contract, auctionId, bidder) {
  console.log('\n💰 Testing placeBid()...');
  
  const bidAmount = ethers.parseEther('1.5');
  
  // Estimate gas
  const estimatedGas = await contract.connect(bidder).placeBid.estimateGas(
    auctionId,
    { value: bidAmount }
  );
  
  // Execute transaction
  const tx = await contract.connect(bidder).placeBid(
    auctionId,
    { value: bidAmount }
  );
  
  const receipt = await tx.wait();
  const actualGas = receipt.gasUsed;
  
  console.log(`   Estimated:    ${estimatedGas.toLocaleString()}`);
  console.log(`   Actual:       ${actualGas.toLocaleString()}`);
  
  printGasCosts('placeBid (first)', actualGas);
  
  // Test second bid (refund previous bidder)
  const bidder2 = (await ethers.getSigners())[2];
  const bidAmount2 = ethers.parseEther('1.8');
  
  const tx2 = await contract.connect(bidder2).placeBid(
    auctionId,
    { value: bidAmount2 }
  );
  
  const receipt2 = await tx2.wait();
  const actualGas2 = receipt2.gasUsed;
  
  console.log(`\n   Second bid (with refund):`);
  console.log(`   Actual:       ${actualGas2.toLocaleString()}`);
  
  printGasCosts('placeBid (refund)', actualGas2);
}

/**
 * Test endAuction operation
 */
async function testEndAuction(contract, auctionId) {
  console.log('\n🏁 Testing endAuction()...');
  
  // Fast-forward time (Hardhat only)
  await ethers.provider.send('evm_increaseTime', [3601]);
  await ethers.provider.send('evm_mine');
  
  // Estimate gas
  const estimatedGas = await contract.endAuction.estimateGas(auctionId);
  
  // Execute transaction
  const tx = await contract.endAuction(auctionId);
  const receipt = await tx.wait();
  const actualGas = receipt.gasUsed;
  
  console.log(`   Estimated:    ${estimatedGas.toLocaleString()}`);
  console.log(`   Actual:       ${actualGas.toLocaleString()}`);
  
  printGasCosts('endAuction', actualGas);
}

/**
 * Test settleAuction operation
 */
async function testSettleAuction(contract, auctionId) {
  console.log('\n✅ Testing settleAuction()...');
  
  // Estimate gas
  const estimatedGas = await contract.settleAuction.estimateGas(auctionId);
  
  // Execute transaction
  const tx = await contract.settleAuction(auctionId);
  const receipt = await tx.wait();
  const actualGas = receipt.gasUsed;
  
  console.log(`   Estimated:    ${estimatedGas.toLocaleString()}`);
  console.log(`   Actual:       ${actualGas.toLocaleString()}`);
  
  printGasCosts('settleAuction', actualGas);
}

/**
 * Print summary
 */
function printSummary() {
  console.log('\n' + '='.repeat(60));
  console.log('📊 GAS COST SUMMARY');
  console.log('='.repeat(60));
  
  console.log(`\n⛽ Total Gas Used: ${metrics.totalGas.toLocaleString()}`);
  
  console.log('\n💵 Total Cost for Full Workflow:');
  Object.entries(GAS_PRICES).forEach(([scenario, gwei]) => {
    const cost = formatCost(metrics.totalGas, gwei);
    console.log(`   ${scenario.padEnd(8)} (${gwei.toString().padStart(3)} gwei): ${cost} ETH`);
  });
  
  console.log('\n📋 Operation Breakdown:');
  metrics.operations.forEach(op => {
    console.log(`\n   ${op.operation}:`);
    console.log(`     Gas: ${Number(op.gasUsed).toLocaleString()}`);
    console.log(`     % of Total: ${((Number(op.gasUsed) / metrics.totalGas) * 100).toFixed(1)}%`);
  });
  
  console.log('\n' + '='.repeat(60));
}

/**
 * Main test execution
 */
async function runGasTests() {
  console.log('⛽ Starting Smart Contract Gas Cost Analysis\n');
  
  try {
    // Get contract factory
    const PepperAuction = await ethers.getContractFactory('PepperAuction');
    
    // Deploy fresh contract
    console.log('📝 Deploying PepperAuction contract...');
    const contract = await PepperAuction.deploy();
    await contract.waitForDeployment();
    console.log(`✅ Contract deployed at: ${await contract.getAddress()}`);
    
    // Get signers
    const [owner, bidder1, bidder2] = await ethers.getSigners();
    console.log(`\n👤 Test accounts:`);
    console.log(`   Owner:   ${owner.address}`);
    console.log(`   Bidder1: ${bidder1.address}`);
    console.log(`   Bidder2: ${bidder2.address}`);
    
    // Test each operation
    const lotId = await testCreateLot(contract, owner);
    const auctionId = await testCreateAuction(contract, lotId);
    await testPlaceBid(contract, auctionId, bidder1);
    await testEndAuction(contract, auctionId);
    await testSettleAuction(contract, auctionId);
    
    // Print summary
    printSummary();
    
    // Save results to file
    const fs = require('fs');
    const path = require('path');
    
    const resultsPath = path.join(__dirname, '../../logs/gas-analysis-results.json');
    fs.mkdirSync(path.dirname(resultsPath), { recursive: true });
    fs.writeFileSync(
      resultsPath,
      JSON.stringify({
        timestamp: new Date().toISOString(),
        totalGas: metrics.totalGas,
        operations: metrics.operations,
        gasPrices: GAS_PRICES
      }, null, 2)
    );
    
    console.log(`\n💾 Results saved to: ${resultsPath}`);
    
  } catch (error) {
    console.error('\n❌ Gas analysis failed:', error);
    process.exit(1);
  }
}

// Run if executed directly
if (require.main === module) {
  runGasTests()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
}

module.exports = { runGasTests };
