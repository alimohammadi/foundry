// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    /**
     * Errors
     */
    error Raffle__SendMoreToEnterRaffle();

    uint256 private immutable I_ENTERANCE_FEE;
    uint256 private immutable I_INTERVAL; // @dev T he duration of the lottery in seconds
    uint256 private immutable I_SUBSCRIPTION_ID;
    bytes32 private immutable I_KEY_HASH;
    uint32 private immutable I_CALLBACK_GAS_LIMIT;
    address payable[] private sPlayers;
    uint256 private sLastTimeStamp;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint256 private constant ROLL_IN_PROGRESS = 42;
    uint32 private constant NUM_WORDS = 1;

    /**
     * Events
     */
    event RaffleEntered(address indexed player);
    event DiceRolled(uint256 indexed requestId, address indexed roller);

    constructor(
        uint256 enteranceFee,
        uint256 interval,
        address vrfCoordintor,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordintor) {
        I_ENTERANCE_FEE = enteranceFee;
        I_INTERVAL = interval;
        sLastTimeStamp = block.timestamp;
        I_KEY_HASH = gasLane;
        I_SUBSCRIPTION_ID = subscriptionId;
        I_CALLBACK_GAS_LIMIT = callbackGasLimit;
    }

    function enterRaffle() external payable {
        if (msg.value < I_ENTERANCE_FEE) {
            revert Raffle__SendMoreToEnterRaffle();
        }

        sPlayers.push(payable(msg.sender));

        emit RaffleEntered(msg.sender);
    }

    // 1. Get a random number
    // 2. Use random number to pick a player from the array
    // 3. Be automatically called
    function pickWinner() external {
        // Check to see if enough time has passed
        if ((block.timestamp - sLastTimeStamp) < I_INTERVAL) {
            revert();
        }

        // Get our random number 2.5
        // 1. Request RNG
        // 2. Get RNG
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: I_KEY_HASH,
                subId: I_SUBSCRIPTION_ID,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: I_CALLBACK_GAS_LIMIT,
                numWords: NUM_WORDS,
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }
 
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        
    }

    /* Getter functions */
    function getEnteranceFee() external view returns (uint256) {
        return I_ENTERANCE_FEE;
    }
}
