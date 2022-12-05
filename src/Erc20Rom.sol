// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Erc20.sol";

contract RomToken is Erc20 {
    uint256 public totalSupply = 0;
    address private minter;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    string public constant name = "Romashin Token";
    string public constant symbol = "ROM";
    uint8 public constant decimals = 10;

    event Approval(address indexed from, address indexed spender, uint amount);
    event Transfer(address indexed from, address indexed to, uint amount);

    constructor() {
        minter = msg.sender;
    }

    function mint(uint amount, address benefeciar) public returns(uint256) {
        assert(msg.sender == minter);
        totalSupply += amount;
        balances[benefeciar] += amount;
        return totalSupply;
    }

    function balanceOf(address tokenOwner) public view override returns(uint256) {
        return balances[tokenOwner];
    }

    function allowance(address from, address spender) public view returns(uint256) {
        return allowed[from][spender];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        uint256 senderBalance = balances[msg.sender];
        if (senderBalance < amount)
            return false;
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        if (balances[msg.sender] < amount)
            return false;
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address spender, uint256 amount) public override returns (bool) {
        if (balances[from] < amount || allowed[from][spender] < amount)
            return false;
        allowed[from][spender] -= amount;
        balances[msg.sender] -= amount;
        balances[spender] += amount;
        emit Transfer(msg.sender, spender, amount);
        return true;
    }
}
