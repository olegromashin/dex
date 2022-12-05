// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Erc20.sol";

interface Pair is Erc20 {
    function token1() external view returns (Erc20);
    function token2() external view returns (Erc20);
    function calculateTrade(uint256 amount, bool firstToSecond) external view returns (uint256);
    function trade(uint256 amount, bool firstToSecond, address beneficiar) external;
    function deposit(address depositor) external;
}

