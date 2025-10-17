// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Raffle {
    /**
     * Errors
     */
    error Raffle__SendMoreToEnterRaffle();

    uint256 private immutable i_enteranceFee;
    uint256 private immutable i_interval; // @dev The duration of the lottery in seconds
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;

    /**
     * Events
     */
    event RaffleEntered(address indexed player);

    constructor(uint256 enteranceFee, uint256 interval) {
        i_enteranceFee = enteranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable {
        if (msg.value < i_enteranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }

        s_players.push(payable(msg.sender));

        emit RaffleEntered(msg.sender);
    }

    // 1. Get a random number
    // 2. Use random number to pick a player from the array
    // 3. Be automatically called
    function pickWinner() external {
        // Check to see if enough time has passed
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }

        // Get our random number
    }

    /* Getter functions */
    function getEnteranceFee() external view returns (uint256) {
        return i_enteranceFee;
    }
}
