const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  const [user] = await ethers.getSigners();
  console.log("👤 Usuario:", user.address);

  const deployed = JSON.parse(fs.readFileSync("deployed.json"));
  const vaultAddress = deployed.lastCompetition?.vault;
  const nftAddress = deployed.lastCompetition?.nft;

  if (!vaultAddress || !nftAddress) throw new Error("❌ Vault o NFT no encontrados en deployed.json");

  const vault = await ethers.getContractAt("CompetitionVault", vaultAddress);
  const nft = await ethers.getContractAt("CompetitionNFT", nftAddress);

  const tokenId = 1;

  const owner = await nft.ownerOf(tokenId);
  console.log(`🎫 El NFT ${tokenId} pertenece a: ${owner}`);
  console.log(`👤 Tú eres: ${user.address}`);

  if (owner.toLowerCase() !== user.address.toLowerCase()) {
    throw new Error("❌ No eres el propietario de ese NFT. No puedes hacer redeem.");
  }

  console.log(`🔥 Haciendo redeem del NFT ${tokenId}...`);

  const tx = await vault.redeem(tokenId);  
  console.log("⏳ Tx enviada:", tx.hash);

  const receipt = await tx.wait();
  console.log("✅ NFT quemado y CHZ reclamado en el bloque:", receipt.blockNumber);
}

main().catch((err) => {
  console.error("💥 Error:", err);
  process.exit(1);
});
