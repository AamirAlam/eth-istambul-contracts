const { ethers } = require("hardhat");
const { sleep } = require("./helper");

async function main() {
  const owner = await ethers.getSigner();
  const sleepSwapMasterChef = "0x817FC3DeCb066F79a41EF54281284c70A721004a";
  const usdcAddress = "0x50A5e47a6B91F390eA5De80D7f86Bf96163Bed78";
  const oneIinchAddress = "0x88f7a97e586ffD74c9Ccb4E0B92Df12F4C567A80";

  const contractFact = await ethers.getContractFactory("SleepSwapMasterChef");
  const contract = contractFact.attach(sleepSwapMasterChef);

  const erc20Fact = await ethers.getContractFactory("MintableERC20");
  const usdc = erc20Fact.attach(usdcAddress);
  const oneInch = erc20Fact.attach(oneIinchAddress);

  // user usdc = 100;

  // amounts after 1inch swap
  const amount0 = "50000000";
  const amount1 = ethers.utils.parseEther("140.712651").toString();
  console.log("amounts ", { amount0, amount1 });

  // const currentPrice = "59439800000000000";

  // function nextBuyPrice(_current, _percent) {
  //   return ethers.BigNumber.from(_current)
  //     .add(ethers.BigNumber.from(_current).mul(_percent).div(100))
  //     .toString();
  // }

  // function nextSellPrice(_current, _percent) {
  //   return ethers.BigNumber.from(_current)
  //     .sub(ethers.BigNumber.from(_current).mul(_percent).div(100))
  //     .toString();
  // }

  // const buyPrices = [];
  // const sellPrices = [];
  // for (let i = 0; i < 5; i++) {
  //   let nextBuy;
  //   if (buyPrices.length === 0) {
  //     nextBuy = nextBuyPrice(currentPrice, 10);
  //     buyPrices.push(nextBuy);
  //   } else {
  //     nextBuy = nextBuyPrice(buyPrices[i - 1], 10);
  //     buyPrices.push(nextBuy);
  //   }
  // }

  // for (let i = 0; i < 5; i++) {
  //   let nextSell;
  //   if (sellPrices.length === 0) {
  //     nextSell = nextSellPrice(currentPrice, 10);
  //     sellPrices.push(nextSell);
  //   } else {
  //     nextSell = nextSellPrice(sellPrices[i - 1], 10);
  //     sellPrices.push(nextSell);
  //   }
  // }

  // console.log("prices", { buyPrices, sellPrices });

  // const params = [
  //   buyPrices,
  //   sellPrices,
  //   amount0,
  //   amount1,
  //   usdc.address,
  //   oneInch.address,
  // ];

  // console.log("params ", params);

  const trx = await Promise.all([
    contract.orders(1),
    contract.orders(2),
    contract.orders(3),
    contract.orders(4),
    contract.orders(5),
    contract.orders(6),
    contract.orders(7),
    contract.orders(8),
    contract.orders(9),
    contract.orders(10),
  ]);
  console.log("user orders trategy orders ", trx);

  // console.log("stopping position");

  // const trx2 = await contract.stopStrategy();
  // console.log("stopped trx ", trx2);

  // const sleepContract = sleep.address;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
