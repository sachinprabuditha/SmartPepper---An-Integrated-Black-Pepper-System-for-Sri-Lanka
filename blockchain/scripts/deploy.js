const hre = require("hardhat");

async function main() {
  console.log("Deploying PepperAuction contract...");

  // Get deployer account
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", hre.ethers.formatEther(balance), "ETH");

  // Deploy contract
  const PepperAuction = await hre.ethers.getContractFactory("PepperAuction");
  const pepperAuction = await PepperAuction.deploy();

  await pepperAuction.waitForDeployment();

  const contractAddress = await pepperAuction.getAddress();
  console.log("PepperAuction deployed to:", contractAddress);

  // Save deployment info
  const deploymentInfo = {
    network: hre.network.name,
    contractAddress: contractAddress,
    deployer: deployer.address,
    deployedAt: new Date().toISOString(),
    blockNumber: await hre.ethers.provider.getBlockNumber()
  };

  console.log("\n=== Deployment Info ===");
  console.log(JSON.stringify(deploymentInfo, null, 2));

  // Verify initial contract state
  const totalAuctions = await pepperAuction.getTotalAuctions();
  const platformFee = await pepperAuction.platformFeePercent();
  const minBidIncrement = await pepperAuction.minBidIncrement();

  console.log("\n=== Contract State ===");
  console.log("Total Auctions:", totalAuctions.toString());
  console.log("Platform Fee:", platformFee.toString(), "%");
  console.log("Min Bid Increment:", minBidIncrement.toString(), "wei");

  console.log("\n✅ Deployment completed successfully!");
  console.log("\n📝 Update your .env file with:");
  console.log(`CONTRACT_ADDRESS=${contractAddress}`);

  return deploymentInfo;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
