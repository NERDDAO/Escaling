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

  mapping(address => Delegation[]) public delegations;

  function createDelegation(string memory name, address funder, address[] memory signers, uint signaturesRequired) public returns (address) {
    DelegatedMultiSig delegation = new DelegatedMultiSig(0, signers, signaturesRequired, name);
    emit DelegationCreated(address(delegation));
    delegations[funder].push(Delegation(name, msg.sender, funder, signers, signaturesRequired));
    for (uint i = 0; i < signers.length; i++) {
      delegations[signers[i]].push(Delegation(name, msg.sender, funder, signers, signaturesRequired));
    }
    return address(delegation);
  }

  function getDelegationsForWallet(address wallet) public view returns (string[] memory, Delegation[] memory) {
    Delegation[] memory walletDelegations = delegations[wallet];
    string[] memory delegationNames = new string[](walletDelegations.length);
    for (uint i = 0; i < walletDelegations.length; i++) {
      delegationNames[i] = walletDelegations[i].name;
    }
    return (delegationNames, walletDelegations);
  }

}