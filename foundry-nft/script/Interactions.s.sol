// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Script} from "forge-std/Script.sol";
import {DevopsTools} from "lib/foundry-devops/src/Devtools.sol";
import {BasicNFT} from "../src/BasicNFT.sol";

contract MintBasicNft is Script {
    string public constant PUG =
        "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";

    function run() external {
        address mostRecentlyDeployed = DevopsTools.get_most_recent_deployment(
            "BasicNFT",
            block.chainid
        );

        minNftOnContract(mostRecentlyDeployed);
    }

    function minNftOnContract(address contractAddress) public {
        vm.broadcast();
        BasicNFT(contractAddress).mintNFT(PUG);
        vm.stopBroadcast();
    }
}
