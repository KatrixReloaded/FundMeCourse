//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/FundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address tester = makeAddr("tester"); // generating a tester/user address
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe dfundMe = new DeployFundMe();
        fundMe = dfundMe.run();
        vm.deal(tester, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // the next line should revert
        fundMe.fund(); // 0 value, less than MINIMUM_USD ($5)
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(tester);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(tester);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(tester);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, tester);
    }

    modifier funded() { 
        /* set up modifiers to reduce the complexity of your unit 
        tests by using repetitive precondition LoC.
        If we had to set up multiple tests where we needed multiple 
        fund calls, we could use such a modifier and make all the calls here */
        vm.prank(tester);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(tester);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // PRECONDITIONS
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // ACTIONS
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // POSTCONDITIONS
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance, endingOwnerBalance);
    }

    function testWithdrawWithMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // not 0 as zero address might revert in most cases
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        /*
        uint256 gasStart = gasleft(); //gas left before making the withdraw call
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();

        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice(); //tx.gasprice() is set by vm.txGasPrice()
        */
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        assert(fundMe.getOwner().balance == startingOwnerBalance+startingFundMeBalance);
        assert(address(fundMe).balance == 0);
    }
}