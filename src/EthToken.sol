// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./EthPair.sol";

contract TokenTokenPair is EthPair {
    Erc20 public override token;
    uint256 lastTransactionEthBalance = 0;
    uint256 lastTransactionTokenBalance = 0;
    mapping(address => uint256) public poolTokenBalances;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 public poolTokenTotalSupply = 0;
    uint256 public constant feeRate = 30; // 0.3% 
    uint256 internal constant feeDecimals = 10000;

    event Approval(address indexed from, address indexed spender, uint amount);
    event Transfer(address indexed from, address indexed to, uint amount);

    constructor(address tokenAddress) {
        token = Erc20(tokenAddress);
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

    function ethBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function tokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function calculateTrade(uint256 amount, bool firstToSecond) external view override returns (uint256) {
        require(lastTransactionEthBalance > 0 && lastTransactionTokenBalance > 0, "Liquidity pool is empty.");
        uint256 invariant = calculateInvariant();
        uint256 fee = calculateFee(firstToSecond);
        if (firstToSecond)
            return lastTransactionTokenBalance - (invariant / (ethBalance() + amount)) - fee;
        else
            return lastTransactionEthBalance - (invariant / (tokenBalance() + amount)) - fee;
    }

    function trade(uint256 amount, bool firstToSecond, address beneficiar) external override {
        require(lastTransactionEthBalance > 0 && lastTransactionTokenBalance > 0, "Liquidity pool is empty.");
        uint256 invariant = calculateInvariant();
        uint256 fee = calculateFee(firstToSecond);
        if (firstToSecond) {
            require(ethBalance() == lastTransactionEthBalance + amount, "Didn't recieve source token for trade.");
            uint256 mustPay = lastTransactionTokenBalance - (invariant / ethBalance()) - fee;
            require(tokenBalance() > mustPay, "Pool doesn't have enough destination token funds.");
            token.transfer(beneficiar, mustPay);
        }
        else {
            require(tokenBalance() == lastTransactionTokenBalance + amount, "Didn't recieve source token for trade.");
            uint256 mustPay = lastTransactionEthBalance - (invariant / tokenBalance()) - fee;
            require(ethBalance() > mustPay, "Pool doesn't have enough destination token funds.");
            (bool sent, ) = beneficiar.call{value: mustPay}("");
            require(sent, "Failed to send Ether");
        }
        lastTransactionEthBalance = ethBalance();
        lastTransactionTokenBalance = tokenBalance();
    }

    function calculateInvariant() internal view returns (uint256) {
        return lastTransactionEthBalance * lastTransactionTokenBalance;
    }

    function calculateFee(bool firstToSecond) internal view returns (uint256) {
        if (firstToSecond)
            return (ethBalance() - lastTransactionEthBalance) * feeRate / feeDecimals;
        else
            return (tokenBalance() - lastTransactionTokenBalance) * feeRate / feeDecimals;
    }

    function deposit(address depositor) external override {
        uint256 ethDepositAmount = ethBalance() - lastTransactionEthBalance;
        uint256 tokenDepositAmount = tokenBalance() - lastTransactionTokenBalance;
        require(ethDepositAmount > 0 && tokenDepositAmount > 0, "You have to send both tokens to make deposit.");
        if (lastTransactionEthBalance == 0) {
            firstTimeDeposit(depositor);
        }
        else {
            uint256 outputPoolToken;
            if (lastTransactionEthBalance > lastTransactionTokenBalance) {
                uint256 poolRatio = lastTransactionEthBalance / lastTransactionTokenBalance;
                uint256 userRatio = ethDepositAmount / tokenDepositAmount;
                if (poolRatio < userRatio) {
                    outputPoolToken = sqrt((tokenDepositAmount * poolRatio) * tokenDepositAmount);
                } else {
                    outputPoolToken = sqrt(ethDepositAmount * tokenDepositAmount);
                }
            } else {
                uint256 poolRatio = lastTransactionTokenBalance / lastTransactionEthBalance;
                uint256 userRatio = tokenDepositAmount / ethDepositAmount;
                if (poolRatio < userRatio) {
                    outputPoolToken = sqrt(ethDepositAmount * (ethDepositAmount * poolRatio));
                } else {
                    outputPoolToken = sqrt(ethDepositAmount * tokenDepositAmount);
                }
            }
            poolTokenBalances[depositor] += outputPoolToken;
            poolTokenTotalSupply += outputPoolToken;
        }
        lastTransactionEthBalance = ethBalance();
        lastTransactionTokenBalance = tokenBalance();
    }

    function firstTimeDeposit(address depositor) internal {
        uint256 ethDepositAmount = ethBalance();
        uint256 tokenDepositAmount = tokenBalance();
        require(ethDepositAmount > 0 && tokenDepositAmount > 0, "You have to send both tokens to make deposit.");
        uint256 outputPoolToken = sqrt(ethDepositAmount * tokenDepositAmount);
        poolTokenBalances[depositor] += outputPoolToken;
        poolTokenTotalSupply += outputPoolToken;
    }

    function withdrawDeposit() external {
        require(poolTokenBalances[msg.sender] > 0, "You don't have pool tokens to withdraw.");
        uint ethWithdrawAmount = poolTokenBalances[msg.sender] * poolTokenBalances[msg.sender] / tokenBalance();
        uint tokenWithdrawAmount = poolTokenBalances[msg.sender] * poolTokenBalances[msg.sender] / ethBalance();
        poolTokenTotalSupply -= poolTokenBalances[msg.sender];
        poolTokenBalances[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: ethWithdrawAmount}("");
        require(sent, "Failed to send Ether");
        token.transfer(msg.sender, tokenWithdrawAmount);
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
