require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: {
    version: "0.8.21",
    settings: {
      optimizer: {
        enabled: true,
        runs: 40
      },
    },
  },
  networks: {
    chiliz: {
      url: process.env.CHILIZ_RPC,
      accounts: [process.env.PRIVATE_KEY],
    },
    hardhat: {
    },
  },
};
