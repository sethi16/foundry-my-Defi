// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { DecentralizedStableCoin } from "./DecentralizedStableCoin.sol";
import "lib/chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";




// IMP, make notes also of the quizs especially of DEFI!
// endogenous & exogenous, types of testing unit, intregation!
/*
 * @title DSCEngine
 * @author Sarthak Sethi
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg at all times.
 * This is a stablecoin with the properties:
 * - Exogenously Collateralized
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * It is similar to DAI(Decentralized stablecoin) if DAI had no governance, no fees, and was backed by only WETH and WBTC.
 *
 * Our DSC system should always be "overcollateralized". At no point, should the value of
 * all collateral < the $ backed value of all the DSC(Debt StableCoin).
 *
 * @notice This contract is the core of the Decentralized Stablecoin system. It handles all the logic
 * for minting and redeeming DSC, as well as depositing and withdrawing collateral.
 * @notice This contract is based on the MakerDAO DSS  system
 */
   contract DSCEngine is ReentrancyGuard {
    
    error GiveMoreThanZero();
    error tokenNotAllowed();
    error InvalidLength();
    error DSCEngine__TransferFailed();
    error healthIssue(uint256 healthValue);
    error NotMinted();
    error CollateralNotRedeemed();
    error NotSuccedInBuring();
    error NotAbleToLiquidate();
    error NotSuccedInLiquidation();
    error Health_Factor_Not_Improved();

    mapping(address tokenAddr => address priceFeedAddr) public priceAddress;
    mapping(address  => mapping(address  => uint256 )) public collateralBalances;
    mapping(address => uint256) public D_minted;
    // This mapping going to hold the data, the user entry address, the tokenAddress chosed & the amount given!

    address[] public tokenContractAddress;
    DecentralizedStableCoin public i_DSC;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // This means you need to be 200% over-collateralized
    uint256 private constant LIQUIDATION_BONUS = 10; // This means you get assets at a 10% discount when liquidating
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant FEED_PRECISION = 1e8;
    // imported contract can act as a dataType if used!

    //////////////////////////
    /////////EVENTS///////////
    ////////////////////////// 
    event collateralDeposited(address indexed user , address indexed s_tokenAddress, uint256 indexed s_amount);
    event CollateralReciever(address indexed caller, address indexed token_Address, uint256 indexed amount_To_Be_Called);
    event DebtBurner(address indexed _caller, uint256 indexed amount_to_be_burned);
     
    //////////////////////////
    /////////Modifier/////////
    ////////////////////////// 

  
    modifier moreThanZero(uint256 checking_amount){
      if(checking_amount == 0){
        revert GiveMoreThanZero();
      }
      _;
    }
    
    modifier tokenAllowed(address checking_tokenAddress){
      if(checking_tokenAddress == address(0)){
        revert tokenNotAllowed();
      }
      _;
    }
    // We take the deployed DecentralizedStableCoin (DSC) contract address as input in the constructor.
// Then, we use that address to create a reference to the DSC contract using its interface.
// This allows us to work with the existing deployed DSC contract funtions when it was last deployed(e.g., call mint, burn, etc.)

     constructor(address[] memory tokenAddresses, address[] memory priceFeedAddress, address DSCAddress){
      if(tokenAddresses.length != priceFeedAddress.length){
        revert InvalidLength();
      }
      for ( uint256 i= 0; i< tokenAddresses.length; i++){
        priceAddress[tokenAddresses[i]] = priceFeedAddress[i];
        // mapping is for storage, includes key & values
        tokenContractAddress.push(tokenAddresses[i]);
      } 
      i_DSC = DecentralizedStableCoin(DSCAddress);
    }
    // // Prevents reentrancy attacks by ensuring the function cannot be re-entered while it's still executing.
// Requires inheriting from OpenZeppelin's ReentrancyGuard and using the `nonReentrant` modifier.
// reentrancy is a state in which a user withdraw the asset & without updating the balance calls it again to get the asset
// reentrancy stops the user to enter the function without completing the function
 
   
    function depositCollateral(address tokenAddress, uint256 amount) public tokenAllowed(tokenAddress) nonReentrant() moreThanZero(amount)  {

      collateralBalances[msg.sender][tokenAddress] += amount;
      // collateralBalances, this mapping gonna store the user who deposited what amount of collateral
      // whenever I use to check, I just gonna enter the user & Token Address will get the amount deposited!
      (bool success) = IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
      /* We use the IERC20 interface to interact with external ERC20 token contracts.
// It allows us to call standard ERC20 functions like transfer, approve, and transferFrom
// without needing the full implementation code. This is useful when dealing with already
// deployed tokens like DAI, USDC, or any custom ERC20 token.
// IERC20 only defines the function signatures (not the logic) — think of it as a remote control.
//  IERC20 only can be used to interact(call), but in ERC20 we can call & make changes to code
*/
      if(!success){
        revert DSCEngine__TransferFailed(); 
      }
      emit collateralDeposited(msg.sender, tokenAddress, amount);
    }

    function mintDSC(uint256 _amount) public {
      D_minted[msg.sender] += _amount;
      revertIfHealthFactorIsBroken(msg.sender); // if i<1;
     (bool success) = i_DSC.mint(msg.sender ,_amount);
     if(!success){
      revert NotMinted();
     }

    }
    function revertIfHealthFactorIsBroken(address) public returns(uint256){
      _healthFactor(msg.sender); // check for i & emit value liq value
      uint256 healthyValue;
      if(healthyValue < 1){
        revert healthIssue(healthyValue);
      }

    }
    function _healthFactor(address) public returns(uint256) {
      (uint256 minted_value, uint256 totalCollateralValueInUsd) = _getAccountInformation(msg.sender);
       // real value of emit & i
       return _calculateHealthFactor( minted_value, totalCollateralValueInUsd);
     
    }
    function _calculateHealthFactor(uint256 minted_value, uint256 totalCollateralValueInUsd) public pure returns(uint256){
       if (minted_value == 0) 
       return type(uint256).max;
       uint256 liqCollateralValue =  (totalCollateralValueInUsd *LIQUIDATION_THRESHOLD) /LIQUIDATION_PRECISION;
      uint256 healthyValue =  liqCollateralValue / minted_value;
      return healthyValue;
    }

    function _getAccountInformation(address) public returns(uint256 minted_value, uint256 collateralValue){
      minted_value = D_minted[msg.sender];
      collateralValue = getAccountCollateralValue(msg.sender);
      // it calculates the value of i & emit
    }
    function getAccountCollateralValue(address) public returns(uint256){
      uint256 totalCollateralValueInUsd = 0;
      for(uint256 index = 0; index < tokenContractAddress.length; index++){
        address token = tokenContractAddress[index];
        uint256 tokenBalance = collateralBalances[msg.sender][token];
        totalCollateralValueInUsd += getUsdValue(token, tokenBalance);
      }
      return totalCollateralValueInUsd ;
    }

    function getUsdValue(address token, uint256 tokenBalance) public returns(uint256 ){
      uint256 usdValue = getUsdSum(token, tokenBalance);
    }

    function getUsdSum(address token, uint256 tokenBalance) public view returns(uint256 usdValue){
      address priceFeedAddr = priceAddress[token];
      AggregatorV3Interface pricefeed = AggregatorV3Interface(priceFeedAddr);
      (, int256 answer, , , ) = pricefeed.latestRoundData();
      // Assuming price feed returns 8 decimals, scale to 18 decimals
       usdValue = (uint256(answer)*ADDITIONAL_FEED_PRECISION * tokenBalance)/PRECISION  ;
      return usdValue;
    }

    function depositCollateralAndMintDsc(address tokenCollateralAddress,uint256 amountCollateral,uint256 amountDscToMint) public { 
      depositCollateral(tokenCollateralAddress, amountCollateral);
      mintDSC(amountDscToMint);
}
function redeemCollateralforDSC(address _tokenAddress, uint256 amount_to_redeem, uint256 amount_to_be_burned) public 
moreThanZero(amount_to_redeem) tokenAllowed(_tokenAddress){
   burnDSC(amount_to_be_burned);
  redeemCollateral(_tokenAddress, amount_to_redeem);
}
function redeemCollateral(address _tokenAddress, uint256 amount_to_redeem) public {
  uint256 savedBalance = collateralBalances[msg.sender][_tokenAddress];
  collateralBalances[msg.sender][_tokenAddress] = savedBalance - amount_to_redeem;
  // updating the balance
  emit CollateralReciever(msg.sender, _tokenAddress, amount_to_redeem);
  bool success = IERC20(_tokenAddress).transfer(msg.sender, amount_to_redeem);
  if(!success){
    revert CollateralNotRedeemed();
  }
  revertIfHealthFactorIsBroken(msg.sender); 
  // checking the Health factor value is it greater than 1!

}
function burnDSC(uint256 amount_to_be_burned) public{
  uint256 minted_token = D_minted[msg.sender];
  D_minted[msg.sender] =  minted_token - amount_to_be_burned;
  // updating the minted token balance after burning
  emit DebtBurner(msg.sender, amount_to_be_burned);
  bool _success =  i_DSC.transferFrom(msg.sender, address(this), amount_to_be_burned);
  if(!_success){
    revert NotSuccedInBuring();
  }
  i_DSC.burn(amount_to_be_burned);
  revertIfHealthFactorIsBroken(msg.sender); 
  // checking the Health factor value is it greater than 1, if yes redeem the collateral!
}
function liquidation(address _tokenAddress, uint256 amount_to_liquidate, uint256 amount_to_be_burned ) public{
 uint256 starting_Health_Factor = _healthFactor(msg.sender);
 if(starting_Health_Factor >= 1){
  revert NotAbleToLiquidate();
 }
 uint256 current_Collateral_Usd_Value = getUsdValue(_tokenAddress, amount_to_liquidate);
 uint256 current_Collateral_Usd_Liquidatevalue = (current_Collateral_Usd_Value*LIQUIDATION_BONUS)/LIQUIDATION_PRECISION;


  bool success = IERC20(_tokenAddress).transfer(msg.sender, current_Collateral_Usd_Liquidatevalue);
  if(!success){
    revert NotSuccedInLiquidation();
  }

  burnDSC(amount_to_be_burned);

  uint256 ending_Health_Factor_Again = _healthFactor(msg.sender);
  if(starting_Health_Factor >= ending_Health_Factor_Again){
    revert Health_Factor_Not_Improved();
  }
}
   }

