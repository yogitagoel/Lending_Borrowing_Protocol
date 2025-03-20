// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {LBP} from "../src/LBP.sol";
import {DeployLBP} from "../script/DeployLBP.sol";

contract TestLBP is Test {
    LBP public Lbp;

    ERC20Mock tokenA;
    ERC20Mock tokenB;

    address lender=makeAddr("lender");
    address borrower=makeAddr("borrower");

    function setUp() public {
        deployer = new DeployLBP();
        (Lbp,tokenA,tokenB) = DeployLBP(deployer).run();
        Lbp=new LBP(tokenA,tokenB);

        tokenA.mint(lender,1e21);
        tokenA.mint(borrower,1e21);
        tokenB.mint(address(Lbp),1e21);

        vm.prank(lender);
        tokenA.approve(address(Lbp),1e21);

        vm.prank(borrower);
        tokenA.approve(address(Lbp),1e21);
        
    }

    function teatRegisterLenderWithDeposit() public {
        vm.prank(lender);
        Lbp.registerUser(lender,true);

        vm.prank(lender);
        Lbp.deposit(1e20);
        
        (,uint256 depositedA,,,)=Lbp.users(lender);
        assertEq(depositedA,1e20,"Deposit Failed");
    }

    function testWithdraw() public {
        vm.startPrank(lender);
        Lbp.registerUser(lender,true);
        Lbp.depositA(1e20);
        skip(365 days);
        Lbp.withdrawA(1e20);

        uint256 lenderBalance=tokenA.balanceOf(lender);
        assertEq(lenderBalance,10e21,"Interest Not Added");
        vm.stopPrank();
    }

    function testRegisterBorrowerAndDepositCollateral() public {
        vm.startPrank(borrower);
        Lbp.registerUser(borrower,false);
        Lbp.depositCollateral(borrower,1e20);

        (,,,uint256 collateral,)=Lbp.users(borrower);
        assertEq(collateral,1e20,"Collateral Deposit Failed");
        vm.stopPrank();
    }

    function testBorrowTokenB() public {
        vm.startPrank(borrower);
        Lbp.registerUser(borrower,false);
        Lbp.depositCollateral(borrower,300*1e18);
        Lbp.borrowB(borrower,1e20);
        
        (,,uint256 borrowedB,,)=Lbp.users(borrower);
        assertEq(borrowedB,1e20,"Borrow Failed");
        vm.stopPrank();
    }

    function testRepayTokenB() public {
        vm.startPrank(borrower);
        Lbp.registerUser(borrower,false);
        Lbp.depositCollateral(borrower,300*1e18);
        Lbp.borrowB(borrower,1e20);
        tokenB.mint(borrower,1e20);
        tokenB.approve(address(Lbp),1e20);
        Lbp.repayB(borrower,1e20);

        (,,uint256 borrowedB,,)=Lbp.users(borrower);
        assertEq(borrowedB,0,"Repay Failed");
        vm.stopPrank();
    }

    function testLiquidate() public {
        vm.startPrank(borrower);
        Lbp.registerUser(borrower,false);
        Lbp.depositCollateral(borrower,300*1e18);
        Lbp.borrowB(borrower,1e20);
        vm.stopPrank();

        vm.startPrank(lender);
        Lbp.liquidate(borrower);
        (,,,uint256 collateral,)=Lbp.users(borrower);
        assertEq(collateral,0,"Liquidation Failed");
        vm.stopPrank();
    }

    function testFailDoubleRegistration() public {
        vm.startPrank(lender);
        Lbp.registerUser(lender,true);
        Lbp.registerUser(lender,true);
        vm.stopPrank();
    }

    function testFailDepositWithoutRegistration() public {
        vm.startPrank(lender);
        Lbp.depositA(lender,1e20);
        vm.stopPrank();
    }

    function testFailWithdrawWithoutDeposit() public {
        vm.startPrank(lender);
        Lbp.registerUser(lender,true);
        Lbp.withdrawA(lender,1e20);
        vm.stopPrank();
    }

    function testFailInsufficientCollateral() public {
        vm.startPrank(borrower);
        Lbp.registerUser(borrower,false);
        Lbp.depositCollateral(borrower,3*1e20);
        Lbp.borrowB(borrower,1e20);
        vm.stopPrank();
    }
}
