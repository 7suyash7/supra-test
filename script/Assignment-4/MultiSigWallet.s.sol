// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { MultiSigWallet } from "../../src/Assignment-4/MultiSigWallet.sol";
import { console } from "forge-std/console.sol";

contract MultiSigWalletScript is Script {
    MultiSigWallet multiSigWallet;
    address[] owners;
    uint requiredApprovals = 2;

    function setUp() public {
        owners = new address[](3);
        owners[0] = address(0x1);
        owners[1] = address(0x2);
        owners[2] = address(0x3);

        multiSigWallet = new MultiSigWallet(owners, requiredApprovals);
        console.log("MultiSigWallet deployed with required approvals:", requiredApprovals);


        payable(address(multiSigWallet)).transfer(5 ether);
        console.log("Funded MultiSigWallet with 5 ether");
    }

    function run() public {
        console.log("Starting Script Run");

        // fund the MultiSigWallet with ether
        payable(address(multiSigWallet)).transfer(2 ether);
        console.log("Transferred ether to MultiSigWallet");

        // submit a transaction by an owner
        address to = address(0x5);
        uint value = 1 ether;
        bytes memory data = "";
        vm.broadcast(owners[0]);
        multiSigWallet.submitTransaction(to, value, data);
        console.log("Transaction submitted to:", to);

        // approve the transaction by two different owners
        vm.broadcast(owners[0]);
        multiSigWallet.approveTransaction(0);
        console.log("Transaction approved by owner 1");

        vm.broadcast(owners[1]);
        multiSigWallet.approveTransaction(0);
        console.log("Transaction approved by owner 2");

        // execute the transaction
        vm.broadcast(owners[0]);
        multiSigWallet.executeTransaction(0);
        console.log("Transaction executed");

        // cancel another transaction
        console.log("Cancelling another transaction");
        vm.broadcast(owners[0]);
        multiSigWallet.submitTransaction(to, value, data);
        vm.broadcast(owners[0]);
        multiSigWallet.cancelTransaction(1);
        console.log("Transaction canceled");

        // modify required approvals
        console.log("Modifying required approvals");
        uint newRequiredApprovals = 3;
        vm.broadcast(owners[0]);
        multiSigWallet.modifyRequiredApprovals(newRequiredApprovals);
        console.log("Required approvals changed to:", newRequiredApprovals);

        console.log("Ending Script Run");
    }

}