// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Test, console} from "forge-std/Test.sol";
import {MoodNft} from "../../src/MoodNft.sol";

contract MoodNftTest is Test {
    MoodNft public moodNft;
    string public constant HAPPY_SVG_IMAGE_URI = "happy svg image uri";
    string public constant SAD_SVG_IMAGE_URI = "sad svg image uri";
    address USER = makeAddr("user");

    function setup() public {
        moodNft = new MoodNft(HAPPY_SVG_IMAGE_URI, SAD_SVG_IMAGE_URI);
    }

    function testViewTokenURI() public {
        vm.prank(USER);
        moodNft.mintNft();
        string memory tokenUri = moodNft.tokenURI(0);
        console.log("tokenUri", tokenUri);

        string memory expectedImageUri = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name": "Mood NFT", ',
                            '"description": "An NFT that changes based on mood.", ',
                            '"attributes": [{"trait_type": "moodiness", "value": 100}], ',
                            '"image": "',
                            HAPPY_SVG_IMAGE_URI,
                            '"}'
                        )
                    )
                )
            )
        );

        assertEq(tokenUri, expectedImageUri);
    }
}
