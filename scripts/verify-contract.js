const hre = require("hardhat");

async function main() {
  const owner = "0x8BD0e959E9a7273D465ac74d427Ecc8AAaCa55D8";

  const router = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
  const airnodeRRP = "0xa0AD79D995DdeeB18a14eAef56A549A04e3Aa1Bd";

  const dapiProxy = "0x3ACccB328Db79Af1B81a4801DAf9ac8370b9FBF8";
  const params = [owner, router, airnodeRRP, dapiProxy];

  const sleepSwapDCA = "0x532Dc8C839025E210547e1F303ae2710cA847871";

  await hre.run("verify:verify", {
    address: sleepSwapDCA,
    constructorArguments: [...params],
  });

  console.log("sleepSwapDCA verired at:", sleepSwapDCA);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
