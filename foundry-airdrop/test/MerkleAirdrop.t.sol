// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAridrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";

contract MerkleAirdropTest is ZkSyncChainChecker, Test {
    MerkleAirdrop public merkleAirdrop;
    BagelToken public token;

    bytes32 public constant MERKLE_ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 public constant AMOUNT_TO_CLAIM = 25 * 1e18;
    uint256 public constant AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;

    bytes32 proof1 = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proof2 = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;

    bytes32[] public PROOF = [proof1, proof2];

    address public gasPayer;
    address user;
    uint256 userPrivKey;

    function setUp() public {
        if (!isZkSyncChain()) {
            // deploy with script
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (merkleAirdrop, token) = deployer.deployMerkleAirdrop();
        } else {
            token = new BagelToken();
            merkleAirdrop = new MerkleAirdrop(MERKLE_ROOT, token);

            token.mint(token.owner(), AMOUNT_TO_SEND);
            token.transfer(address(merkleAirdrop), AMOUNT_TO_SEND);
        }

        (user, userPrivKey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
    }

    function testUsersCanClaim() public {
        // console.log("User address:", user);
        // console.log("User private key:", userPrivKey);

        uint256 startingBalance = token.balanceOf(user);
        bytes32 digest = merkleAirdrop.getMessageHash(user, AMOUNT_TO_CLAIM);

        // sign a message
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivKey, digest);

        // gasPayer calls claim using the signed message
        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        uint256 endingBalance = token.balanceOf(user);

        assertEq(endingBalance - startingBalance, AMOUNT_TO_CLAIM);
    }
}
