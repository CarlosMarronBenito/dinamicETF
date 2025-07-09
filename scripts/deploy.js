const hre = require("hardhat");

async function main() {
  const router = "0x94448122c3F4276CDFA8C190249da4C1c736eEab"; // Dirección del router V2 en Chiliz
  const wchz = "0x678c34581db0a7808d0aC669d7025f1408C9a3C6";    // Dirección de CHZ en Chiliz

  const ContractFactory = await hre.ethers.getContractFactory("BatchCHZBuyerNative");
  const contract = await ContractFactory.deploy(router, wchz);

  await contract.waitForDeployment();
  const address = await contract.getAddress();
  console.log(`✅ Contrato desplegado en: ${address}`);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
