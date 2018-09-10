pragma solidity ^0.4.24;

import './Ownable.sol';

contract AccountAuthorizer is Ownable {
    address private _owner;
    uint public MAX_AUTHORIZERS = 10;

    enum StatusAuthorizer {INACTIVE, ACTIVE}
    StatusAuthorizer statusAuthorizer;

    enum TypeAuthorizer {JUDGE, LAWYER}
    TypeAuthorizer typeAuthorizer;

    uint public _numAuthorized;
    mapping(address => Authorizer) public _authorizers;

    struct Authorizer {
        address _address;
        uint created_at;
        StatusAuthorizer statusAuthorizer;
        TypeAuthorizer typeAuthorizer;
    }

    modifier onlyAuthorizer(){
        require(
            _authorizers[msg.sender]._address != 0x0 &&
            _authorizers[msg.sender].statusAuthorizer == StatusAuthorizer.ACTIVE
        );
        _;
    }

    function addAuthorizer(address _authorized, TypeAuthorizer _typeAuthorizer) public onlyOwner {
        require(_numAuthorized <= MAX_AUTHORIZERS);
        require(
            _authorizers[_authorized]._address == 0x0 ||
            _authorizers[_authorized].statusAuthorizer == StatusAuthorizer.INACTIVE
        );

        _numAuthorized++;

        Authorizer memory authorizer;
        authorizer._address = _authorized;
        authorizer.created_at = now;
        authorizer.statusAuthorizer = StatusAuthorizer.ACTIVE;
        authorizer.typeAuthorizer = _typeAuthorizer;
        _authorizers[_authorized] = authorizer;
    }

    function removeAuthorizer(address _authorized) public onlyOwner {
        require(_numAuthorized > 0);
        _authorizers[_authorized].statusAuthorizer = StatusAuthorizer.INACTIVE;
        _numAuthorized--;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require((newOwner != address(0)) && (_authorizers[newOwner].statusAuthorizer == StatusAuthorizer.ACTIVE));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
