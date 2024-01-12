// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Test } from "forge-std/Test.sol";
import { MultiSigWallet } from "../../src/Assignment-4/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet wallet;
    address[] owners;
    uint requiredApprovals;

    function setUp() public {
        owners = [address(0x1), address(0x2), address(0x3), address(0x4)];
        requiredApprovals = 2;

        wallet = new MultiSigWallet(owners, requiredApprovals);
    }

    // test to verify the correct initialization of owners
    function testInitializationOwners() public {
        assertEq(wallet.getOwners(), owners, "Owners are not initialized correctly");
    }

    // test to verify the correct initialization of required approvals
    function testInitializationRequiredApprovals() public {
        assertEq(wallet.getRequiredApprovals(), requiredApprovals, "Required approvals are not initialized correctly");
    }

    // test to add a new owner
    function testAddNewOwner() public {
        address newOwner = address(0x5);
        vm.prank(owners[0]);
        wallet.addOwner(newOwner);
        bool isOwner = wallet.isOwner(newOwner);
        assertTrue(isOwner, "New owner should be added successfully");
    }

    // test to remove an owner
    function testRemoveOwner() public {
        address ownerToRemove = owners[1];
        vm.prank(owners[0]);
        wallet.removeOwner(ownerToRemove);
        bool isStillOwner = wallet.isOwner(ownerToRemove);
        assertFalse(isStillOwner, "Owner should be removed successfully");
    }

    // test to add an existing owner
    function testAddExistingOwner() public {
        address existingOwner = owners[0];
        vm.prank(existingOwner);
        vm.expectRevert("Owner already exists");
        wallet.addOwner(existingOwner);
    }

    // test to remove a non owner
    function testRemoveNonOwner() public {
        address nonOwner = address(0x6);
        vm.prank(owners[0]);
        vm.expectRevert("Owner not found");
        wallet.removeOwner(nonOwner);
    }

    // test transaction submission
    function testSubmitTransaction() public {
        address to = address(0x5);
        uint value = 1000;
        bytes memory data = "Test data";

        vm.prank(owners[0]);
        wallet.submitTransaction(to, value, data);

        MultiSigWallet.WalletMultiSigTx memory transaction = wallet.getTransaction(0);
        assertEq(transaction.to, to, "Recipient address does not match");
        assertEq(transaction.value, value, "Transaction value does not match");
        assertEq(transaction.data, data, "Transaction data does not match");
        assertFalse(transaction.executed, "Transaction should not be executed yet");
        assertTrue(transaction.isActive, "Transaction should be active");
        assertEq(transaction.approvalCount, 0, "Approval count should be 0");
    }

    // test to approve submitted transaction and check if approval count is correct
    function testApproveTransaction() public {
        address to = address(0x5);
        uint value = 1000;
        bytes memory data = "Test data";
        vm.prank(owners[0]);
        wallet.submitTransaction(to, value, data);

        vm.prank(owners[0]);
        wallet.approveTransaction(0);
        vm.prank(owners[1]);
        wallet.approveTransaction(0);

        MultiSigWallet.WalletMultiSigTx memory transaction = wallet.getTransaction(0);
        assertEq(transaction.approvalCount, 2, "Approval count should increase by 1");
    }

    // test to approve non existing transaction to ensure it fails
    function testApproveNonExistingTransaction() public {
        uint nonExistingTxIndex = 999; // Assuming this transaction index does not exist
        vm.prank(owners[0]);
        vm.expectRevert("Transaction does not exist");
        wallet.approveTransaction(nonExistingTxIndex);
    }

    // test to approve an already executed transaction and ensure it fails
    function testApproveExecutedTransaction() public {
        address to = address(0x5);
        uint value = 1000;
        bytes memory data = "";

        payable(address(wallet)).transfer(value);

        vm.prank(owners[0]);
        wallet.submitTransaction(to, value, data);

        vm.prank(owners[0]);
        wallet.approveTransaction(0);
        vm.prank(owners[1]);
        wallet.approveTransaction(0);

        vm.prank(owners[0]);
        wallet.executeTransaction(0);

        vm.prank(owners[2]);
        vm.expectRevert("Transaction already executed");
        wallet.approveTransaction(0);
    }
    
    // test to approve transaction already appproved by same owner
    function testApproveTransactionAlreadyApprovedBySameOwner() public {
        address to = address(0x5);
        uint value = 1000;
        bytes memory data = "Test data";
        
        vm.prank(address(0x1));
        wallet.submitTransaction(to, value, data);

        vm.prank(address(0x2));
        wallet.approveTransaction(0);

        vm.expectRevert("Transaction already approved");
        vm.prank(address(0x2));
        wallet.approveTransaction(0);
    }

    // test to execute transactions
    function testExecuteTransaction() public {
        address to = address(0x5);
        uint value = 1000;
        bytes memory data = "";

        payable(address(wallet)).transfer(value);

        vm.prank(owners[0]);
        wallet.submitTransaction(to, value, data);

        vm.prank(owners[0]);
        wallet.approveTransaction(0);
        vm.prank(owners[1]);
        wallet.approveTransaction(0);

        uint initialBalance = address(to).balance;
        vm.prank(owners[0]);
        wallet.executeTransaction(0);

        assertEq(address(to).balance, initialBalance + value, "The recipient did not receive the correct amount");
    }

    // test to ensure non existing transaction fails
    function testExecuteNonExistingTransaction() public {
        uint nonExistingTxIndex = 999;
        vm.prank(owners[0]);
        vm.expectRevert("Transaction does not exist");
        wallet.executeTransaction(nonExistingTxIndex);
    }

    // test to ensure insufficient approvals transaction fails
    function testExecuteTransactionInsufficientApprovals() public {
        address to = address(0x5);
        uint value = 1000;
        bytes memory data = "";

        payable(address(wallet)).transfer(value);

        vm.prank(owners[0]);
        wallet.submitTransaction(to, value, data);

        vm.prank(owners[0]);
        wallet.approveTransaction(0);

        vm.prank(owners[0]);
        vm.expectRevert("Insufficient approvals");
        wallet.executeTransaction(0);
    }

    // test to ensure transaction already executed fails
    function testExecuteTransactionAlreadyExecuted() public {
        address to = address(0x5);
        uint value = 1000;
        bytes memory data = "";

        payable(address(wallet)).transfer(value);

        vm.prank(owners[0]);
        wallet.submitTransaction(to, value, data);

        vm.prank(owners[0]);
        wallet.approveTransaction(0);
        vm.prank(owners[1]);
        wallet.approveTransaction(0);
        vm.prank(owners[0]);
        wallet.executeTransaction(0);

        vm.prank(owners[0]);
        vm.expectRevert("Transaction already executed");
        wallet.executeTransaction(0);
    }

    // test to cancel a submitted transaction
    function testCancelTransaction() public {
        address to = address(0x5);
        uint value = 1000;
        bytes memory data = "Test data";

        vm.prank(owners[0]);
        wallet.submitTransaction(to, value, data);

        vm.prank(owners[0]);
        wallet.cancelTransaction(0);

        MultiSigWallet.WalletMultiSigTx memory transaction = wallet.getTransaction(0);
        assertFalse(transaction.isActive, "Transaction should be marked as inactive");
    }

    // test to cancel a non existing transaction and ensure it fails
    function testCancelNonExistingTransaction() public {
        uint nonExistingTxIndex = 999;
        vm.prank(owners[0]);
        vm.expectRevert("Transaction does not exist");
        wallet.cancelTransaction(nonExistingTxIndex);
    }

    // test to cancel a transaction that has already been executed and ensure it fails
    function testCancelExecutedTransaction() public {
        address to = address(0x5);
        uint value = 1000;
        bytes memory data = "";

        payable(address(wallet)).transfer(value);
        vm.prank(owners[0]);
        wallet.submitTransaction(to, value, data);

        vm.prank(owners[0]);
        wallet.approveTransaction(0);
        vm.prank(owners[1]);
        wallet.approveTransaction(0);
        vm.prank(owners[0]);
        wallet.executeTransaction(0);

        vm.prank(owners[0]);
        vm.expectRevert("Transaction already executed");
        wallet.cancelTransaction(0);
    }

    // test to cancel a transaction that has already been cancelled and ensure it fails
    function testCancelAlreadyCanceledTransaction() public {
        address to = address(0x5);
        uint value = 1000;
        bytes memory data = "Test data";

        vm.prank(owners[0]);
        wallet.submitTransaction(to, value, data);

        vm.prank(owners[0]);
        wallet.cancelTransaction(0);

        vm.prank(owners[0]);
        vm.expectRevert("Transaction already cancelled");
        wallet.cancelTransaction(0);
    }

    // test to change required number of approvals and verify if it updates
    function testChangeRequiredApprovals() public {
        uint newRequiredApprovals = 3;

        vm.prank(owners[0]);
        wallet.modifyRequiredApprovals(newRequiredApprovals);

        assertEq(wallet.getRequiredApprovals(), newRequiredApprovals, "Required approvals should be updated correctly");
    }

    // test to set an invalid number of required approvals and ensure it fails
    function testSetInvalidRequiredApprovals() public {
        uint invalidRequiredApprovals = owners.length + 1;

        vm.prank(owners[0]);
        vm.expectRevert("Invalid number of required approvals");
        wallet.modifyRequiredApprovals(invalidRequiredApprovals);
    }

    // test withdraw from contract and check if balance decreases
    function testWithdrawFunds() public {
        uint depositAmount = 1000;
        uint withdrawAmount = 500;
        payable(address(wallet)).transfer(depositAmount);

        uint initialBalance = address(wallet).balance;
        address payable recipient = payable(address(0x5));

        vm.prank(owners[0]);
        wallet.withdraw(withdrawAmount, recipient);

        assertEq(address(wallet).balance, initialBalance - withdrawAmount, "Contract balance should decrease by the withdrawn amount");
    }

    // test to withdraw an amount exceeding contract balance and ensure it fails
    function testWithdrawExceedingAmount() public {
        uint depositAmount = 500;
        payable(address(wallet)).transfer(depositAmount);

        uint withdrawAmount = depositAmount + 500;
        address payable recipient = payable(address(0x5));

        vm.prank(owners[0]);
        vm.expectRevert("Insufficient balance");
        wallet.withdraw(withdrawAmount, recipient);
    }

    // test to withdraw to invalid address and ensure it fails
    function testWithdrawToInvalidAddress() public {
        uint depositAmount = 1000;
        payable(address(wallet)).transfer(depositAmount);

        uint withdrawAmount = 500;
        address payable invalidRecipient = payable(address(0));

        vm.prank(owners[0]);
        vm.expectRevert("Invalid recipient address");
        wallet.withdraw(withdrawAmount, invalidRecipient);
    }

    // edge cases

    // test with min owners
    function testMinimumNumberOfOwners() public {
        address[] memory minOwners = new address[](1);
        minOwners[0] = address(0x1);

        MultiSigWallet minOwnerWallet = new MultiSigWallet(minOwners, 1);
        assertEq(minOwnerWallet.getOwners().length, 1, "There should be exactly 1 owner");
    }

    // test with max owners
    function testMaximumNumberOfOwners() public {
        address[] memory maxOwners = new address[](10);
        for (uint i = 0; i < 10; i++) {
            maxOwners[i] = address(uint160(i + 1));
        }

        MultiSigWallet maxOwnerWallet = new MultiSigWallet(maxOwners, 1);
        assertEq(maxOwnerWallet.getOwners().length, 10, "There should be exactly 10 owners");
    }

    // test min required approvals
    function testMinimumRequiredApprovals() public {
        MultiSigWallet minApprovalWallet = new MultiSigWallet(owners, 1);
        assertEq(minApprovalWallet.getRequiredApprovals(), 1, "Required approvals should be minimum (1)");
    }

    // test max required approvals
    function testMaximumRequiredApprovals() public {
        MultiSigWallet maxApprovalWallet = new MultiSigWallet(owners, owners.length);
        assertEq(maxApprovalWallet.getRequiredApprovals(), owners.length, "Required approvals should be maximum (equal to the number of owners)");
    }
    
}
