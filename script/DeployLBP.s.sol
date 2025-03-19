// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {LBP} from "../src/LBP.sol";

contract DeployLBP is Script {
    LBP public counter;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        counter = new LBP();

        vm.stopBroadcast();
    }
}
