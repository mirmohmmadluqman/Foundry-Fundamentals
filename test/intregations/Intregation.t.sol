// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract IntractionsTest is Test {

    FundMe fundMe;

    uint256 constant SENDING_VALUE = 0.001 ether; // Less than minimum to test revert
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    address USER = makeAddr("user");

    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run();
        vm.deal(USER, STARTING_BALANCE); // Give USER 10 ether
    }

    function testUserCanFundInteractions() public {
        FundFundMe fundFundMe = new FundFundMe(); // Fix name here
        fundFundMe.fundFundMe(address(fundMe)); // Fund the FundMe contract

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe(); // Fix name here
        withdrawFundMe.withdrawFundMe(address(fundMe)); // Withdraw from the FundMe contract

        assert(address(fundMe).balance == 0); // Check if the balance is zero after withdrawal
        
        
        
        // vm.prank(USER); // Set USER as the sender
        // vm.deal(USER, 1 ether); // Give USER enough ether to fund
        // fundFundMe.fundFundMe(address(fundMe));   // Now this line works

        // address funder = fundMe.getFunder(0);
        // assertEq(funder, USER);
    }

    // I was at 9:30

}