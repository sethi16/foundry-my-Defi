//SPDX-LICENSE-IDENTIFIER:MIT
pragma solidity ^0.8.18;

import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {Test} from "lib/forge-std/src/Test.sol";
import {DeployerScript} from "../../script/DeployerScript.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";
import {StopOnRevertHandler} from "./StopOnRevertHandler.t.sol";

// StdVariant is the contract, which have targetContract for allowing fuzzing!

contract StopOnRevertIvaraint is Test, StdInvariant{
    // Variable holds the data when it was lastly deployed
    DSCEngine DSCE;
    DecentralizedStableCoin DSC;
    HelperConfig HC;

    function setUp(){
        DeployerScript Deployer = new DeployerScript();
        (HC, DSC, DSCE) = Deployer.run();
        ( address Weth, address Wbtc, address PriceFeedWeth, address PriceFeedWbtc,) = HC.ActiveNetworkConfig();

        StopOnRevertHandler handler = new StopOnRevertHandler(HC, DSC, DSCE);
        targetContract(address(handler));

    }


}
