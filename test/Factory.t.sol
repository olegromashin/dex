// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Factory.sol";

contract FactoryTest is Test {
    Factory public factory;

    function setUp() external {
        factory = new Factory();
    }

    function testInstantiatePair() external {
        factory.instantiatePair(address(0));
        assertEq(factory.instantiatedPairs(address(0)), true);
    }

    function testNotInstantiatedAddress() external {
        assertEq(factory.instantiatedPairs(address(0)), false);
    }
}
