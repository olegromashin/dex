// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20WithMinter is ERC20 {
    address public owner;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        owner = msg.sender;
    }

    function mint(address account, uint256 amount) external {
        require(msg.sender == owner, "Access denied.");
        _mint(account, amount);
    }
}
