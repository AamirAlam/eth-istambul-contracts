const hre = require("hardhat");

async function main() {
  const factoryAddress = "0xDd2183623973093F149000Be20224056d68ADD5a";
  const wethAddress = "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6";
  const proxyReader = "0xCF63299e788343A7431AE7428593EEc5560BE93F";
  const params = [factoryAddress, wethAddress, proxyReader];

  const routerAddress = "0x3990eE369Fb517906362F3C69fa78dc78672A146";

  await hre.run("verify:verify", {
    address: routerAddress,
    constructorArguments: [...params],
  });

  console.log("UniswapV2Router verired at:", routerAddress);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
