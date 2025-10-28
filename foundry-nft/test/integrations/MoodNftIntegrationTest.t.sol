// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Test, console} from "forge-std/Test.sol";
import {MoodNft} from "../../src/MoodNft.sol";
import {DeeployMoodNft} from "script/DeployMoodNft.s.sol";

contract MoodNftIntegrationTest is Test {
    MoodNft public moodNft;
    string public constant HAPPY_SVG_IMAGE_URI = "happy svg image uri";
    string public constant SAD_SVG_IMAGE_URI = "sad svg image uri";
    string public constant SAD_SVG_URI = "sad svg uri";

    address USER = makeAddr("user");

    DeeployMoodNft deployer;

    function setup() public {
        deployer = new DeeployMoodNft();
        moodNft = deployer.run();
    }

    function testViewTokenUriIntegration() public {
        vm.prank(USER);
        moodNft.mintNft();
        string memory tokenUri = moodNft.tokenURI(0);
        console.log("tokenUri", tokenUri);
    }

    function testFlipTokenToSad() public {
        vm.prank(USER);
        moodNft.mintNft();

        vm.prank(USER);
        moodNft.flipMood(0);

        assertEq(
            keccak256(abi.encodePacked(moodNft.tokenURI(0))) ==
                keccak256(abi.encodePacked((SAD_SVG_URI)))
        );
    }
}
