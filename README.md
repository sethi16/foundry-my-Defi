Whole Understanding of the contract:
1. Relative Stability: Anchored or Pegged -> $1.00
   1. ChainLink priceFeed.
   2. Set a function to exhange ETH & BTC->$$
2. Stability mechanism (Minting): Algorithmic (Decentralized)
   1. people can only mint stablecoin with enough collaternal
3. Collateral: Exogenous (Crypto)
   1. wETH
   2. wBTC (Both are of ERC20) w means wrapped!

Usage
Start a local node
make anvil
Deploy
This will default to your local node. You need to have it running in another terminal in order for it to deploy.

make deploy
Deploy - Other Network
See below

Testing
We talk about 4 test tiers in the video.

Unit
Integration
Forked
Staging
In this repo we cover #1 and Fuzzing.

forge test
Test Coverage
forge coverage
and for coverage based testing:

forge coverage --report debug
Deployment to a testnet or mainnet
Setup environment variables
You'll want to set your SEPOLIA_RPC_URL and PRIVATE_KEY as environment variables. You can add them to a .env file, similar to what you see in .env.example.

PRIVATE_KEY: The private key of your account (like from metamask). NOTE: FOR DEVELOPMENT, PLEASE USE A KEY THAT DOESN'T HAVE ANY REAL FUNDS ASSOCIATED WITH IT.
You can learn how to export it here.
SEPOLIA_RPC_URL: This is url of the sepolia testnet node you're working with. You can get setup with one for free from Alchemy
Optionally, add your ETHERSCAN_API_KEY if you want to verify your contract on Etherscan.

Get testnet ETH
Head over to faucets.chain.link and get some testnet ETH. You should see the ETH show up in your metamask.

Deploy
make deploy ARGS="--network sepolia"
Scripts
Instead of scripts, we can directly use the cast command to interact with the contract.

For example, on Sepolia:

Get some WETH
cast send 0xdd13E55209Fd76AfE204dBda4007C227904f0a81 "deposit()" --value 0.1ether --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
Approve the WETH
cast send 0xdd13E55209Fd76AfE204dBda4007C227904f0a81 "approve(address,uint256)" 0x091EA0838eBD5b7ddA2F2A641B068d6D59639b98 1000000000000000000 --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
Deposit and Mint DSC
cast send 0x091EA0838eBD5b7ddA2F2A641B068d6D59639b98 "depositCollateralAndMintDsc(address,uint256,uint256)" 0xdd13E55209Fd76AfE204dBda4007C227904f0a81 100000000000000000 10000000000000000 --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
