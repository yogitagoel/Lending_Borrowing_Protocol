// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {LBP} from "../src/LBP.sol";
import {ERC20Mock} from "@openzepplin/contracts/mocks/ERC20Mock.sol";

contract DeployLBP is Script {
    LBP public lbp;

    function run() public returns (LBP lbp, ERC20Mock tokenA, ERC20Mock tokenB) {
        tokenA = new ERC20Mock("Token A","TKA",address(this),1e18);
        tokenB = new ERC20Mock("Token B","TKB",address(this),1e18);
        vm.startBroadcast();

        lbp = new LBP(tokenA,tokenB);

        vm.stopBroadcast();
        return(lbp,tokenA,tokenB);
    }
}
