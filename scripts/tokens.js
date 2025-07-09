const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  const deployed = JSON.parse(fs.readFileSync("deployed.json"));
  const vaultAddress = deployed.lastCompetition?.vault;

  if (!vaultAddress) {
    throw new Error("❌ No vault found. Asegúrate de haber creado una competición.");
  }

  const vault = await ethers.getContractAt("CompetitionVault", vaultAddress);

  console.log("🔍 Obteniendo tokens configurados en el vault:", vaultAddress);

  // Leer secuencialmente hasta que falle
  const tokens = [];
  for (let i = 0; ; i++) {
    try {
      const token = await vault.tokensToBuy(i);
      tokens.push(token);
    } catch {
      break; // se acabó la lista
    }
  }

  if (tokens.length === 0) {
    console.log("⚠️ No hay tokens configurados en este vault.");
  } else {
    console.log("🪙 Tokens configurados:");
    tokens.forEach((token, index) => {
      console.log(`  #${index}: ${token}`);
    });
  }
}

main().catch((err) => {
  console.error("🔥 Error fatal:", err);
  process.exit(1);
});
