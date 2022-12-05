// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Factory {
    mapping(address => bool) public instantiatedPairs;

    function instantiatePair(address pairAddress) external {
        instantiatedPairs[pairAddress] = true;
    }
}
