//SPDX-LICENSE-IDENTIFIER: MIT
pragma solidity ^0.8.18;

import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {Test} from "forge-std/Test.sol";
import {DeployerScript} from "../../script/DeployerScript.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import { ERC20Mock } from "./mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract StopOnRevertHandler is Test {
    Helperconfig Hc;
    Decentralizedstablecoin Dsc;
    Dscengine Dsce;
  //  address weth;
  // OR
  ERC20Mock weth;
  ERC20Mock wbtc;
  address[] testCollateralDepositer;
  MockV3Aggregator PricefeedEth;
  MockV3Aggregator PricefeedBtc;

// address wbtc;

// Here you see I deployed the same contract with its address, deploying it again I used the deployed address when it was deployed,
// so not used new, deployed because the variable here gonna hold the data of lastly deployed address and we can call function 
// & it will respond with valid input as it is deployed and values received 
// same goes with if I one contract need to interact with another contract not the On-chain contract they were already deployed like ERC20
// We be able to call the function based on this particular token I made

    constructor(address helperconfig, address decentralizedstablecoin, address dscengine ) {
        helperconfig = Helperconfig(Hc);
        decentralizedstablecoin = Decentralizedstablecoin(Dsc);
        dscengine = Dscengine(Dsce);

       address[] TokenAddresses = Dsce.getCollateralTokens();
       weth = ERC20Mock(TokenAddresses[0]);
       wbtc = ERC20Mock(TokenAddresses[1]);
       // I know when i deploy with the address, variable will get access to all the functions of this contract related to this token address
       PricefeedEth =  MockV3Aggregator(getCollateralTokenPriceFeed(address(weth)));
       PricefeedBtc =  MockV3Aggregator(getCollateralTokenPriceFeed(address(wbtc)));
       // Here, I had the plain priceFeed & Token Address I converted it into of MockV3, as the token my contract got was of anvil, if testing was going through mainnet,
      // I would be using the same token and allowing IERC20 not ERC20MOCK, as mock is contract and inherited the ERC20, which is abstract and use ERC20 function to allow and mint, 
      // IERC20 function only can be called it's a part of ERC20, unlike ERC20 function can be called & modify, when i allowing through ERC20MOCK, witht the help of ERC20,  
      // IERC20, also gets the token from the ERC20, as it is a part of it, then finally my contract can transfer.
      // If I be using anvil chain, need to use the token as mock, also need to mint to increase its balance, unlike vm.deal, I was using here I here to use minting because vm.deal,
      // can only be able to add ETH, after minting I can allow and contract can transfer.
      // If I use Mainnet collateral token, I cant mint as it is a mainnet token, I will allow IERC20(toke_Name), by casting and call the allow function, and then transfer,
      // In mainnet my metamask will transfer the tokens, when I use forge test, I choose etherum mainnet url or any other mainnet, & also the private key of my metamask,
      // Here, my metamask will sign-off the transaction and pay for my tokens collateral tokens, same goes with chainlink, it use link token to pay for the subscription,
      // When I test I pay tokens by the same method.
      // In only fuzzing testing we have param in the function to get the input from stateful fuzzing, foundry.



    }
    /////////////////////////////////////////
    /////////Collateral deposit test/////////
    /////////////////////////////////////////

    function testCollateralDeposit(uint256 SeedNumber, uint256 amount) public {
        ERC20Mock DepositAddress = getMyAddress(SeedNumber);
        amount = bound(amount, 1, 1000);
        vm.startPrank(msg.sender);
        DepositAddress.mint(msg.sender, amount);
        DepositAddress.approve(address(Dsce), amount);
        console.log(address(DepositAddress));
        Dsce.depositCollateral(address(DepositAddress), amount);
          testCollateralDepositer.push(msg.sender);
        vm.stopPrank();
      
        // In calling a function we dont give dataTypes
        // we cant give address, we can  give the address!
    }
    /////////////////////////////////////////
    /////////Minting tokens test/////////////
    /////////////////////////////////////////
    function testMyMintingCheck(uint256 numberOfTokenToMint, uint256 SeedNumber) external{
       address user = testCollateralDepositer[SeedNumber % testCollateralDepositer.length];
        vm.startPrank(user);
        (, uint256 totalCollateralValueInUsd) = Dsce._getAccountInformation(msg.sender);
        uint256 finalValue = (totalCollateralValueInUsd * 70)/ 100 ;
       numberOfTokenToMint = bound(numberOfTokenToMint, 1, finalValue);
        Dsce.mintDSC(numberOfTokenToMint);
        vm.stopPrank();
    }

    /////////////////////////////////////////
    /////////Redeem collateral test//////////
    /////////////////////////////////////////

    function testRedeemCollateral(uint256 SeedNumber, uint256 amount_to_redeem) external{
         ERC20Mock DepositAddress = getMyAddress(SeedNumber);
         vm.prank(msg.sender);
        uint256 collateralbalance = Dsce.checkBalance(msg.sender, address(DepositAddress));
        amount_to_redeem = bound(amount_to_redeem, 0, collateralbalance);
        if(amount_to_redeem == 0){
            return;
        }
        Dsce.redeemCollateral(address(DepositAddress), amount_to_redeem);
    }

    /////////////////////////////////////////
    /////////Burn Tokens test////////////////
    /////////////////////////////////////////

    function testCheckBurningTokens(uint256 tokensToBurn) external{

        vm.prank(msg.sender);
        uint256 MintedTokenBalance = mintedTokens(msg.sender);
        tokensToBurn = bound(tokensToBurn, 1, MintedTokenBalance);
        MYDSC.approve(address(dsc), tokensToBurn);
        // check your dsc contract you will find the ERC20 Token named as MYDSC, is the reason i used this, dont confuse
        burnDSC(tokensToBurn);

    }
    /////////////////////////////////////////
    //////Update Collateral price test/////// 
    /////////////////////////////////////////

    function getMyAddress(uint256 number) internal view returns (ERC20Mock) {
        if(number%2 == 0){
            return weth;
        }
        else{
            return wbtc;
        }
    }
}
