// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface Erc20 {
    function balanceOf(address tokenOwner) external view returns(uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address spender, uint256 amount) external returns (bool);
}
