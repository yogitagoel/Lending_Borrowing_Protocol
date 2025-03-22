// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


import {AggregatorV3Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract LPToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address user, uint256 lpTokens) external {
        _mint(user, lpTokens);
    }

    function burn(address user, uint256 amount) external{
        _burn(user, amount);
}

}

contract LBP{
    
    error UserAlreadyRegistered();
    error AmountMustBePositive();
    error InsufficientBalance();
    error InsufficientCollateral();
    error ExceedsDebt();
    error CollateralRatioMaintained();

    IERC20 tokenA;
    IERC20 tokenB;
    LPToken lpToken;

    uint256 public constant COLLATERAL_RATIO = 150;
    uint256 public constant BASE_INTEREST_RATE = 5;

    uint256 public totalA;
    uint256 public totalB;
    uint256 public totalLPTokens;

    struct User{
        bool isLender;
        uint256 depositedA;
        uint256 borrowedB;
        uint256 collateral;
        uint256 lastTransactionTime;
    }
    
    mapping(address => User) public users;

    event UserRegistered(address indexed user,bool isLender);
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event DepositedCollateral(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event Liquidated(address indexed user);

    modifier onlyLender() {
    	require(users[msg.sender].isLender, "Not a lender");
    	_;
	}

    modifier onlyBorrower() {
    	require(!users[msg.sender].isLender, "Not a borrower");
    	_;
    }

    constructor(address _tokenA,address _tokenB){
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        lpToken = new LPToken("LP Token","LPT");
    }

    function RegisterUser(address user,bool isLender) public {
        if(users[user].depositedA>0 || users[user].collateral>0){
            revert UserAlreadyRegistered();
        }
        users[user].isLender = isLender;
        emit UserRegistered(user,isLender);
    }
    
    //Lender Functions
    function depositA(address user,uint256 amount) external onlyLender{
        if(amount<0){revert AmountMustBePositive();}
        tokenA.transferFrom(user,address(this),amount);
        users[user].depositedA += amount;
        totalA += amount;

        uint256 lpTokens;
        if (totalLPTokens ==0){lpTokens=amount;}
        else{(lpTokens = (amount*totalLPTokens)/totalA);}
        lpToken.mint(user,lpTokens);
        totalLPTokens += lpTokens;

        emit Deposited(user,amount);
        
    }

    function withdrawA(address user,uint256 amount) external onlyLender{
        if(users[user].depositedA<amount){revert InsufficientBalance();}

        uint256 lpTokens = (amount*totalLPTokens)/totalA;
        lpToken.burn(user,lpTokens);
        totalLPTokens -= lpTokens;

        uint256 interest=calcInterest(user);
        totalA-=amount;
        users[user].depositedA -= amount;
        tokenA.transfer(user,amount+interest);
        emit Withdrawn(user,amount);
    }

    function calcInterest(address user) public view returns (uint256 interest){
        uint256 timePassed = block.timestamp - users[user].lastTransactionTime;
        interest = users[user].depositedA*BASE_INTEREST_RATE*timePassed/(100);
        return interest;
    }
    
    //Borrower Functions
    function depositCollateral(address user,uint256 amount) external onlyBorrower{
        if(amount<0){revert AmountMustBePositive();}
        tokenA.transferFrom(user,address(this),amount);
        users[user].collateral += amount;
        totalA += amount;
        emit Deposited(user,amount);
    }

    function borrowB(address user,uint256 amount) external onlyBorrower{
        uint256 maxBorrow = users[user].collateral*100/COLLATERAL_RATIO;
        if(amount>maxBorrow){revert InsufficientCollateral();}
        tokenB.transfer(user,amount);
        users[user].borrowedB += amount;
        totalB += amount;
        users[user].lastTransactionTime = block.timestamp;
        emit Borrowed(user,amount);
    }

    function repayB(address user,uint256 amount)external onlyBorrower{
        if(users[user].borrowedB<amount){revert ExceedsDebt();}
        uint256 interest=calcInterest(user);
        tokenB.transferFrom(user,address(this),amount+interest);
        users[user].borrowedB -= amount;

        if(users[user].borrowedB==0){
            tokenA.transfer(user,users[user].collateral);
            totalA -= users[user].collateral;
            users[user].collateral = 0;
        }

        emit Repaid(user,amount);
    }

    function liquidate(address user) public {
        if(users[user].collateral<users[user].borrowedB*100/COLLATERAL_RATIO){
            revert CollateralRatioMaintained();
        }

        uint256 collateralToSeize=users[user].collateral;
        tokenA.transfer(msg.sender,collateralToSeize);
        users[user].collateral = 0;
        users[user].borrowedB = 0;
        emit Liquidated(user);
    }




}
