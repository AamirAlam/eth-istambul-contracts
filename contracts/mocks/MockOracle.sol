// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MockOracle is Ownable {
    int256 private mockPrice;

    event PriceUpdated(int256 newPrice);

    constructor(int256 initialPrice) {
        mockPrice = initialPrice;
    }

    function setMockPrice(int256 newPrice) external onlyOwner {
        mockPrice = newPrice;
        emit PriceUpdated(newPrice);
    }

    function getPrice() external view returns (int256) {
        return mockPrice;
    }
}
