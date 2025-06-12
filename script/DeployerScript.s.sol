//SPDX-LICENSE-IDENTIFIER: MIT
pragma solidity ^0.8.18;

import {DSCEngine} from "../src/DSCEngine.sol";
import {Script} from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.s.sol";
import {DecentralizedStableCoin } from "../src/DecentralizedStableCoin.sol";

contract DeplyerScript is Script{

    address[] public _tokenAddresses;
    address[] public _priceFeed;

    function run() public returns(HelperConfig, DSCEngine, DecentralizedStableCoin){
        // Contracts acting as a datatype
    HelperConfig config = new HelperConfig();
    (address Weth,address Wbtc, address PriceFeedWeth, address PriceFeedWbtc, uint256 deployerKey) 
    = config.ActiveNetworkConfig();
    _tokenAddresses = (address Weth,address Wbtc);
    _priceFeed = (address PriceFeedWeth, address PriceFeedWbtc);

    vm.startBroadcast(uint256 deployerKey);
    // No need to pass the private key,
    // Here only pass if you dont give the key in the forge deployment command! 
    DecentralizedStableCoin DStablecoin = new DecentralizedStableCoin(msg.sender);
    DSCEngine DebtCoin = new DSCEngine(_tokenAddresses, _priceFeed, address(DStablecoin));
    DStablecoin.transferOwnership(address(DebtCoin));
    // transferOwnership is a function used to give owner rights to another contract,
    // like, one src file giving to another contarct to control and call functions
    // It's beacuse the contract is Ownable only be called by the owner, here passing the right 
    // So, another contract can act as a owner & call the functions 
    vm.stopBroadcast();
    return (config, DebtCoin, DStablecoin);
    }




}