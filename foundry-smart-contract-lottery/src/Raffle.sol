// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Raffle {
    uint256 private immutable i_enteranceFee;

    constructor(uint256 enteranceFee) {
        i_enteranceFee = enteranceFee;
    }

    function enterRaffle() public payable {}

    function pickWinner() public {}

    /* Getter functions */
    function getEnteranceFee() external view returns (uint256) {
        return i_enteranceFee;
    }
}
