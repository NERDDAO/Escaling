// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./DelegatedMultiSig.sol";

contract delegaOOr {
    event DelegationCreated(address indexed delegation);

    constructor() {}

    function createDelegation(address funder, address[] memory signers, uint signaturesRequired) public returns (address) {
        DelegatedMultiSig delegation = new DelegatedMultiSig();
        delegation.setFunder(funder);
        for (uint i = 0; i < signers.length; i++) {
            delegation.authorizeSigner(signers[i]);
        }
        delegation.updateSignaturesRequired(signaturesRequired);
        emit DelegationCreated(address(delegation));
        return address(delegation);
    }
}
