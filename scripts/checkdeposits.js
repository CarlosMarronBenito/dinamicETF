const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  const deployed = JSON.parse(fs.readFileSync("deployed.json"));
  const factoryAddress = deployed.factory;
  const competitionName = deployed.lastCompetition?.name;

  if (!factoryAddress || !competitionName) {
    throw new Error("❌ No factory or competition name found.");
  }

  const factory = await ethers.getContractAt("CompetitionFactory", factoryAddress);

  const isOpen = await factory.areDepositsOpen(competitionName);

  console.log(`📦 Competencia: ${competitionName}`);
  console.log(`💰 Depósitos abiertos: ${isOpen ? "✅ Sí" : "❌ No"}`);
}

main().catch((err) => {
  console.error("🔥 Error:", err);
  process.exit(1);
});
