/* eslint-disable camelcase */
const { ethers } = require("hardhat");

async function main() {
  const contractFactory = await ethers.getContractFactory(
    "SleepSwapMasterChef"
  );

  const owner = "0x8BD0e959E9a7273D465ac74d427Ecc8AAaCa55D8";

  const params = [owner];
  const deployedContract = await contractFactory.deploy(...params);

  console.log(`deployed sleepswap   at: ${deployedContract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
