// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract MoodNft is ERC721 {
    // errors
    error MoodNft__CantFlipMoodIfNotOwner();

    uint256 private sTokenCounter;
    string private sSadSvgImageURI;
    string private sHappySvgImageURI;

    enum MOOD {
        HAPPY,
        SAD
    }

    mapping(uint256 => MOOD) private sTokenIdToMood;

    constructor(
        string memory happySvgImageURI,
        string memory sadSvgImageURI
    ) ERC721("Mood NFT", "MN") {
        sTokenCounter = 0;
        sSadSvgImageURI = sadSvgImageURI;
        sHappySvgImageURI = happySvgImageURI;
    }

    function mintNft() public {
        _safeMint(msg.sender, sTokenCounter);
        sTokenIdToMood[sTokenCounter] = MOOD.HAPPY;
        sTokenCounter++;
    }

    function flipMood(uint256 tokenId) public {
        // Only want the NFT owner to be able to change the mood
        if (
            msg.sender != msg.sender &&
            msg.sender != getApproved(tokenId) &&
            !isApprovedForAll(msg.sender, msg.sender)
        ) {
            revert MoodNft__CantFlipMoodIfNotOwner();
        }

        if (sTokenIdToMood[tokenId] == MOOD.HAPPY) {
            sTokenIdToMood[tokenId] = MOOD.SAD;
        } else {
            sTokenIdToMood[tokenId] = MOOD.HAPPY;
        }
    }

    function _baseUri() internal pure returns (string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        string memory imageUri;

        if (sTokenIdToMood[tokenId] == MOOD.SAD) {
            imageUri = sSadSvgImageURI;
        } else {
            imageUri = sHappySvgImageURI;
        }

        return
            string(
                abi.encodePacked(
                    _baseUri(),
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "Mood NFT", ',
                                '"description": "An NFT that changes based on mood.", ',
                                '"attributes": [{"trait_type": "moodiness", "value": 100}], ',
                                '"image": "',
                                imageUri,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}
