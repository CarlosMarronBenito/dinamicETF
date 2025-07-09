const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  const [user] = await ethers.getSigners();
  console.log("👤 Acting as user:", user.address);

  // Leer dirección del vault desde archivo
  const deployed = JSON.parse(fs.readFileSync("deployed.json"));
  const vaultAddress = deployed.lastCompetition?.vault;

  if (!vaultAddress) {
    throw new Error("❌ No vault address found. Create a competition first.");
  }

  const vault = await ethers.getContractAt("CompetitionVault", vaultAddress);

  // CHZ que el usuario quiere depositar
  const amountToSend = ethers.parseEther("10"); // 10 CHZ

  // Validar que el usuario tenga saldo suficiente
  const balance = await ethers.provider.getBalance(user.address);
  if (balance < amountToSend) {
    throw new Error("❌ Not enough CHZ to deposit.");
  }

  console.log(`📨 Sending ${ethers.formatEther(amountToSend)} CHZ to vault: ${vaultAddress}`);

  try {
    // Llamar a la función sin argumentos (minOut ya no existe)
    const tx = await vault.depositAndBuy({ value: amountToSend });

    console.log("⏳ Tx sent:", tx.hash);
    const receipt = await tx.wait();
    console.log("✅ Deposit and NFT mint successful! Block:", receipt.blockNumber);

    // Recuperar tokenId si NFT lo permite
    try {
      const nftAddress = await vault.nftAddress();
      const nft = await ethers.getContractAt("CompetitionNFT", nftAddress);
      const tokenId = await nft.getCurrentTokenId(); // debe existir en el contrato NFT
      console.log("🎟️ Your NFT tokenId:", tokenId.toString());

      deployed.lastDeposit = {
        user: user.address,
        tokenId: tokenId.toString(),
        vault: vaultAddress,
      };
      fs.writeFileSync("deployed.json", JSON.stringify(deployed, null, 2));
      console.log("📄 Saved lastDeposit in deployed.json");
    } catch {
      console.log("ℹ️ Could not fetch tokenId automatically (missing function in NFT).");
    }
  } catch (error) {
    console.error("❌ Transaction failed:");
    if (error.data) {
      console.error("📦 Revert data (hex):", error.data);
    }
    console.error(error);
  }
}

main().catch((error) => {
  console.error("🔥 Script error:", error);
  process.exit(1);
});
