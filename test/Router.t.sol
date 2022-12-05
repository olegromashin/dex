// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Factory.sol";
import "../src/Router.sol";

contract RouterTest is Test {
    Factory public factory;
    Router public router;

    function setUp() external {
        factory = new Factory();
        router = new Router(address(factory));
    }

    function testInstantiatedPair() external {
        factory.instantiatePair(address(0));
        assertEq(router.pairInstantiated(address(0)), true);
    }

    function testNotInstantiatedAddress() external {
        assertEq(router.pairInstantiated(address(0)), false);
    }

    function testCannotCalculateTradeOnNotInstantiatedPair() external {
        vm.expectRevert(bytes("Unknown pair."));
        router.calculateTrade(address(0), true, 200);
    }
}
