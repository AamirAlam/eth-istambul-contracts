/* eslint-disable camelcase */
const { ethers } = require("hardhat");

async function main() {
  const contractFactory = await ethers.getContractFactory("SleepSwapMasterDCA");

  const owner = "0x8BD0e959E9a7273D465ac74d427Ecc8AAaCa55D8";
  const router = "0xE592427A0AEce92De3Edee1F18E0157C05861564";

  const airnodeRRP = "0xa0AD79D995DdeeB18a14eAef56A549A04e3Aa1Bd";

  const dapiProxy = "0x3ACccB328Db79Af1B81a4801DAf9ac8370b9FBF8";
  const params = [owner, router, airnodeRRP, dapiProxy];
  const deployedContract = await contractFactory.deploy(...params);

  console.log(`deployed sleepswap   at: ${deployedContract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
