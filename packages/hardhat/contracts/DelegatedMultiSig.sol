// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./MetaMultiSigWallet.sol";

contract DelegatedMultiSig is MetaMultiSigWallet {
    struct TransactionProposal {
        address sender;
        address recipient;
        uint256 value;
        bytes data;
        bool approved;
    }

    address public funder;
    mapping(address => bool) public authorizedSigners;
    uint public numAuthorizedSigners;
    mapping(uint => TransactionProposal) public transactionProposals;
    uint public proposalCounter;

    constructor()
        MetaMultiSigWallet(0, new address[](0), 0)
    {}

    function setFunder(address _funder) public {
        require(funder == address(0), "Funder already set");
        funder = _funder;
    }

    modifier onlyAuthorizedSigner() {
        require(authorizedSigners[msg.sender], "Not authorized signer");
        _;
    }

    modifier onlyFunder() {
        require(msg.sender == funder, "Not funder");
        _;
    }

    function authorizeSigner(address signer) public onlySelf {
        require(signer != address(0), "Zero address");
        require(!authorizedSigners[signer], "Already authorized");
        authorizedSigners[signer] = true;
        numAuthorizedSigners++;
    }

    function removeSigner(address signer) public onlySelf {
        require(authorizedSigners[signer], "Not authorized");
        delete authorizedSigners[signer];
        numAuthorizedSigners--;
    }

    function proposeTransaction(address recipient, uint256 value, bytes memory data) public onlyAuthorizedSigner returns (uint) {
        uint proposalId = proposalCounter;
        transactionProposals[proposalId] = TransactionProposal({
            sender: msg.sender,
            recipient: recipient,
            value: value,
            data: data,
            approved: false
        });
        proposalCounter++;
        return proposalId;
    }

    function approveTransaction(uint proposalId) public onlyFunder {
        TransactionProposal storage proposal = transactionProposals[proposalId];
        require(!proposal.approved, "Already approved");
        proposal.approved = true;
    }

    function rejectTransaction(uint proposalId) public onlyFunder {
        TransactionProposal storage proposal = transactionProposals[proposalId];
        require(!proposal.approved, "Already approved");
        delete transactionProposals[proposalId];
    }

    function isTransactionApproved(uint proposalId) public view returns (bool) {
        return transactionProposals[proposalId].approved;
    }
}
