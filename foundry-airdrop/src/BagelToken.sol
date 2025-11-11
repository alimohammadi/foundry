// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BagelToken is ERC20, Ownable {
    //Ownable(msg.sender) => who ever deploys the contract is the owner
    constructor() ERC20("BagelToken", "BAGEL") Ownable(msg.sender) {
        // _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
