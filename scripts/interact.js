require("dotenv").config();
const { ethers } = require("ethers");
const hre = require("hardhat");


const CONTRACT_ADDRESS = "0x3db5A0D0dFb28aA1CB58f465b752fa0671d1C217";

const ABI = [
  "function swapEqualCHZToMultipleTokens(address[] tokensOut, uint256 minOutPerToken) payable"
];

async function main() {
  const provider = new ethers.JsonRpcProvider(process.env.CHILIZ_RPC);
  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
  const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, wallet);

  const tokensOut = [
    "0x6D124526a5948Cb82BB5B531Bf9989D8aB34C899",
    "0x6350f61CDa7baea0eFAFF15ba10eb7A668E816da",
    "0x141Da2E915892D6D6c7584424A64903050Ac4226"
  ];

  const totalCHZ = ethers.parseEther("1"); 
  const minOutPerToken = 0; 

  const tx = await contract.swapEqualCHZToMultipleTokens(tokensOut, minOutPerToken, {
    value: totalCHZ
  });

  console.log("✅ TX enviada:", tx.hash);
  const receipt = await tx.wait();
  console.log("📄 Confirmada:", receipt.transactionHash);
}

main().catch(console.error);
