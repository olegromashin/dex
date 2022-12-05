// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Factory.sol";
import "./Pair.sol";

contract Router {
    Factory internal factoryContract;

    constructor(address factoryAddress) {
        factoryContract = Factory(factoryAddress);
    }

    function pairInstantiated(address pairAddress) public view returns (bool) {
        return factoryContract.instantiatedPairs(pairAddress);
    }

    function calculateTrade(address pairAddress, bool firstToSecond, uint256 amount) external view returns (uint256) {
        require(factoryContract.instantiatedPairs(pairAddress), "Unknown pair.");
        Pair pair = Pair(pairAddress);
        return pair.calculateTrade(amount, firstToSecond);
    }

    function trade(address pairAddress, bool firstToSecond, uint256 amount) external {
        require(factoryContract.instantiatedPairs(pairAddress), "Unknown pair.");
        Pair pair = Pair(pairAddress);
        pair.trade(amount, firstToSecond, msg.sender);
    }

    function deposit(address pairAddress) external {
        require(factoryContract.instantiatedPairs(pairAddress), "Unknown pair.");
        Pair pair = Pair(pairAddress);
        pair.deposit(msg.sender);
    }

    function swap(address pairAddress, bool firstToSecond, uint256 amount, address benefeciar) external {
        require(factoryContract.instantiatedPairs(pairAddress), "Unknown pair.");
        Pair pair = Pair(pairAddress);
        pair.trade(amount, firstToSecond, benefeciar);
    }
}
