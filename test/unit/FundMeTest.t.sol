// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {

    FundMe fundMe;
    uint256 constant SENDING_VALUE = 0.001 ether; // Less than minimum to test revert
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    address USER = makeAddr("user");

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // Give USER 10 ether
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        uint256 expectedVersion = block.chainid == 31337 ? 4 : 6;
        assertEq(version, expectedVersion);
    }

    // Test that funding with less than the minimum amount reverts
    function testFundFailsWithoutenoughEth() public {
        vm.prank(USER);
        vm.expectRevert(); // Expect revert because sent ETH < minimum required
        fundMe.fund{value: SENDING_VALUE}();
    }

    // Optional: Test successful fund increases amount funded correctly
    function testFundUpdatesAmountFunded() public {
        vm.prank(USER);
        uint256 validValue = 0.1 ether; // greater than minimum
        fundMe.fund{value: validValue}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, validValue);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: 0.1 ether}(); // Updated to valid value above minimum

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: STARTING_BALANCE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }


    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        uint256 gasStart =  gasleft();
        vm.txGasPrice(GAS_PRICE); // We sent 1000 gas
        vm.prank(fundMe.getOwner()); // This cost 200 gas
        fundMe.withdraw(); // Should have spent gas

        uint256 gasEnd = gasleft(); // 800 Gas is left
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Gas Used: ", gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundMeBalance);
    }

    function testwithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), 1 ether); // Provide enough ETH to bypass minimum
            fundMe.fund{value: 0.1 ether}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        console.log("Contract balance after withdraw:", address(fundMe).balance);
        // assertEq(address(fundMe).balance, 0);
        assertEq(address(fundMe).balance, 0, "Withdraw failed: Contract still has balance");
        assertEq(fundMe.getOwner().balance, startingOwnerBalance + startingFundMeBalance);
    }

    // function testWithdrawFromMultipleFundersCheaper() public funded {
    //     uint160 numberOfFunders = 10;
    //     uint160 startingFunderIndex = 1;
    //     for (uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++) {
    //         // we get hoax from stdcheats
    //         // prank + deal
    //         hoax(address(i), SENDING_VALUE);
    //         fundMe.fund{value: SENDING_VALUE}();
    //     }

    //     uint256 startingFundMeBalance = address(fundMe).balance;
    //     uint256 startingOwnerBalance = fundMe.getOwner().balance;

    //     vm.startPrank(fundMe.getOwner());
    //     fundMe.cheaperWithdraw();
    //     vm.stopPrank();

    //     assert(address(fundMe).balance == 0);
    //     assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    //     assert((numberOfFunders + 1) * SENDING_VALUE == fundMe.getOwner().balance - startingOwnerBalance);

    // }

}