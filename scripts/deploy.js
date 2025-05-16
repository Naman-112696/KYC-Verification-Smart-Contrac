const { ethers } = require("hardhat");

async function main() {
  console.log("Starting deployment process...");

  // Get the contract factory
  const KYCVerification = await ethers.getContractFactory("KYCVerification");
  console.log("Contract factory created");

  // Deploy the contract
  const kycVerification = await KYCVerification.deploy();
  await kycVerification.deployed();

  console.log(`KYCVerification deployed to: ${kycVerification.address}`);
}

// Execute the deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error during deployment:", error);
    process.exit(1);
  });
