// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {MerkleAirdrop} from "../src/MerkleAridrop.sol";

contract Interact is Script {
    /////////////////////////////////
    //           ERRORS            //
    /////////////////////////////////
    error Interact__ClaimAirdrop__InvalidSignatureLength();

    /////////////////////////////////
    //           VARIABLES         //
    /////////////////////////////////
    address public constant CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 public constant AMOUNT = 25 * 1e18;

    bytes32 PROOF1 = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 PROOF2 = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public MERKLE_PROOF = [PROOF1, PROOF2];

    bytes private SIGNATURE =
        hex"fbd2270e6f23fb5fe9248480c0f4be8a4e9bd77c3ad0b1333cc60b5debc511602a2a06c24085d8d7c038bad84edc53664c8ce0346caeaa3570afec0e61144dc11c";

    function claimAirdrop(address merkleAirdropAddress) public {
        vm.startBroadcast();
        (uint8 V, bytes32 R, bytes32 S) = splitSignature(SIGNATURE);
        MerkleAirdrop(merkleAirdropAddress).claim(CLAIMING_ADDRESS, AMOUNT, MERKLE_PROOF, V, R, S);
        vm.stopBroadcast();
    }

    function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (sig.length != 65) {
            revert Interact__ClaimAirdrop__InvalidSignatureLength();
        }
        require(sig.length == 65, "invalid signature length"); // 32 + 32 + 1 = 65

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // Adjust v value if needed
        if (v < 27) {
            v += 27;
        }
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(mostRecentlyDeployed);
    }
}
