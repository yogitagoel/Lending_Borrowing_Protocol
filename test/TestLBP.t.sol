// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {LBP} from "../src/LBP.sol";
import {DeployLBP} from "../script/DeployLBP.sol";

contract TestLBP is Test {
    LBP public counter;

    function setUp() public {
        counter = new LBP();
        
    }
}
