// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MultiSigWallet {
    address[] public owners;
    uint public requiredApprovals;

    // transaction struct
    struct WalletMultiSigTx {
        address to;
        uint value;
        bytes data;
        bool executed;
        bool isActive;
        uint approvalCount;
    }

    mapping(uint => WalletMultiSigTx) public transactions;
    mapping(uint => mapping(address => bool)) public approvals;
    uint public transactionCount;

    constructor(address[] memory _owners, uint _requiredApprovals) {
        require(_owners.length > 0, "Owners required");
        require(_requiredApprovals > 0 && _requiredApprovals <= _owners.length, 
                "Invalid number of required approvals");

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");

            for (uint j = i + 1; j < _owners.length; j++) {
                require(owner != _owners[j], "Duplicate owner detected");
            }

            owners.push(owner);
        }
        
        requiredApprovals = _requiredApprovals;
    }


    // modifier
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Not an owner");
        _;
    }

    // events
    event SubmitTransaction(address indexed owner, uint indexed txIndex, address indexed to, uint value, bytes data);
    event ApproveTransaction(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
    event CancelTransaction(address indexed owner, uint indexed txIndex);

    receive() external payable {}

    // function to add an owner to the wallet
    function addOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        for (uint i = 0; i < owners.length; i++) {
            require(owners[i] != newOwner, "Owner already exists");
        }
        owners.push(newOwner);
    }

    // function to remove an owner from the wallet
    function removeOwner(address ownerToRemove) public onlyOwner {
        require(ownerToRemove != address(0), "Invalid owner address");
        bool ownerFound = false;
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == ownerToRemove) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                ownerFound = true;
                break;
            }
        }
        require(ownerFound, "Owner not found");
    }
    
    // function to check whether an address is an owner
    function isOwner(address _address) public view returns (bool) {
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == _address) {
                return true;
            }
        }
        return false;
    }

    // retrieve addresses that are owners
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    // retrieve transactions
    function getTransaction(uint txIndex) public view returns (WalletMultiSigTx memory) {
        return transactions[txIndex];
    }

    // withdraw funds from the wallet
    function withdraw(uint _amount, address payable _to) public onlyOwner {
        require(address(this).balance >= _amount, "Insufficient balance");
        require(_to != address(0), "Invalid recipient address");

        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Withdrawal failed");
    }

    // function to check current number of required approvals
    function getRequiredApprovals() public view returns (uint) {
        return requiredApprovals;
    }

    // submit a transaction
    function submitTransaction(address _to, uint _value, bytes memory _data) public onlyOwner {
        uint txIndex = transactionCount++;
        transactions[txIndex] = WalletMultiSigTx({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            isActive: true,
            approvalCount: 0
        });
        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    // approve a transaction
    function approveTransaction(uint _txIndex) public onlyOwner {
        
        require(transactions[_txIndex].to != address(0), "Transaction does not exist");
        require(transactions[_txIndex].isActive, "Transaction is not active");
        require(!approvals[_txIndex][msg.sender], "Transaction already approved");
        require(!transactions[_txIndex].executed, "Transaction already executed");

        approvals[_txIndex][msg.sender] = true;
        transactions[_txIndex].approvalCount += 1;

        emit ApproveTransaction(msg.sender, _txIndex);
    }

    // function to execute a transaction
    function executeTransaction(uint _txIndex) public onlyOwner {
        require(transactions[_txIndex].to != address(0), "Transaction does not exist");
        require(transactions[_txIndex].isActive, "Transaction is not active");
        require(transactions[_txIndex].approvalCount >= requiredApprovals, "Insufficient approvals");
        require(!transactions[_txIndex].executed, "Transaction already executed");

        transactions[_txIndex].executed = true;
        (bool success, ) = transactions[_txIndex].to.call{value: transactions[_txIndex].value}(transactions[_txIndex].data);
        require(success, "Transaction execution failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }


    // function to cancel a transaction
    function cancelTransaction(uint _txIndex) public onlyOwner {
        require(transactions[_txIndex].to != address(0), "Transaction does not exist");
        require(!transactions[_txIndex].executed, "Transaction already executed");
        require(transactions[_txIndex].isActive, "Transaction already cancelled");

        transactions[_txIndex].isActive = false;

        emit CancelTransaction(msg.sender, _txIndex);
    }

    // function to modify number of approvals required
    function modifyRequiredApprovals(uint _newRequiredApprovals) public onlyOwner {
        require(_newRequiredApprovals > 0 && _newRequiredApprovals <= owners.length, "Invalid number of required approvals");

        requiredApprovals = _newRequiredApprovals;
    }
}
