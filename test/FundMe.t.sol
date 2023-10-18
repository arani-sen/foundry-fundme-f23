// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe}  from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe public fundMe;
    HelperConfig public helperConfig;

    uint256 public constant SEND_VALUE = 0.1 ether; // just a value to make sure we are sending enough!
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant GAS_PRICE = 1;

    address public constant USER = address(1);

    function setup()external {
         DeployFundMe deployFundMe = new DeployFundMe();
         fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_USER_BALANCE);

    }


    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        assert(address(fundMe).balance > 0);
        _;
    }


   function testFundUpdatesFundedDataStructure() public {
        vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        vm.prank(USER);
        fundMe.fund{value:SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        fundMe.withdraw();
    }


    function testWithdrawFromASingleFunder() public funded {
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        // // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance 
        );
    }

    function testWithWithdrawFrommultipleFunders() public funded{
        uint160 numberoffunders = 10;
        uint160 startingFunderIndex = 2;

        for(uint160 i = startingFunderIndex; i< numberoffunders; i++){
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE};
        }

        
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance; 
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
        assert((numberOfFunders + 1) * SEND_VALUE == fundMe.getOwner().balance - startingOwnerBalance);
    }

}

 