//SPDX-LICENSE-IDENTIFIER: MIT
pragma solidity ^0.8.18;
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import "lib/chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { Script } from "forge-std/Script.sol";
import { ERC20Mock } from "../test/mocks/ERC20Mock.sol";

contract HelperConfig is Script{

    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2000e8;
    int256 public constant BTC_USD_PRICE = 1000e8;
    uint256 private Default_Private_Key = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    // private key is not an address

    struct NetworkConfig {
        address Weth;
        address Wbtc;
        address PriceFeedWeth;
        address PriceFeedWbtc;
        uint256 deployerKey;
    }
    NetworkConfig public ActiveNetworkConfig;

    constructor(){
        if(block.chainid == 11155111){
            ActiveNetworkConfig = getSepoliaConfig();
        }
        else {
            ActiveNetworkConfig = AnvilConfig();
        }
    }
    function getSepoliaConfig() public returns (NetworkConfig memory sepoliaNetworkConfig){ 
        sepoliaNetworkConfig = NetworkConfig({
            Weth:0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            Wbtc: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            PriceFeedWeth:0x694AA1769357215DE4FAC081bf1f309aDC325306,
            PriceFeedWbtc:0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            deployerKey:vm.envUint("private_key")
            // vm.envUint() is a cheatcode to get the key saved in the .env file
    });
    }
    function AnvilConfig() public returns(NetworkConfig memory){
        if(ActiveNetworkConfig.PriceFeedWbtc != address(0)){
            return ActiveNetworkConfig;
           // First time you call the function: ActiveNetworkConfig.PriceFeedWbtc == address(0)
//-> It runs the full setup (mock price feeds, ERC20 mocks, and assigns to ActiveNetworkConfig).

// ->Second time you call it: ActiveNetworkConfig.PriceFeedWbtc != address(0)
// It immediately returns the existing config and skips redeploying everything.
// First time function called ==0, skip function deploy the lower contracts
// second time called value !=0, it will return the value which was last return after deploying!

            vm.startBroadcast();
             MockV3Aggregator EthPrice = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
             MockV3Aggregator WthPrice = new MockV3Aggregator(DECIMALS, BTC_USD_PRICE);
             ERC20Mock Weth = new ERC20Mock("WETH", "WETH", msg.sender, 1000e8);
             ERC20Mock Wbtc = new ERC20Mock("WETH", "WETH", msg.sender, 1000e8);
             vm.stopBroadcast();
             ActiveNetworkConfig = NetworkConfig({
            Weth:address(Weth),
            Wbtc: address(Wbtc),
            PriceFeedWeth:address(EthPrice),
            PriceFeedWbtc:address(WthPrice),
            deployerKey:Default_Private_Key
                         });                
        }
    }
}