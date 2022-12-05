// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Pair.sol";
import "./Erc20.sol";
import "./Router.sol";

contract DexUser {
    Router router;

    constructor(address routerAddress) {
        router = Router(routerAddress);
    }

    function swap(address pairAddress, bool firstToSecond, uint256 amount) external {
        require(router.pairInstantiated(pairAddress), "This router doesn't work with specified pair address.");
        Pair pair = Pair(pairAddress);
        Erc20 sourcetokenContract = getSourceTokenContract(pair, firstToSecond);
        require(sourcetokenContract.balanceOf(msg.sender) >= amount, "Not enough tokens on your balance to request for swap.");
        sourcetokenContract.transfer(pairAddress, amount);
        router.swap(pairAddress, firstToSecond, amount, msg.sender);
    }

    function calculateTrade(address pairAddress, bool firstToSecond, uint256 amount) external view {
        require(router.pairInstantiated(pairAddress), "This router doesn't work with specified pair address.");
        Pair pair = Pair(pairAddress);
        Erc20 sourcetokenContract = getSourceTokenContract(pair, firstToSecond);
        require(sourcetokenContract.balanceOf(msg.sender) >= amount, "Not enough tokens on your balance to request for calculating trade.");
        router.calculateTrade(pairAddress, firstToSecond, amount);
    }

    function getSourceTokenContract(Pair pair, bool firstToSecond) internal view returns (Erc20) {
        if (firstToSecond)
            return pair.token1();
        else
            return pair.token2();
    }

    function deposit(address pairAddress, uint256 token1Amount, uint256 token2Amount) external {
        require(router.pairInstantiated(pairAddress), "This router doesn't work with specified pair address.");
        Pair pair = Pair(pairAddress);
        Erc20 token1 = pair.token1();
        Erc20 token2 = pair.token2();
        require(token1.balanceOf(msg.sender) >= token1Amount, "Not enough tokens on your token 1 balance to deposit.");
        require(token2.balanceOf(msg.sender) >= token2Amount, "Not enough tokens on your token 2 balance to deposit.");
        token1.transfer(pairAddress, token1Amount);
        token2.transfer(pairAddress, token2Amount);
        router.deposit(pairAddress);
    }
}
