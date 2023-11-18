const hre = require("hardhat");

async function main() {
  const params = [];

  const pairAddress = "0xad9fC7E8B58A052E7685cD929Cf90ac5A82158e9";

  await hre.run("verify:verify", {
    address: pairAddress,
    constructorArguments: [...params],
  });

  console.log("pair verired at:", pairAddress);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
