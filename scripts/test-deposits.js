const { ethers } = require("hardhat");
const { sleep, toWei } = require("./helper");

// test addresses on mumbai
const usdcAddress = "0x50A5e47a6B91F390eA5De80D7f86Bf96163Bed78";
const oneIinchAddress = "0x88f7a97e586ffD74c9Ccb4E0B92Df12F4C567A80";
const masterChefMumbai = "0x028A408F21a44E8C6F07E62C5A948b948A765228";

async function main() {
  const owner = await ethers.getSigner();
  const sleepSwapMasterChef = masterChefMumbai;
  const token0 = "0x2ddb853a09d4Da8f0191c5B887541CD7af3dDdce";
  const token1 = "0xEba3b31122e701296877001157083E2C0491020C";

  const contractFact = await ethers.getContractFactory("SleepSwapMasterChef");
  const contract = contractFact.attach(sleepSwapMasterChef);

  const erc20Fact = await ethers.getContractFactory("MintableERC20");
  const token0Cont = erc20Fact.attach(token0);
  const token1Cont = erc20Fact.attach(token1);

  // user usdc = 100;

  // amounts after 1inch swap
  const amount0 = toWei("0.2", 18);
  const amount1 = toWei("0.588294", 6);
  console.log("amounts ", { amount0, amount1 });

  const token0Allowance = await token0Cont.allowance(
    owner.address,
    sleepSwapMasterChef
  );
  const token1Allowance = await token1Cont.allowance(
    owner.address,
    sleepSwapMasterChef
  );

  console.log("allownace ", { token0Allowance, token1Allowance });

  if (ethers.BigNumber.from(token0Allowance).lte(amount0)) {
    // approve tokens
    const approveTrx0 = await token0Cont.approve(
      sleepSwapMasterChef,
      "100000000000000000000000000"
    );
    console.log("token0 approved ", approveTrx0);
    await sleep(3000);
  }

  if (ethers.BigNumber.from(token1Allowance).lte(amount1)) {
    const approveTrx1 = await token1Cont.approve(
      sleepSwapMasterChef,
      "100000000000000000000000000"
    );
    console.log("token1 approved ", approveTrx1);
    await sleep(3000);
  }

  const currentPrice = "804279000000000000";

  function nextSellPrice(_current, _percent) {
    return ethers.BigNumber.from(_current)
      .add(ethers.BigNumber.from(_current).mul(_percent).div(100))
      .toString();
  }

  function nextBuyPrice(_current, _percent) {
    return ethers.BigNumber.from(_current)
      .sub(ethers.BigNumber.from(_current).mul(_percent).div(100))
      .toString();
  }

  const buyPrices = [];
  const sellPrices = [];
  for (let i = 0; i < 5; i++) {
    let nextBuy;
    if (buyPrices.length === 0) {
      nextBuy = nextBuyPrice(currentPrice, 10);
      buyPrices.push(nextBuy);
    } else {
      nextBuy = nextBuyPrice(buyPrices[i - 1], 10);
      buyPrices.push(nextBuy);
    }
  }

  for (let i = 0; i < 5; i++) {
    let nextSell;
    if (sellPrices.length === 0) {
      nextSell = nextSellPrice(currentPrice, 10);
      sellPrices.push(nextSell);
    } else {
      nextSell = nextSellPrice(sellPrices[i - 1], 10);
      sellPrices.push(nextSell);
    }
  }

  console.log("prices", { buyPrices, sellPrices });

  const params = [
    buyPrices,
    sellPrices,
    amount0,
    amount1,
    token0Cont.address,
    token1Cont.address,
  ];

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
