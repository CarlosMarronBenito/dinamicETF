const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("🚀 Deploying contracts with:", deployer.address);

  // Dirección del batch buyer (ya desplegado)
  const batchCHZBuyer = "0x3db5A0D0dFb28aA1CB58f465b752fa0671d1C217";

  // Deploy CompetitionFactory
  const Factory = await ethers.getContractFactory("CompetitionFactory");
  console.log("📦 Deploying CompetitionFactory...");
  const factory = await Factory.deploy(batchCHZBuyer);
  await factory.waitForDeployment(); // Ethers v6
  console.log("✅ Factory deployed at:", factory.target);

  // Save factory address
  const deployed = {
    factory: factory.target,
  };

  fs.writeFileSync("deployed.json", JSON.stringify(deployed, null, 2));
  console.log("📄 Deployment data saved to deployed.json");
}

main().catch((error) => {
  console.error("🔥 Fatal error:", error);
  process.exit(1);
});
