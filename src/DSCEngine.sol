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

pragma solidity ^0.8.30;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { DecentralizedStableCoin } from "./DecentralizedStableCoin.sol";


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

    mapping(address tokenAddr => address priceFeedAddr) public priceAddress;
    mapping(address => mapping(address => uint256)) public collateralBalances;
    // This mapping going to hold the data, the user entry address, the tokenAddress chosed & the amount given!

    address[] public tokenContractAddress;
    DecentralizedStableCoin public i_DSC;
    // imported contract can act as a dataType if used!

    //////////////////////////
    /////////EVENTS///////////
    ////////////////////////// 
    event collateralDeposited(address indexed user , address indexed s_tokenAddress, uint256 indexed s_amount);
     
    //////////////////////////
    /////////Modifier/////////
    ////////////////////////// 

  
    modifier moreThanZero(uint256 amount){
      if(amount == 0){
        revert GiveMoreThanZero();
      }
      _;
    }
    
    modifier tokenAllowed(address tokenAddress){
      if(tokenAddress == address(0)){
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
   
    function depositCollateral(address tokenAddress, uint256 amount) external tokenAllowed(tokenAddress) nonReentrant() moreThanZero(amount)  {

      collateralBalances[msg.sender][tokenAddress] += amount;
      // collateralBalances, this mapping gonna store the user who deposited what amount of collateral
      // whenever I use to check, I just gonna enter the user & Token Address will get the amount deposited!
      (bool success) = IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
      // We use the IERC20 interface to interact with external ERC20 token contracts.
// It allows us to call standard ERC20 functions like transfer, approve, and transferFrom
// without needing the full implementation code. This is useful when dealing with already
// deployed tokens like DAI, USDC, or any custom ERC20 token.
// IERC20 only defines the function signatures (not the logic) — think of it as a remote control.
//  IERC20 only can be used to interact(call), but in ERC20 we can call & make changes to code

      if(!success){
        revert DSCEngine__TransferFailed(); 
      }
      emit collateralDeposited(msg.sender, tokenAddress, amount);
  

    }

   }

