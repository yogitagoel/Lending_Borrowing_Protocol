// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {LBP} from "../src/LBP.sol";
import {ERC20Mock} from "../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract DeployLBP is Script {

    function run() public returns (LBP lbp, ERC20Mock tokenA, ERC20Mock tokenB) {
        tokenA = new ERC20Mock();
        tokenB = new ERC20Mock();
        vm.startBroadcast();

        lbp = new LBP(address(tokenA),address(tokenB));

        vm.stopBroadcast();
        return(lbp,tokenA,tokenB);
    }
}
