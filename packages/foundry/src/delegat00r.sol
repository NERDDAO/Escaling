// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DelegatedMultiSig.sol";

contract delegat00r {

  event DelegationCreated(address indexed delegation);

  struct Delegation {
    string name;
    address delegator;
    address funder;
    address[] signers;
    uint signaturesRequired;
  }

  mapping(address => Delegation[]) public delegator;
  mapping(address => Delegation[]) public delegating;

  function getDelegatorsForWallet(address wallet) public view returns (Delegation[] memory delegators) {
    delegators = delegator[wallet];
  }

  function getDelegatingForWallet(address wallet) public view returns (Delegation[] memory delegatingForWallet) {
    delegatingForWallet = delegating[wallet];
  }

  function createDelegation(string memory name, address funder, address[] memory signers, uint signaturesRequired) public returns (address) {
    DelegatedMultiSig delegation = new DelegatedMultiSig(0, signers, signaturesRequired, name);
    delegator[funder].push(Delegation(name, msg.sender, funder, signers, signaturesRequired));
    for (uint i = 0; i < signers.length; i++) {
      delegating[signers[i]].push(Delegation(name, msg.sender, funder, signers, signaturesRequired));
    }
    emit DelegationCreated(address(delegation));
    return address(delegation);
  }

}