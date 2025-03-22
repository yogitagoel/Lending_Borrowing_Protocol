// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {LBP} from "../src/LBP.sol";
import {DeployLBP} from "../script/DeployLBP.s.sol";
import {ERC20Mock} from "../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract TestLBP is Test {
    LBP public Lbp;
    DeployLBP deployer;

    ERC20Mock tokenA;
    ERC20Mock tokenB;

    address lender=makeAddr("lender");
    address borrower=makeAddr("borrower");

    function setUp() public {
        deployer = new DeployLBP();
        (Lbp,tokenA,tokenB) = DeployLBP(deployer).run();
        Lbp=new LBP(address(tokenA),address(tokenB));

        tokenA.mint(lender,1e21);
        tokenA.mint(borrower,1e21);
        tokenB.mint(address(Lbp),5e22);
        tokenA.mint(address(Lbp),5e22);

        vm.prank(lender);
        tokenA.approve(address(Lbp),5e22);

        vm.prank(borrower);
        tokenA.approve(address(Lbp),5e22);
        
    }

    function testRegisterLenderWithDeposit() public {
        vm.prank(lender);
        Lbp.RegisterUser(lender,true);

        vm.prank(lender);
        Lbp.depositA(lender,1e20);
        
        (,uint256 depositedA,,,)=Lbp.users(lender);
        assertEq(depositedA,1e20,"Deposit Failed");
    }

    function testWithdraw() public {
        vm.startPrank(lender);
        uint256 init_lenderBalance=tokenA.balanceOf(lender);
        Lbp.RegisterUser(lender,true);
        Lbp.depositA(lender,1e18);
        skip(3600);
        uint256 interest=Lbp.calcInterest(lender);
        Lbp.withdrawA(lender,1e18);

        uint256 lenderBalance=tokenA.balanceOf(lender);
        assertEq(lenderBalance,init_lenderBalance+interest,"Interest Not Added");
        vm.stopPrank();
    }

    function testRegisterBorrowerAndDepositCollateral() public {
        vm.startPrank(borrower);
        Lbp.RegisterUser(borrower,false);
        Lbp.depositCollateral(borrower,1e20);

        (,,,uint256 collateral,)=Lbp.users(borrower);
        assertEq(collateral,1e20,"Collateral Deposit Failed");
        vm.stopPrank();
    }

    function testBorrowTokenB() public {
        vm.startPrank(borrower);
        Lbp.RegisterUser(borrower,false);
        Lbp.depositCollateral(borrower,300*1e18);
        Lbp.borrowB(borrower,1e20);
        
        (,,uint256 borrowedB,,)=Lbp.users(borrower);
        assertEq(borrowedB,1e20,"Borrow Failed");
        vm.stopPrank();
    }

    function testRepayTokenB() public {
        vm.startPrank(borrower);
        Lbp.RegisterUser(borrower,false);
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
        Lbp.RegisterUser(borrower,false);
        Lbp.depositCollateral(borrower,300*1e18);
        Lbp.borrowB(borrower,1e20);
        vm.stopPrank();

        vm.startPrank(lender);
        Lbp.liquidate(borrower);
        (,,,uint256 collateral,)=Lbp.users(borrower);
        assertEq(collateral,0,"Liquidation Failed");
        vm.stopPrank();
    }

    function test_FailDoubleRegistration() public {
        vm.startPrank(lender);
        Lbp.RegisterUser(lender,true);
        Lbp.RegisterUser(lender,true);
        vm.stopPrank();
    }

    function test_FailDepositWithoutRegistration() public {
        vm.startPrank(lender);
        vm.expectRevert("Not a lender");
        Lbp.depositA(lender,1e20);
        vm.stopPrank();
    }

    function test_FailWithdrawWithoutDeposit() public {
        vm.startPrank(lender);
        Lbp.RegisterUser(lender,true);
        vm.expectRevert(abi.encodeWithSignature("InsufficientBalance()"));
        Lbp.withdrawA(lender,1e20);
        vm.stopPrank();
    }
}
