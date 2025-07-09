const { ethers } = require("hardhat");
const fs = require("fs");

// ⚠️ Actualiza esta lista con los tokens que deseas establecer
const NEW_TOKENS = [
  "0x6D124526a5948Cb82BB5B531Bf9989D8aB34C899",
  "0x6350f61CDa7baea0eFAFF15ba10eb7A668E816da",
  "0x141Da2E915892D6D6c7584424A64903050Ac4226",
  "0x678c34581db0a7808d0aC669d7025f1408C9a3C6"
];

async function main() {
  const [admin] = await ethers.getSigners();
  console.log("🔑 Using signer:", admin.address);

  const deployed = JSON.parse(fs.readFileSync("deployed.json"));
  const vaultAddress = deployed.lastCompetition?.vault;
  if (!vaultAddress) throw new Error("❌ No vault address found in deployed.json");

  const vault = await ethers.getContractAt("CompetitionVault", vaultAddress);

  // Validar duplicados y direcciones inválidas
  const unique = new Set(NEW_TOKENS);
  if (unique.size !== NEW_TOKENS.length) throw new Error("❌ Hay tokens duplicados");

  for (const token of NEW_TOKENS) {
    if (!ethers.isAddress(token) || token === ethers.ZeroAddress) {
      throw new Error(`❌ Dirección inválida: ${token}`);
    }
  }

  console.log("🔄 Actualizando lista de tokens en vault:", vaultAddress);
  console.log("🪙 Nueva lista:", NEW_TOKENS);

  const tx = await vault.updateTokensToBuy(NEW_TOKENS);
  console.log("⏳ Tx enviada:", tx.hash);
  await tx.wait();
  console.log("✅ Tokens actualizados correctamente.");
}

main().catch((err) => {
  console.error("🔥 Error fatal:", err);
  process.exit(1);
});
