// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MultiSigVault {
    struct Transaction {
        address to;
        uint256 amount;
        bytes data;
        bool executed;
        uint256 signatureCount;
        mapping(address => bool) isSigned;
    }

    address[] public owners;
    uint256 public requiredSignatures;
    Transaction[] public transactions;

    // Events
    event VaultCreated(address[] owners, uint256 requiredSignatures);
    event TransactionProposed(uint256 transactionId, address to, uint256 amount);
    event TransactionSigned(uint256 transactionId, address owner);
    event TransactionExecuted(uint256 transactionId);
    event TransactionCancelled(uint256 transactionId);
    event OwnerAdded(address newOwner);
    event OwnerRemoved(address owner);
    event RequiredSignaturesChanged(uint256 newRequiredSignatures);

    // Modifier to check if the caller is an owner
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Not an owner");
        _;
    }

    // Constructor to create the vault
    constructor(address[] memory _owners, uint256 _requiredSignatures) {
        require(_owners.length > 0, "Owners required");
        require(_requiredSignatures > 0 && _requiredSignatures <= _owners.length, "Invalid required signatures");

        owners = _owners;
        requiredSignatures = _requiredSignatures;

        emit VaultCreated(_owners, _requiredSignatures);
    }

    // Function to propose a transaction
    function proposeTransaction(address _to, uint256 _amount, bytes memory _data) public onlyOwner {
        uint256 transactionId = transactions.length;
        transactions.push(Transaction({
            to: _to,
            amount: _amount,
            data: _data,
            executed: false,
            signatureCount: 0
        }));

        emit TransactionProposed(transactionId, _to, _amount);
    }

    // Function to sign a transaction
    function signTransaction(uint256 _transactionId) public onlyOwner {
        Transaction storage transaction = transactions[_transactionId];
        require(!transaction.executed, "Transaction already executed");
        require(!transaction.isSigned[msg.sender], "Transaction already signed");

        transaction.isSigned[msg.sender] = true;
        transaction.signatureCount++;

        emit TransactionSigned(_transactionId, msg.sender);
    }

    // Function to execute a transaction
    function executeTransaction(uint256 _transactionId) public onlyOwner {
        Transaction storage transaction = transactions[_transactionId];
        require(transaction.signatureCount >= requiredSignatures, "Not enough signatures");
        require(!transaction.executed, "Transaction already executed");

        // Execute the transaction
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.amount}(transaction.data);
        require(success, "Transaction execution failed");

        emit TransactionExecuted(_transactionId);
    }

    // Function to cancel a proposed transaction
    function cancelTransaction(uint256 _transactionId) public onlyOwner {
        Transaction storage transaction = transactions[_transactionId];
        require(!transaction.executed, "Transaction already executed");

        emit TransactionCancelled(_transactionId);
    }

    // Function to add a new owner
    function addOwner(address newOwner) public onlyOwner {
        owners.push(newOwner);
        emit OwnerAdded(newOwner);
    }

    // Function to remove an existing owner
    function removeOwner(address owner) public onlyOwner {
        require(isOwner(owner), "Not an owner");
        // Logic to remove owner from the owners array
        emit OwnerRemoved(owner);
    }

    // Function to change required signatures
    function changeRequiredSignatures(uint256 newRequiredSignatures) public onlyOwner {
        require(newRequiredSignatures > 0 && newRequiredSignatures <= owners.length, "Invalid required signatures");
        requiredSignatures = newRequiredSignatures;

        emit RequiredSignaturesChanged(newRequiredSignatures);
    }

    // Function to check if an address is an owner
    function isOwner(address _owner) public view returns (bool) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _owner) {
                return true;
            }
        }
        return false;
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
