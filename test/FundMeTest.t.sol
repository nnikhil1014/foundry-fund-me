// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test,console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";   
import {DeployFundMe} from "../script/DeployFundMe.s.sol";
// Importing the necessary contracts and libraries for testing.
// console is used for debugging purposes, it allows us to print messages to the console during test execution.

contract FundMeTest is Test {
    FundMe fundme;

    function setUp() external {
        // fundme = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundme = deployFundMe.run();
    }
    
    function testMinimumDollarIsFive() view public {
        assertEq(fundme.MINIMUM_USD(), 5e18, "Minimum USD should be 5");
    }

    function testOwnerIsMsgSender() view public {
        console.log("Owner address:", msg.sender);
        console.log("FundMe owner address:", fundme.i_owner());
        assertEq(fundme.i_owner(), msg.sender, "Owner should be the message sender");
        // this works because we have pass our current address in the address(this) field, which checks the owner for the address and returns true, earlier we were checking the owner against the msg.sender, which is not the same as address(this) in this context.
    }

    function testPriceFeedVersionIsAccurate() view public {
        uint256 version = fundme.getVersion();
        assertEq(version, 4, "Price feed version should be 4");
    }
}