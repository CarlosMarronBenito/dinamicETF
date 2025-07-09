const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  const [admin] = await ethers.getSigners();
  console.log("👑 Admin wallet:", admin.address);

  const deployed = JSON.parse(fs.readFileSync("deployed.json"));
  const vaultAddress = deployed.lastCompetition?.vault;
  if (!vaultAddress) throw new Error("❌ No vault found in deployed.json");

  const vault = await ethers.getContractAt("CompetitionVault", vaultAddress);

  const amountIn = ethers.parseUnits("8.1", 18);
  const amountOutMin = 0;
  const path = [
    "0x141Da2E915892D6D6c7584424A64903050Ac4226",
    "0x678c34581db0a7808d0aC669d7025f1408C9a3C6"
  ];
  const isTokenInWrapped = true;
  const receiveUnwrappedToken = false;
  const deadline = Math.floor(Date.now() / 1000) + 600;

  console.log("🔁 Ejecutando swap...");

  try {
    const tx = await vault.adminSwapExactTokensForTokens(
      amountIn,
      amountOutMin,
      path,
      isTokenInWrapped,
      receiveUnwrappedToken,
      deadline
    );

    console.log("⏳ Tx enviada:", tx.hash);
    const receipt = await tx.wait();
    console.log("✅ Swap completado en bloque:", receipt.blockNumber);
  } catch (err) {
    console.error("🔥 Swap reverted");
    if (err.error && err.error.data) {
      const revertData = err.error.data;
      console.error("🧠 Raw revert data:", revertData);
    } else {
      console.error("📦 Full error object:", err);
    }
  }
}

main().catch((err) => {
  console.error("💥 Fatal:", err);
  process.exit(1);
});
