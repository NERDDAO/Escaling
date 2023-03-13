// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./DelegatedMultiSig.sol";

contract DelegaOOr {
    event DelegationCreated(address indexed delegation);

    struct Delegation {
        address delegator;
        address funder;
        address[] signers;
        uint signaturesRequired;
    }

    mapping(address => Delegation[]) public delegations;

    constructor() {}

    function createDelegation(address funder, address[] memory signers, uint signaturesRequired) public returns (address) {
        DelegatedMultiSig delegation = new DelegatedMultiSig(0, signers, signaturesRequired);
        delegation.setFunder(funder);
        emit DelegationCreated(address(delegation));
        delegations[funder].push(Delegation(msg.sender, funder, signers, signaturesRequired));
        for (uint i = 0; i < signers.length; i++) {
            delegations[signers[i]].push(Delegation(msg.sender, funder, signers, signaturesRequired));
        }
        return address(delegation);
    }

    function getDelegationsForWallet(address wallet) public view returns (Delegation[] memory) {
        return delegations[wallet];
    }
}
