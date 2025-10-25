// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

//forge install OpenZeppelin/openzeppelin-contracts (https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC721)
contract BasicNFT is ERC721 {
    uint256 private sTokenCounter;
    mapping(uint256 => string) private sTokenIdToTokenUri;

    constructor() ERC721("BasicNFT", "DOG") {
        sTokenCounter = 0;
    }

    function mintNFT(string memory tokenUri) public {
        sTokenIdToTokenUri[sTokenCounter] = tokenUri;
        _safeMint(msg.sender, sTokenCounter);
        sTokenCounter++;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        // return "ipfs://hash"; //ipfs://hash
        return sTokenIdToTokenUri[tokenId];
    }
}
