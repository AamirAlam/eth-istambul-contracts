const { ethers } = require("hardhat");
const { sleep, toWei } = require("./helper");

const wmaticPolygon = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270";
const usdtPolygon = "0xc2132D05D31c914a87C6611C10748AEb04B58e8F";

async function main() {
  const owner = await ethers.getSigner();
  const sleepSwapMasterChef = "0xD73624a0aaa1cc718Bea517A77868666B6082819"; // "0xBD4B78B3968922e8A53F1d845eB3a128Adc2aA12";
  const token0 = usdtPolygon;
  const token1 = wmaticPolygon;

  const contractFact = await ethers.getContractFactory("SleepSwapMasterDCA");
  const contract = contractFact.attach(sleepSwapMasterChef);

  const erc20Fact = await ethers.getContractFactory("MintableERC20");
  const token0Cont = erc20Fact.attach(token0);
  // const token1Cont = erc20Fact.attach(token1);

  // user usdc = 100;

  const amount0 = toWei("2", 6);
  const amount1 = toWei("0");
  console.log("amounts ", { amount0, amount1 });

  const token0Allowance = await token0Cont.allowance(
    owner.address,
    sleepSwapMasterChef
  );

  console.log("allownace ", { token0Allowance });

  if (ethers.BigNumber.from(token0Allowance).lte(amount0)) {
    // approve tokens
    const approveTrx0 = await token0Cont.approve(
      sleepSwapMasterChef,
      "100000000000000000000000000"
    );
    console.log("token0 approved ", approveTrx0);
    await sleep(3000);
  }

  async function getCurrentBlockTimestamp() {
    const polygonNodeUrl = "https://polygon-rpc.com";
    const provider = new ethers.providers.JsonRpcProvider(polygonNodeUrl);

    // Get the current block number
    const currentBlockNumber = await provider.getBlockNumber();

    // Get the current block
    const currentBlock = await provider.getBlock(currentBlockNumber);
    console.log("current block ", currentBlock);
    // Get the timestamp of the current block
    const currentBlockTimestamp = currentBlock.timestamp;

    return currentBlockTimestamp;
  }

  async function generateTimestampSeries() {
    const timestamps = [];
    const currentTimestamp = await getCurrentBlockTimestamp(); // Math.floor(new Date().getTime() / 1000);

    // Generate 5 timestamps with an increasing 10-minute interval
    for (let i = 0; i < 5; i++) {
      const timestamp = currentTimestamp + i * 600; // 600 seconds = 10 minutes
      timestamps.push(timestamp);
    }

    return timestamps;
  }

  const startTimes = await generateTimestampSeries();

  console.log("prices", { startTimes });

  const params = [startTimes, amount0, amount1, token0, token1];

  console.log("params ", params);

  const trx = await contract.startStrategyWithDeposit(...params);
  console.log("start trategy trx ", trx);

  // const sleepContract = sleep.address;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
