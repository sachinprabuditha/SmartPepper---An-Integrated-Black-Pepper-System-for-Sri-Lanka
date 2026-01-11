const hre = require("hardhat");

async function main() {
  console.log("🚀 Deploying SmartPepper Contracts...\n");

  // Get deployer account
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", hre.ethers.formatEther(balance), "ETH\n");

  // 1. Deploy PepperPassport (NFT) contract
  console.log("1️⃣ Deploying PepperPassport contract...");
  const PepperPassport = await hre.ethers.getContractFactory("PepperPassport");
  const pepperPassport = await PepperPassport.deploy();
  await pepperPassport.waitForDeployment();
  const passportAddress = await pepperPassport.getAddress();
  console.log("✅ PepperPassport deployed to:", passportAddress, "\n");

  // 2. Deploy PepperAuction contract
  console.log("2️⃣ Deploying PepperAuction contract...");
  const PepperAuction = await hre.ethers.getContractFactory("PepperAuction");
  const pepperAuction = await PepperAuction.deploy();
  await pepperAuction.waitForDeployment();
  const auctionAddress = await pepperAuction.getAddress();
  console.log("✅ PepperAuction deployed to:", auctionAddress, "\n");

  // 3. Link contracts
  console.log("3️⃣ Linking PepperPassport to PepperAuction...");
  const linkTx = await pepperAuction.setPassportContract(passportAddress);
  await linkTx.wait();
  console.log("✅ Contracts linked successfully\n");

  // 4. Transfer ownership of PepperPassport to PepperAuction
  // This allows PepperAuction.createLot() to call mintPassport() internally
  console.log("4️⃣ Transferring PepperPassport ownership to PepperAuction...");
  const transferTx = await pepperPassport.transferOwnership(auctionAddress);
  await transferTx.wait();
  console.log("✅ PepperPassport ownership transferred to PepperAuction");
  console.log("   New Owner:", auctionAddress, "\n");

  // Save deployment info
  const deploymentInfo = {
    network: hre.network.name,
    contracts: {
      pepperAuction: auctionAddress,
      pepperPassport: passportAddress
    },
    deployer: deployer.address,
    deployedAt: new Date().toISOString(),
    blockNumber: await hre.ethers.provider.getBlockNumber()
  };

  console.log("=== 📄 Deployment Info ===");
  console.log(JSON.stringify(deploymentInfo, null, 2));

  // Verify initial contract state
  const totalAuctions = await pepperAuction.getTotalAuctions();
  const platformFee = await pepperAuction.platformFeePercent();
  const minBidIncrement = await pepperAuction.minBidIncrement();
  const totalPassports = await pepperPassport.totalSupply();

  console.log("\n=== 🔍 Contract State ===");
  console.log("PepperAuction:");
  console.log("  Total Auctions:", totalAuctions.toString());
  console.log("  Platform Fee:", platformFee.toString(), "%");
  console.log("  Min Bid Increment:", minBidIncrement.toString(), "wei");
  console.log("\nPepperPassport:");
  console.log("  Total NFTs Minted:", totalPassports.toString());

  console.log("\n✅ Deployment completed successfully!");
  console.log("\n📝 Update your .env files with:");
  console.log("Backend (.env):");
  console.log(`CONTRACT_ADDRESS=${auctionAddress}`);
  console.log(`PASSPORT_CONTRACT_ADDRESS=${passportAddress}`);
  console.log("\nFrontend (.env.local):");
  console.log(`NEXT_PUBLIC_CONTRACT_ADDRESS=${auctionAddress}`);
  console.log(`NEXT_PUBLIC_PASSPORT_CONTRACT_ADDRESS=${passportAddress}`);

  return deploymentInfo;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
