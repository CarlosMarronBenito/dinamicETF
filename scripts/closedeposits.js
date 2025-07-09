const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  const [admin] = await ethers.getSigners();
  console.log("👑 Acting as admin (Pepe):", admin.address);

  const deployed = JSON.parse(fs.readFileSync("deployed.json"));
  const vaultAddress = deployed.lastCompetition?.vault;

  if (!vaultAddress) throw new Error("❌ Vault address missing");

  const vault = await ethers.getContractAt("CompetitionVault", vaultAddress);

  const tx = await vault.setDepositsOpen(false);
  console.log("⏳ Tx enviada:", tx.hash);
  const receipt = await tx.wait();
  console.log("✅ Vault: depósitos desactivados. Block:", receipt.blockNumber);
}

main().catch((err) => {
  console.error("🔥 Error:", err);
  process.exit(1);
});
