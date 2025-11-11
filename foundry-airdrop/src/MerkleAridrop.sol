// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;
    // some list of addresses and allow someone in the list to claim ERC-20 token

    /////////////////////////////////
    //           ERRORS            //
    /////////////////////////////////
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    /////////////////////////////////
    //           EVENTS            //
    /////////////////////////////////
    event Claimed(address indexed account, uint256 amount);

    /////////////////////////////////
    //           STRUCTS           //
    /////////////////////////////////
    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    /////////////////////////////////
    //           VARIABLES         //
    /////////////////////////////////
    address[] claimers;
    bytes32 public immutable I_MERKLE_ROOT;
    IERC20 public immutable I_AIRDROP_TOKEN;
    mapping(address user => bool claimed) private sHasClaimed;
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account, uint256 amount)");

    // merkle proofs and merkle trees
    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("MerkleAirdrop", "1") {
        // store the merkle root
        I_MERKLE_ROOT = merkleRoot;
        I_AIRDROP_TOKEN = airdropToken;
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
    {
        if (sHasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        // Check the signature
        if (!_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }

        // Calculate using the account and amount - the hash => leaf node
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount)))); // Hashing twice for security

        if (!MerkleProof.verify(merkleProof, I_MERKLE_ROOT, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }

        sHasClaimed[account] = true;
        emit Claimed(account, amount);
        I_AIRDROP_TOKEN.safeTransfer(account, amount);
    }

    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return
            _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount}))));
    }

    function getMerkleRoot() external view returns (bytes32) {
        return I_MERKLE_ROOT;
    }

    function getAirdropToken() external view returns (IERC20) {
        return I_AIRDROP_TOKEN;
    }

    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);
        return actualSigner == account;
    }
}
