// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Pair.sol";

contract TokenTokenPair is Pair {
    Erc20 public override token1;
    Erc20 public override token2;
    uint256 lastTransactionToken1Balance = 0;
    uint256 lastTransactionToken2Balance = 0;
    mapping(address => uint256) public poolTokenBalances;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 public poolTokenTotalSupply = 0;
    uint256 public constant feeRate = 30; // 0.3% 
    uint256 internal constant feeDecimals = 10000;

    event Approval(address indexed from, address indexed spender, uint amount);
    event Transfer(address indexed from, address indexed to, uint amount);

    constructor(address token1Address, address token2Address) {
        require(token1Address != token2Address, "Tokens addresses must be different.");
        token1 = Erc20(token1Address);
        token2 = Erc20(token2Address);
    }

    function balanceOf(address tokenOwner) public view override returns(uint256) {
        return poolTokenBalances[tokenOwner];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        uint256 senderBalance = poolTokenBalances[msg.sender];
        if (senderBalance < amount)
            return false;
        poolTokenBalances[msg.sender] -= amount;
        poolTokenBalances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        if (poolTokenBalances[msg.sender] < amount)
            return false;
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address spender, uint256 amount) public override returns (bool) {
        if (poolTokenBalances[from] < amount || allowed[from][spender] < amount)
            return false;
        allowed[from][spender] -= amount;
        poolTokenBalances[msg.sender] -= amount;
        poolTokenBalances[spender] += amount;
        emit Transfer(msg.sender, spender, amount);
        return true;
    }

    function token1Balance() public view returns (uint256) {
        return token1.balanceOf(address(this));
    }

    function token2Balance() public view returns (uint256) {
        return token2.balanceOf(address(this));
    }

    function calculateTrade(uint256 amount, bool firstToSecond) external view override returns (uint256) {
        require(lastTransactionToken1Balance > 0 && lastTransactionToken2Balance > 0, "Liquidity pool is empty.");
        uint256 invariant = calculateInvariant();
        uint256 fee = calculateFee(firstToSecond);
        if (firstToSecond)
            return lastTransactionToken2Balance - (invariant / (token1Balance() + amount)) - fee;
        else
            return lastTransactionToken1Balance - (invariant / (token2Balance() + amount)) - fee;
    }

    function trade(uint256 amount, bool firstToSecond, address beneficiar) external override {
        require(lastTransactionToken1Balance > 0 && lastTransactionToken2Balance > 0, "Liquidity pool is empty.");
        uint256 invariant = calculateInvariant();
        uint256 fee = calculateFee(firstToSecond);
        if (firstToSecond) {
            require(token1Balance() == lastTransactionToken1Balance + amount, "Didn't recieve source token for trade.");
            uint256 mustPay = lastTransactionToken2Balance - (invariant / token1Balance()) - fee;
            require(token2Balance() > mustPay, "Pool doesn't have enough destination token funds.");
            token2.transfer(beneficiar, mustPay);
        }
        else {
            require(token2Balance() == lastTransactionToken2Balance + amount, "Didn't recieve source token for trade.");
            uint256 mustPay = lastTransactionToken1Balance - (invariant / token2Balance()) - fee;
            require(token1Balance() > mustPay, "Pool doesn't have enough destination token funds.");
            token1.transfer(beneficiar, mustPay);
        }
        lastTransactionToken1Balance = token1Balance();
        lastTransactionToken2Balance = token2Balance();
    }

    function calculateInvariant() internal view returns (uint256) {
        return lastTransactionToken1Balance * lastTransactionToken2Balance;
    }

    function calculateFee(bool firstToSecond) internal view returns (uint256) {
        if (firstToSecond)
            return (token1Balance() - lastTransactionToken1Balance) * feeRate / feeDecimals;
        else
            return (token2Balance() - lastTransactionToken2Balance) * feeRate / feeDecimals;
    }

    function deposit(address depositor) external override {
        uint256 token1DepositAmount = token1Balance() - lastTransactionToken1Balance;
        uint256 token2DepositAmount = token2Balance() - lastTransactionToken2Balance;
        require(token1DepositAmount > 0 && token2DepositAmount > 0, "You have to send both tokens to make deposit.");
        if (lastTransactionToken1Balance == 0) {
            firstTimeDeposit(depositor);
        }
        else {
            uint256 outputPoolToken;
            if (lastTransactionToken1Balance > lastTransactionToken2Balance) {
                uint256 poolRatio = lastTransactionToken1Balance / lastTransactionToken2Balance;
                uint256 userRatio = token1DepositAmount / token2DepositAmount;
                if (poolRatio < userRatio) {
                    outputPoolToken = sqrt((token2DepositAmount * poolRatio) * token2DepositAmount);
                } else {
                    outputPoolToken = sqrt(token1DepositAmount * token2DepositAmount);
                }
            } else {
                uint256 poolRatio = lastTransactionToken2Balance / lastTransactionToken1Balance;
                uint256 userRatio = token2DepositAmount / token1DepositAmount;
                if (poolRatio < userRatio) {
                    outputPoolToken = sqrt(token1DepositAmount * (token1DepositAmount * poolRatio));
                } else {
                    outputPoolToken = sqrt(token1DepositAmount * token2DepositAmount);
                }
            }
            poolTokenBalances[depositor] += outputPoolToken;
            poolTokenTotalSupply += outputPoolToken;
        }
        lastTransactionToken1Balance = token1Balance();
        lastTransactionToken2Balance = token2Balance();
    }

    function firstTimeDeposit(address depositor) internal {
        uint256 token1DepositAmount = token1Balance();
        uint256 token2DepositAmount = token2Balance();
        require(token1DepositAmount > 0 && token2DepositAmount > 0, "You have to send both tokens to make deposit.");
        uint256 outputPoolToken = sqrt(token1DepositAmount * token2DepositAmount);
        poolTokenBalances[depositor] += outputPoolToken;
        poolTokenTotalSupply += outputPoolToken;
    }

    function withdrawDeposit() external {
        require(poolTokenBalances[msg.sender] > 0, "You don't have pool tokens to withdraw.");
        uint token1WithdrawAmount = poolTokenBalances[msg.sender] * poolTokenBalances[msg.sender] / token2Balance();
        uint token2WithdrawAmount = poolTokenBalances[msg.sender] * poolTokenBalances[msg.sender] / token1Balance();
        poolTokenTotalSupply -= poolTokenBalances[msg.sender];
        poolTokenBalances[msg.sender] = 0;
        token1.transfer(msg.sender, token1WithdrawAmount);
        token2.transfer(msg.sender, token2WithdrawAmount);
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
