/* eslint-disable camelcase */
const { ethers } = require("hardhat");

async function main() {
  const contractFactory = await ethers.getContractFactory("UniswapV2Factory");
  const owner = await ethers.getSigner();

  const deployedContract = await contractFactory.deploy(owner.address);

  console.log(`deployed UniswapV2Factory   at: ${deployedContract.address}`);
  // const contract = contractFactory.attach(deployedContract.address);

  // const inithash = await contract.INIT_CODE_HASH();
  // console.log("init code hash ", inithash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
