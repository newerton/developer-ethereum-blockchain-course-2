pragma solidity ^0.4.24;

import './AccountAuthorizer.sol';

contract AccountTransaction is AccountAuthorizer {

    uint public constant MIN_SIGNATURES_JUDGE = 1;
    uint public constant MIN_SIGNATURES_LAWYER = 2;

    uint internal _transactionIdx;

    uint[] internal _pendingTransactions;

    enum StatusTransaction {WAITING, CANCELLED, SENDED}
    StatusTransaction statusTransaction;

    mapping(uint => Transaction) internal _transactions;

    event LogDebug(string log);
    event TransactionCancelled(uint transactionIdx);
    event TransactionSendTokenCreated(address from, address to, uint amount, uint transactionId);
    event TransactionSendTokenCompleted(address from, address to, uint amount, uint transactionId);
    event TransactionSendTokenSigned(address by, uint transactionId);

    struct Transaction {
        address from;
        address to;
        bytes32 description;
        uint amount;
        uint date;
        uint8 signatureCountJudge;
        uint8 signatureCountLawyer;
        StatusTransaction statusTransaction;
        mapping(address => uint8) signaturesJudge;
        mapping(address => uint8) signaturesLawyer;
    }

    function getPendingTransactions() public view returns (uint[]){
        return _pendingTransactions;
    }

    function getTransactionSendToken(uint _transactionId) public onlyAuthorizer view returns (
        address from,
        address to,
        uint amount,
        bytes32 description,
        uint date,
        uint8 signatureCountJudge,
        uint8 signatureCountLawyer,
        StatusTransaction status
    ) {

        from = _transactions[_transactionId].from;
        to = _transactions[_transactionId].to;
        amount = _transactions[_transactionId].amount;
        description = _transactions[_transactionId].description;
        date = _transactions[_transactionId].date;
        signatureCountJudge = _transactions[_transactionId].signatureCountJudge;
        signatureCountLawyer = _transactions[_transactionId].signatureCountLawyer;
        status = _transactions[_transactionId].statusTransaction;
        return (from, to, amount, description, date, signatureCountLawyer, signatureCountJudge, status);

    }

    function signTransactionSendToken(uint _transactionId) public onlyAuthorizer {
        Transaction storage transaction = _transactions[_transactionId];
        require(transaction.from != 0x0);
        require(transaction.from != msg.sender);
        require(transaction.statusTransaction == StatusTransaction.WAITING);
        if (_authorizers[msg.sender].typeAuthorizer == TypeAuthorizer.LAWYER) {
            assert(transaction.signaturesLawyer[msg.sender] == 0);
            transaction.signaturesLawyer[msg.sender] = 1;
            transaction.signatureCountLawyer++;
        } else {
            assert(transaction.signaturesJudge[msg.sender] == 0);
            transaction.signaturesJudge[msg.sender] = 1;
            transaction.signatureCountJudge++;
        }

        emit TransactionSendTokenSigned(msg.sender, _transactionId);

        if (transaction.signatureCountLawyer >= MIN_SIGNATURES_LAWYER || transaction.signatureCountJudge >= MIN_SIGNATURES_JUDGE) {
            require(address(this).balance >= transaction.amount);
            emit TransactionSendTokenCompleted(transaction.from, transaction.to, transaction.amount, _transactionId);
            transaction.to.transfer(transaction.amount);
            updateStatusTransactionSendToken(_transactionId, StatusTransaction.SENDED);
        }
    }

    function updateStatusTransactionSendToken(uint _transactionId, StatusTransaction _statusTransaction) internal {
        _transactions[_transactionId].statusTransaction = _statusTransaction;
    }

    function deleteTransactionSendToken(uint _transactionId) external onlyOwner {
        require(_transactions[_transactionId].statusTransaction == StatusTransaction.WAITING);
        _transactions[_transactionId].statusTransaction = StatusTransaction.CANCELLED;
        emit TransactionCancelled(_transactionId);
    }

}
