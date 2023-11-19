/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-solhint");

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

module.exports = {
  etherscan: {
    apiKey: "2X7YUM8RI1H8JM3BCSAEFQ2SH5V34QVRDA",
  },
  solidity: {
    compilers: [
      {
        version: "0.8.7",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.7.5",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.5.16",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.6.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
    gas: 700000000,
    //  gasMultiplier:5,
    gasPrice: 5,
  },

  defaultNetwork: "hardhat",

  networks: {
    polygon: {
      url: "https://polygon-rpc.com/",
      accounts: [process.env.private_key],
      // gas: 3000000, // <--- Twice as much
      // gasPrice: 800000000000,
      timeout: 999999,
    },
    mumbai: {
      url: "https://rpc.ankr.com/polygon_mumbai",
      accounts: [process.env.private_key],
      timeout: 999999,
    },
    goerli: {
      url: "https://rpc.ankr.com/eth_goerli",
      accounts: [process.env.private_key],
      timeout: 999999,
    },
    scrollSepolia: {
      // chainId: 534351,
      url: "https://sepolia-rpc.scroll.io/" || "",
      accounts:
        process.env.private_key !== undefined ? [process.env.private_key] : [],
    },
  },
};
