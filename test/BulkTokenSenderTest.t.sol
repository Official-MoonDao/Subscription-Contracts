// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/BulkTokenSender.sol";
import "./MockERC20.sol";

contract TestBulkTokenSender is Test {
    BulkTokenSender public bulkTokenSender;
    MockERC20 public mockToken;

    address public sender = address(0x123);
    address public recipient1 = address(0x111);
    address public recipient2 = address(0x222);
    address public recipient3 = address(0x333);

    function setUp() public {
        // Deploy MockERC20 token and BulkTokenSender contract
        vm.prank(sender);
        mockToken = new MockERC20(1000 * 10**18); // Mint 1000 tokens with 18 decimals to the sender
        bulkTokenSender = new BulkTokenSender();

        // Deal 1000 tokens to the sender
        //deal(address(mockToken), sender, 1000 * 10**18);

        // Set the sender as the caller for the test cases

        // Approve BulkTokenSender contract to spend tokens on behalf of the sender
        vm.prank(sender);
        mockToken.approveFor(sender, address(bulkTokenSender), 800 * 10**18); // Approve 500 tokens
        //vm.endPrank();
    }

    function testBulkTokenTransfer() public {
        // Set up recipients and amounts
        address[] memory recipients = new address[](3);
        recipients[0] = recipient1;
        recipients[1] = recipient2;
        recipients[2] = recipient3;

        uint256 [] memory amounts = new uint256[](3);
        amounts[0] = 100 * 10**18; // 100 tokens
        amounts[1] = 150 * 10**18; // 150 tokens
        amounts[2] = 250 * 10**18; // 250 tokens

        mockToken.balanceOf(sender);
        // log approved amount of contract for sender
        mockToken.allowance(sender, address(bulkTokenSender));
        // Call the send function
        vm.prank(sender);
        bulkTokenSender.send(address(mockToken), recipients, amounts);

        // Assert balances of recipients after the bulk send
        assertEq(mockToken.balanceOf(recipient1), 100 * 10**18);
        assertEq(mockToken.balanceOf(recipient2), 150 * 10**18);
        assertEq(mockToken.balanceOf(recipient3), 250 * 10**18);

        // Assert that the sender's balance has decreased correctly
        assertEq(mockToken.balanceOf(sender), 500 * 10**18); // Sender should have 500 tokens left
    }

    function testUploadAllocationResult() public {
        // Set up recipients and percents
        address[] memory recipients = new address[](3);
        recipients[0] = recipient1;
        recipients[1] = recipient2;
        recipients[2] = recipient3;

        uint256[] memory percents = new uint256[](3);
        percents[0] = 10;
        percents[1] = 20;
        percents[2] = 30;

        // Call the uploadAllocationResult function
        vm.prank(sender);
        bulkTokenSender.uploadAllocationResult(recipients, percents);

        // Assert that the current recipients, amounts, and split percents have been updated correctly
        assertEq(bulkTokenSender.currentRecipients(0), recipient1);
        assertEq(bulkTokenSender.currentRecipients(1), recipient2);
        assertEq(bulkTokenSender.currentRecipients(2), recipient3);

        assertEq(bulkTokenSender.currentAmounts(0), 0);
        assertEq(bulkTokenSender.currentAmounts(1), 0);
        assertEq(bulkTokenSender.currentAmounts(2), 0);

        assertEq(bulkTokenSender.currentSplitPercent(0), 10);
        assertEq(bulkTokenSender.currentSplitPercent(1), 20);
        assertEq(bulkTokenSender.currentSplitPercent(2), 30);
    }


    //function testRevertsOnMismatchedArrays() public {
        //// Set up recipients and amounts with mismatched lengths
        //address[] memory recipients = new address[](2);
        //recipients[0] = recipient1;
        //recipients[1] = recipient2;

        //uint256[] memory amounts = new uint256[](3);
        //amounts[0] = 100 * 10**18;
        //amounts[1] = 150 * 10**18;
        //amounts[2] = 250 * 10**18;

        //// Expect the function to revert due to the mismatch between recipients and amounts
        //vm.expectRevert();
        //bulkTokenSender.send(address(mockToken), recipients, amounts);
    //}

    //function testRevertsOnTransferFailure() public {
        //// Set up recipients and amounts
        //address[] memory recipients = new address[](3);
        //recipients[0] = recipient1;
        //recipients[1] = recipient2;
        //recipients[2] = recipient3;

        //uint256[] memory amounts = new uint256[](3);
        //amounts[0] = 600 * 10**18; // Amount exceeding approval limit for one transfer
        //amounts[1] = 150 * 10**18;
        //amounts[2] = 250 * 10**18;

        //// Expect the function to revert due to transfer failure
        //vm.expectRevert();
        //bulkTokenSender.send(address(mockToken), recipients, amounts);
    //}
}

