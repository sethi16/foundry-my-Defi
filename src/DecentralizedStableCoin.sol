// SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
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
// view & pure functions4
pragma solidity ^0.8.18;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @title Decentralized Stable Coin
 * @Minting: Algorithmic
 * @Collateral: Exogenous (BTH & ETC)
 * This is a decentralized ERC20 stable coin contract that aims to maintain a stable value through algorithmic mechanisms and collateralization.
 */
 // Here, ERC20Burnable is acting as a child contract of ERC20
 // Means ERC20, all functions & variables of ERC20 are inherited by ERC20Burnable
 // Means, we need to pass values of ERC20 constructor as ERC20Burnable has iherited it
contract DecentralizedStableCoin is ERC20Burnable, Ownable{
    error InsufficientBalance();
    error MustbeGreaterThanZero();
    error AmountCannotBeZero();
    constructor(address initialOwner) ERC20("DecentralizedStabelCoin","DSC") Ownable(initialOwner){
    }
    // abstract function cant be deployed
    // Virtual function means it can be overridden by child contracts
     function burn(uint256 amount) public onlyOwner() override {
        if (balanceOf(msg.sender) < amount) {
            revert InsufficientBalance();
        }
        if (amount == 0) {
            revert MustbeGreaterThanZero();
        }
        super.burn(amount);
        
        //  Not compulsary to write the whole virtual function, could be just called like other functions
        // super keyword is used to call the parent contract's function
        // This allows us to use the burn function from the ERC20Burnable contract
        // Use incase of Calls the parent’s original implementation 
        // In abstract contract even about inheritance we need to call the parent abstract contract's function by super keyword
     }
     // onlyOwner moidifer has been imported from Ownable contract
     function mint(address to, uint256 amount) external onlyOwner() returns(bool) {
        if (to == address(0)){
            revert MustbeGreaterThanZero();
        }
        if(amount == 0){
            revert AmountCannotBeZero();
        }
        _mint(to, amount);
        return true; // bool used to indicate function run success
     }
// Here, the mint function is used rather than _mint function because if we override the _mint function we can not call the _mint function
// SO, we are using the mint function which will become replica of _mint & call the _mint function internally

}