//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {OurToken} from "../src/OurToken.sol";
import {Script} from "forge-std/Script.sol";

// If you run "make anvil" and then "make deploy", then you can see this deployment in your local anvil instance.
contract DeployOurToken is Script {
    uint256 constant INITIAL_SUPPLY = 1000 ether;

    function run() public returns (OurToken) {
        vm.startBroadcast();
        OurToken ot = new OurToken(100 ether);
        vm.stopBroadcast();

        return ot;
    }
}
