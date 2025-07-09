const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  const [admin] = await ethers.getSigners();
  console.log("👑 Admin:", admin.address);

  const deployed = JSON.parse(fs.readFileSync("deployed.json"));
  const vaultAddress = deployed.lastCompetition?.vault;
  if (!vaultAddress) throw new Error("❌ No vault found in deployed.json");

  const vault = await ethers.getContractAt("CompetitionVault", vaultAddress);

  console.log("🏁 Finalizando la competición...");
  const tx = await vault.endCompetition();
  console.log("⏳ Tx enviada:", tx.hash);

  const receipt = await tx.wait();
  console.log("✅ Competición finalizada en el bloque:", receipt.blockNumber);
}

main().catch((err) => {
  console.error("💥 Error:", err);
  process.exit(1);
});
