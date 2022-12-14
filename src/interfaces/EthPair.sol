// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface EthPair {
    function token() external view returns (ERC20);
    function calculateTrade(uint256 amount, bool firstToSecond) external view returns (uint256);
    function trade(uint256 amount, bool firstToSecond, address beneficiar) external;
    function deposit(address depositor) external;
}

