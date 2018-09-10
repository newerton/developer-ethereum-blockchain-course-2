pragma solidity ^0.4.24;

import './AccountTransaction.sol';

contract CheckingAccount is AccountTransaction {
    address _owner;
    event DepositFunds(address from, uint amount);

    constructor() public {
        _numAuthorized = 0;
        _owner = msg.sender;
        addAuthorizer(msg.sender, TypeAuthorizer.JUDGE);
    }

    function() public payable {
        emit DepositFunds(msg.sender, msg.value);
    }

    function withdraw(uint _amount, bytes32 description) public onlyAuthorizer {
        require(_amount > 0);
        require(address(this).balance >= _amount);
        transferTo(msg.sender, _amount, description);
    }

    function walletBalance() public view returns (uint){
        return address(this).balance;
    }

    function transferTo(address _to, uint _amount, bytes32 _description) private {
        uint transactionId = ++_transactionIdx;

        Transaction memory transaction;
        transaction.from = msg.sender;
        transaction.to = _to;
        transaction.amount = _amount;
        transaction.description = _description;
        transaction.date = now;
        transaction.signatureCountLawyer = 0;
        transaction.signatureCountJudge = 0;
        transaction.statusTransaction = StatusTransaction.WAITING;

        _transactions[transactionId] = transaction;
        _pendingTransactions.push(transactionId);

        emit TransactionSendTokenCreated(transaction.from, _to, _amount, transactionId);
    }
}
