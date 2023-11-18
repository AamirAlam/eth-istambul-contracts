const hre = require("hardhat");

async function main() {
  // deployed addresses
  const usdcAddress = "0x50A5e47a6B91F390eA5De80D7f86Bf96163Bed78";
  const oneIinchAddress = "0x88f7a97e586ffD74c9Ccb4E0B92Df12F4C567A80";

  const deployParam = ["USD Coin", "USDC", 6];

  await hre.run("verify:verify", {
    address: usdcAddress,
    constructorArguments: [...deployParam],
  });

  console.log("usdcAddress verired at:", usdcAddress);

  await hre.run("verify:verify", {
    address: oneIinchAddress,
    constructorArguments: ["DAI Coin", "DAI", 18],
  });

  console.log("oneIinchAddress verired at:", oneIinchAddress);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
