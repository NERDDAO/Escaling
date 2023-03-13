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

    string public delegationName;

    address public funder;
    mapping(address => bool) public authorizedSigners;
    uint public numAuthorizedSigners;
    mapping(uint => TransactionProposal) public transactionProposals;
    uint public proposalCounter;

    constructor(uint256 _chainId, address[] memory _owners, uint _signaturesRequired, string memory _delegationName) MetaMultiSigWallet(_chainId, _owners, _signaturesRequired) {
        delegationName = _delegationName; // Initialize the delegation name
    }

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

    function executeTransaction(uint proposalId) public onlyFunder {
        TransactionProposal storage proposal = transactionProposals[proposalId];
        require(proposal.approved, "Not approved");
        require(proposal.recipient != address(0), "Zero address recipient");
        (bool success, ) = proposal.recipient.call{value: proposal.value}(proposal.data);
        require(success, "Transaction failed");
        delete transactionProposals[proposalId];
    }
}
