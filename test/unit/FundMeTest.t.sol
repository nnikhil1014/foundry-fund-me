// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

// Importing the necessary contracts and libraries for testing.
// console is used for debugging purposes, it allows us to print messages to the console during test execution.

contract FundMeTest is Test {
    FundMe fundme;
    address alice = makeAddr("alice");
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant SEND_VALUE = 0.1 ether;

    modifier funded() {
    vm.deal(alice, STARTING_BALANCE); // Ensure alice has enough balance to fund
    vm.prank(alice);
    fundme.fund{value: SEND_VALUE}();
    assert(address(fundme).balance > 0);
    _;
    }

    function setUp() external {
        // fundme = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundme = deployFundMe.run();
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundme.MINIMUM_USD(), 5e18, "Minimum USD should be 5");
    }

    function testOwnerIsMsgSender() public view {
        console.log("Owner address:", msg.sender);
        console.log("FundMe owner address:", fundme.i_owner());
        assertEq(
            fundme.i_owner(),
            msg.sender,
            "Owner should be the message sender"
        );
        // this works because we have pass our current address in the address(this) field, which checks the owner for the address and returns true, earlier we were checking the owner against the msg.sender, which is not the same as address(this) in this context.
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundme.getVersion();
        bool isValidVersion = (version == 6 || version == 4);
        assertTrue(isValidVersion, "Price feed version should be 4 or 6");

        // this test passes for ethereum mainnet, when the version is 6 and it passes for sepolia testnet, when the version is 4.
    }

    function testFundFailsWIthoutEnoughETH() public {
    vm.expectRevert(); // <- The next line after this one should revert! If not test fails.
    fundme.fund();     // <- We send 0 value
    }


    // this test is written to check if the fund function reverts when we try to fund the contract with 0 value, which is less than the minimum USD value of 5 USD.
    function testFundUpdatesFundDataStructure() public {
    vm.deal(alice, STARTING_BALANCE);
    vm.prank(alice);
    fundme.fund{value: SEND_VALUE}();
    uint256 amountFunded = fundme.getAddressToAmountFunded(alice);
    assertEq(amountFunded, SEND_VALUE);
    }


    // this test is written to check if the fund function updates the address to amount funded mapping correctly, when we fund the contract with a value greater than or equal to the minimum USD value of 5 USD.
    function testAddsFunderToArrayOfFunders() public {
    vm.deal(alice, STARTING_BALANCE);
    vm.startPrank(alice);
    fundme.fund{value: SEND_VALUE}();
    vm.stopPrank();

    address funder = fundme.getFunder(0);
    assertEq(funder, alice);
    }

    function testOnlyOwnerCanWithdraw() public funded {
    vm.expectRevert();
    fundme.withdraw();
    }


    // we are using the :: The arrange-act-assert (AAA) methodology is one of the simplest and most universally accepted ways to write tests. As the name suggests, it comprises three parts:

    function testWithdrawFromASingleFunder() public funded {

    // Arrange - Step #1: Set up the initial state of the contract and the test environment.

    uint256 startingFundMeBalance = address(fundme).balance;
    uint256 startingOwnerBalance = fundme.getOwner().balance;

    // Act - Step #2: Perform the action that we want to test, in this case, the withdraw function.

    vm.startPrank(fundme.getOwner());
    fundme.withdraw();

    vm.stopPrank();

    // Assert - Step #3: Check the final state of the contract and the test environment to ensure that the action had the expected effect.

    uint256 endingFundMeBalance = address(fundme).balance;
    uint256 endingOwnerBalance = fundme.getOwner().balance;
    assertEq(endingFundMeBalance, 0);
    assertEq( startingFundMeBalance + startingOwnerBalance, endingOwnerBalance );
    }
    

    function testWithdrawFromMultipleFunders() public funded {
    uint160 numberOfFunders = 10;
    uint160 startingFunderIndex = 1;
    for (uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++) {
        // we get hoax from stdcheats
        // prank + deal
        hoax(address(i), SEND_VALUE);
        fundme.fund{value: SEND_VALUE}();
    }

    uint256 startingFundMeBalance = address(fundme).balance;
    uint256 startingOwnerBalance = fundme.getOwner().balance;

    vm.startPrank(fundme.getOwner());
    fundme.withdraw();
    vm.stopPrank();

    assert(address(fundme).balance == 0);
    assert(startingFundMeBalance + startingOwnerBalance == fundme.getOwner().balance);
    assert((numberOfFunders + 1) * SEND_VALUE == fundme.getOwner().balance - startingOwnerBalance);
    }
}
