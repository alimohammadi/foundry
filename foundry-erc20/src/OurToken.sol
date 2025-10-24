//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// https://github.com/openzeppelin - OpenZeppelin/openzeppelin-contracts
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OurToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("OurToken", "OTK") {
        _mint(msg.sender, initialSupply);
    }
}
