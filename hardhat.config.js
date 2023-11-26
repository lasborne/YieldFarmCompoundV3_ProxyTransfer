require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config()

const goerli_testnet = process.env.GOERLI_API_KEY
const base_mainnet = process.env.BASE_API_KEY
const base_testnet = process.env.BASE_GOERLI_API_KEY
const deployerPrivateKey = process.env.PRIVATE_KEY
const testerPrivateKey = process.env.PRIVATE_KEY2

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "goerli",
  networks: {
    hardhat: {},
    goerli: {
      url: goerli_testnet,
      accounts: [deployerPrivateKey, testerPrivateKey]
    },
    base: {
      url: base_mainnet,
      accounts: [deployerPrivateKey, testerPrivateKey]
    },
    baseGoerli: {
      url: base_testnet,
      accounts: [deployerPrivateKey, testerPrivateKey]
    }
  },
  /*etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  },*/
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
}
