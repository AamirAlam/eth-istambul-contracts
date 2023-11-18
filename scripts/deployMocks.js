const { ethers } = require("hardhat");
const { sleep } = require("./helper");

async function main() {
  const USDC = await ethers.getContractFactory("MintableERC20");

  // Deploying faucet contract
  const usdc = await USDC.deploy("USD Coin", "USDC", 6);
  await usdc.deployed();
  await sleep(20000);
  console.log("USDC deployed:", usdc.address);

  const usdcContract = USDC.attach(usdc.address);

  const usdcMint = await usdcContract.mint("100000000000000"); // 100M
  console.log("usdc mint trx", usdcMint);

  await sleep(30000);
  // deploy and mint 1INCH
  const ONE_INCH = await ethers.getContractFactory("MintableERC20");
  // Deploying sleep contract
  const oneInch = await ONE_INCH.deploy("ONE INCH", "1INCH", 18);
  await oneInch.deployed();
  console.log("DAI Faucet:", oneInch.address);
  await sleep(30000);
  const oneInchContract = await ONE_INCH.attach(oneInch.address);

  const mint2 = await oneInchContract.mint("100000000000000000000000000"); // 100M
  console.log("mint 1Inch trx", mint2);
  // const sleepContract = sleep.address;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
