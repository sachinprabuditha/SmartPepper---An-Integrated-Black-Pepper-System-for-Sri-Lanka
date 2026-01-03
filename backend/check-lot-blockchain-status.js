const { ethers } = require('ethers');

const AUCTION_ADDRESS = '0x70e0bA845a1A0F2DA3359C97E0285013525FFC49';
const RPC_URL = 'http://127.0.0.1:8545';

const ABI = [
  "function lots(string) view returns (string lotId, address farmer, string variety, uint256 quantity, string quality, string harvestDate, bytes32 certificateHash, uint8 status, uint256 createdAt)",
  "function lotExists(string) view returns (bool)"
];

async function checkLotStatus() {
  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const contract = new ethers.Contract(AUCTION_ADDRESS, ABI, provider);
  
  const lotId = 'LOT-1767472240326';
  
  try {
    console.log(`\n🔍 Checking lot status on blockchain: ${lotId}\n`);
    
    // Check if lot exists
    const exists = await contract.lotExists(lotId);
    console.log(`Lot exists: ${exists}`);
    
    if (exists) {
      // Get lot details
      const lot = await contract.lots(lotId);
      console.log(`\nLot Details:`);
      console.log(`  Lot ID: ${lot.lotId}`);
      console.log(`  Farmer: ${lot.farmer}`);
      console.log(`  Variety: ${lot.variety}`);
      console.log(`  Quantity: ${lot.quantity.toString()}`);
      console.log(`  Quality: ${lot.quality}`);
      console.log(`  Harvest Date: ${lot.harvestDate}`);
      console.log(`  Status: ${lot.status} (0=Available, 1=InAuction, 2=Sold, 3=Cancelled)`);
      console.log(`  Created At: ${new Date(Number(lot.createdAt) * 1000).toLocaleString()}`);
      
      if (lot.status === 0n) {
        console.log(`\n✅ Lot is Available for auction`);
      } else if (lot.status === 1n) {
        console.log(`\n❌ Lot is already InAuction - cannot create another auction`);
        console.log(`   This happened because a previous auction creation changed the status`);
        console.log(`   even though the database insert failed.`);
      }
    } else {
      console.log(`\n❌ Lot does not exist on blockchain`);
    }
    
  } catch (error) {
    console.error('Error:', error.message);
  }
}

checkLotStatus();
