// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./DelegatedMultiSig.sol";

contract delegaOOr {
    event DelegationCreated(address indexed delegation);

    constructor() {}

function createDelegation(address funder, address[] memory signers, uint signaturesRequired) public returns (address) {
    DelegatedMultiSig delegation = new DelegatedMultiSig(0, signers, signaturesRequired);
    delegation.setFunder(funder);
    emit DelegationCreated(address(delegation));
    return address(delegation);
}

}
