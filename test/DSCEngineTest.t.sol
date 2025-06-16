//SPDX-LICENSE-IDENTIFIER: MIT
pragma solidity ^0.8.18;

import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {Test, Console} from "lib/forge-std/src/Test.sol";
import {DeployerScript} from "../../script/DeployerScript.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import { ERC20Mock } from "../test/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
// StdCheats get already get imported when i import test file, no need to import this if you want you can!

//No — it does not make any difference if you import StdCheats.sol explicitly as long as 
// you're already importing and inheriting from forge-std/Test.sol.

contract DSCEngineTest is Test{
    DecentralizedStableCoin DSC; 
    DSCEngine DSCE;
    HelperConfig HConfig;
    DeployerScript DScript;
    address Weth;
    address Wbtc;
    address PriceFeedWeth;
    address PriceFeedWbtc;
    address bob = makeAddr("bob");
    ERC20Mock WEthPriceFeed;
    ERC20Mock WBtcPriceFeed;


    function setUp() external{
        DScript = new DeployerScript();
        (HConfig, DSC, DSCE) = DScript.run();
        (Weth, Wbtc, PriceFeedWeth, PriceFeedWbtc) = HConfig.ActiveNetworkConfig();
        vm.deal(bob, 100 ether);

        WEthPriceFeed = ERC20Mock(Weth);
        WBtcPriceFeed = ERC20Mock(Wbtc);

        WEthPriceFeed.mint(msg.sender, 100 ether);
        WBtcPriceFeed.mint(msg.sender, 100 ether);
    }
// For constructor checking i have taken their variables (param)
    address[] memory tokenAddresses;
    address[] memory priceFeedAddress;

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() external{
        tokenAddresses.push(Weth, Wbtc);
        priceFeedAddress.push(PriceFeedWeth, PriceFeedWbtc);
        vm.expectRevert(DSCEngine.InvalidLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddress);
    }

function getUsdPrice() public {
    uint256 price = DSCE.getUsdSum(Weth,10 ether);
    assert(price == 20000);
// In testing even i need to use how many tokens Weth user has, i cant give weth,so instead in testing i will pass eth!

}
        

}