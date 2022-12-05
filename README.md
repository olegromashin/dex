# Decentralized exchange for Ethereum

## Deployment

Used [Foundry](https://book.getfoundry.sh/) for testing and deployment script.
To run deploy script:

1. Make a copy of `.env-template` and rename it into `.env`.

2. Fill `.env` file.

3. Run `forge script script/Deploy.s.sol:DeployScript --rpc-url $GOERLI_RPC_URL --broadcast --verify -vvvv`

## TODO

1. More tests.

2. Use SafeMath.

3. Rewise naming.

4. Refactoring.
