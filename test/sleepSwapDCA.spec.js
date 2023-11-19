const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SleepSwapMasterDCA", function () {
  let sleepSwap;
  let owner;
  let manager;
  let user1;
  let user2;
  let token1;
  let token2;
  let mockOracle;

  before(async function () {
    [owner, manager, user1, user2] = await ethers.getSigners();

    // Deploy Mock Oracle
    const MockOracle = await ethers.getContractFactory("MockOracle");
    mockOracle = await MockOracle.deploy(1000); // Initial mock price is set to 1000
    await mockOracle.deployed();

    // Deploy Mock Tokens
    const Token = await ethers.getContractFactory("MintableERC20");
    token1 = await Token.deploy("Test 1", "TTA", 18);
    token2 = await Token.deploy("Test 2", "TTB", 18);

    // Deploy SleepSwapMasterDCA with mock Oracle and Tokens
    const SleepSwapMasterDCA = await ethers.getContractFactory(
      "SleepSwapMasterDCA"
    );
    sleepSwap = await SleepSwapMasterDCA.deploy(
      manager.address,
      mockOracle.address,
      ethers.constants.AddressZero,
      ethers.constants.AddressZero
    );
    await sleepSwap.deployed();
  });

  it("Should deploy with the correct owner and manager", async function () {
    expect(await sleepSwap.owner()).to.equal(owner.address);
    expect(await sleepSwap.manager()).to.equal(manager.address);
  });

  it("Should allow the owner to add a new manager", async function () {
    const newManager = await ethers.Wallet.createRandom();
    await sleepSwap.addManager(newManager.address);
    expect(await sleepSwap.manager()).to.equal(newManager.address);
  });

  it("Should allow the owner to update the manager", async function () {
    const newManager = await ethers.Wallet.createRandom();
    await sleepSwap.updateManager(newManager.address);
    expect(await sleepSwap.manager()).to.equal(newManager.address);
  });

  it("Should allow a user to start the strategy with deposit", async function () {
    const amount0 = ethers.utils.parseEther("1");
    const amount1 = ethers.utils.parseEther("2");
    await token1.transfer(user1.address, amount0);
    await token2.transfer(user1.address, amount1);
    await token1.connect(user1).approve(sleepSwap.address, amount0);
    await token2.connect(user1).approve(sleepSwap.address, amount1);

    await sleepSwap.connect(user1).startStrategyWithDeposit(
      [
        /* start times */
      ],
      amount0,
      amount1,
      token1.address,
      token2.address
    );

    // Add assertions for the state changes and emitted events
  });

  it("Should allow a user to start the strategy with existing funds", async function () {
    // Similar to the previous test case but use startStrategy function
  });

  it("Should execute orders correctly", async function () {
    // Mock Oracle price is set to 1000, adjust assertions based on your contract logic
    const expectedOutput = await sleepSwap.swapTokenTest(
      ethers.utils.parseEther("1")
    );
    expect(expectedOutput[0]).to.equal(900); // 90% of 1000
  });

  it("Should update the order status correctly", async function () {
    // Add test logic here, including updating order status and checking balances
  });

  it("Should stop the strategy correctly", async function () {
    // Add test logic here, including stopping the strategy and checking balances
  });

  it("Should withdraw user funds correctly", async function () {
    // Add test logic here, including withdrawing funds and checking balances
  });

  it("Should handle edge cases and prevent unauthorized actions", async function () {
    // Add test logic for edge cases, unauthorized actions, and reentrancy attacks
  });

  // Add more test cases as needed
});
