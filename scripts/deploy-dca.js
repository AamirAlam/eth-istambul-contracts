/* eslint-disable camelcase */
const { ethers } = require("hardhat");

async function main() {
  const contractFactory = await ethers.getContractFactory("SleepSwapMasterDCA");

  const owner = "0x8BD0e959E9a7273D465ac74d427Ecc8AAaCa55D8";
  const router = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
  const params = [owner, router];
  const deployedContract = await contractFactory.deploy(...params);

  console.log(`deployed sleepswap   at: ${deployedContract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
