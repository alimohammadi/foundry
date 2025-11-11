// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {MerkleAirdrop} from "../src/MerkleAridrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {Script} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirdrop is Script {
    // merkle root generated from the input.json file
    bytes32 public constant MERKLE_ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    address public constant BAGEL_TOKEN_ADDRESS = 0x7fcDE2a6A3F3B25CFe2B6CC1c8a8D2e0A5d9e9B3; // replace with deployed BagelToken address
    uint256 public constant AMOUNT_TO_AIRDROP = 25 * 1e18 * 4;

    function deployMerkleAirdrop() public returns (MerkleAirdrop, BagelToken) {
        vm.startBroadcast();
        BagelToken token = new BagelToken();

        MerkleAirdrop merkleAirdrop = new MerkleAirdrop(MERKLE_ROOT, IERC20(address(token)));
        token.mint(token.owner(), AMOUNT_TO_AIRDROP);
        token.transfer(address(merkleAirdrop), AMOUNT_TO_AIRDROP);
        vm.stopBroadcast();
        return (merkleAirdrop, token);
    }

    function run() external returns (MerkleAirdrop, BagelToken) {
        // IERC20 airdropToken = IERC20(BAGEL_TOKEN_ADDRESS);

        // vm.startBroadcast();
        // MerkleAirdrop merkleAirdrop = new MerkleAirdrop(MERKLE_ROOT, airdropToken);
        // vm.stopBroadcast();

        // console.log("MerkleAirdrop deployed at:", address(merkleAirdrop));
        return deployMerkleAirdrop();
    }
}

