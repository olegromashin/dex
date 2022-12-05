// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TokenToken.sol";
import "../src/Erc20.sol";
import "../src/Erc20Eqt.sol";
import "../src/Erc20Rom.sol";

contract TokenTokenTest is Test {
    Pair public pair;
    RomToken public token1;
    EqtToken public token2;

    function setUp() external {
        token1 = new RomToken();
        token1.mint(2000, address(this));
        token2 = new EqtToken();
        token2.mint(2000, address(this));
        pair = new TokenTokenPair(address(token1), address(token2));
    }

    function testCannotDepositIfDidntSendTokens() external {
        vm.expectRevert(bytes("You have to send both tokens to make deposit."));
        pair.deposit(address(this));
    }

    function testDeposit() external {
        token1.transfer(address(pair), 1000);
        token2.transfer(address(pair), 1000);
        pair.deposit(address(this));
        assertEq(pair.balanceOf(address(this)), 1000);
    }

    function testCannotTradeIfLiquidityPoolEmpty() external {
        token1.transfer(address(pair), 1000);
        vm.expectRevert(bytes("Liquidity pool is empty."));
        pair.trade(1000, true, address(this));
    }

    function testTrade() external {
        token1.transfer(address(pair), 1000);
        token2.transfer(address(pair), 1000);
        pair.deposit(address(this));
        token1.transfer(address(pair), 500);
        pair.trade(500, true, address(this));
        assertEq(token2.balanceOf(address(this)), 1333);
    }
}
