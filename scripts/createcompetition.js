const { ethers } = require("hardhat");
const fs = require("fs");

function generateRandomName() {
  const suffix = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `TEST_${suffix}`;
}

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("📲 Using signer:", deployer.address);

  const deployed = JSON.parse(fs.readFileSync("deployed.json"));
  const factoryAddress = deployed.factory;
  const Factory = await ethers.getContractAt("CompetitionFactory", factoryAddress);

  const name = generateRandomName();
  const nftName = `${name} NFT Collection`;
  const nftSymbol = name.replace("TEST_", "T");

  const initialTokens = [
    "0x6D124526a5948Cb82BB5B531Bf9989D8aB34C899",
    "0x6350f61CDa7baea0eFAFF15ba10eb7A668E816da",
    "0x141Da2E915892D6D6c7584424A64903050Ac4226"
  ];

  const wchz = "0x678c34581db0a7808d0aC669d7025f1408C9a3C6";
  const adminRouter = "0x94448122c3F4276CDFA8C190249da4C1c736eEab";
  const baseURI = "ipfs://bafybeifaj6sk55qlegcgagya5ldrw675vdzctj6tjlihan75eqich2t3wi/";

  // Validaciones
  const hasDuplicates = new Set(initialTokens).size !== initialTokens.length;
  if (hasDuplicates) throw new Error("❌ initialTokens tiene duplicados");

  if (!ethers.isAddress(wchz) || wchz === ethers.ZeroAddress) {
    throw new Error("❌ Dirección WCHZ inválida");
  }

  if (!ethers.isAddress(adminRouter) || adminRouter === ethers.ZeroAddress) {
    throw new Error("❌ Dirección router inválida");
  }

  console.log("✅ Todos los parámetros son válidos:");
  console.log({ name, nftName, nftSymbol, initialTokens, wchz, router: adminRouter, baseURI });

  try {
    console.log(`🚀 Llamando a createCompetition("${name}")...`);
    const tx = await Factory.createCompetition(
      name,
      nftName,
      nftSymbol,
      initialTokens,
      wchz,
      adminRouter,
      baseURI
    );
    console.log("⏳ Tx enviada:", tx.hash);
    const receipt = await tx.wait();
    console.log("✅ ¡Competición creada! Block:", receipt.blockNumber);

    // Obtener direcciones del vault y nft
    const [vault, nft] = await Factory.getCompetition(name);
    console.log("🏦 Vault:", vault);
    console.log("🎟️  NFT:", nft);

    // Establecer base URI en el NFT (si no se ha hecho en el Factory)
    const NFT = await ethers.getContractAt("CompetitionNFT", nft);
    const baseSetTx = await NFT.setBaseTokenURI(baseURI);
    await baseSetTx.wait();
    console.log("🖼️ BaseTokenURI seteado correctamente.");

    // Guardar en deployed.json
    deployed.lastCompetition = { name, vault, nft };
    fs.writeFileSync("deployed.json", JSON.stringify(deployed, null, 2));
    console.log("📄 Guardado en deployed.json");

  } catch (err) {
    console.error("❌ Error al crear competición:");
    if (err.data) {
      console.error("📦 Revert data (hex):", err.data);
    }
    console.error(err);
  }
}

main().catch((error) => {
  console.error("🔥 Error fatal:", error);
  process.exit(1);
});
