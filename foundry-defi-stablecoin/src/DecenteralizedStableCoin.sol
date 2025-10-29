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
// view & pure functions

pragma solidity ^0.8.18;
import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extentions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DecenteralizedStableCoin is ERC20Burnable {
    error DecenteralizedStableCoin__MustBeMoreThanZero();
    error DecenteralizedStableCoin__BurnAmountExceedsBalance();
    error DecenteralizedStableCoin__NotZeroAddress();

    constructor() ERC20("DecenteralizedStableCoin", "DSC") Ownable {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);

        if (_amount <= 0) {
            revert DecenteralizedStableCoin__MustBeMoreThanZero();
        }

        if (balance < _amount) {
            revert DecenteralizedStableCoin__BurnAmountExceedsBalance();
        }

        super.burn(_amount); //super means go to super class and call that function

        function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
            if (_to == address(0)) {
                revert DecenteralizedStableCoin__NotZeroAddress()
            }

            if(_amount <= 0) {
                revert DecenteralizedStableCoin__MustBeMoreThanZero();
            }

            _mint(_to, _amount);

            return true;
        }
    }
}
