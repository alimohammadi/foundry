// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {BasicNFT} from "../src/BasicNFT.sol";

contract DeployBasicNft is Script {
    // function deployBasicNft() public returns (address) {
    //     BasicNFT basicNft = new BasicNFT();
    //     return address(basicNft);
    // }

    function run() external returns (BasicNFT) {
        vm.startBroadcast();
        BasicNFT basicNft = new BasicNFT();
        vm.stopBroadcast();

        return basicNft;
    }
}
