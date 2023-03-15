// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@gnosis.pm/zodiac/contracts/core/Module.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract DelegatedMultiSigModule is Module {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public threshold;
    mapping(bytes32 => EnumerableSet.AddressSet) private approvals;
    mapping(address => bool) public proposers;

    event ProposalCreated(address indexed proposer, bytes32 indexed proposalHash);
    event Approved(address indexed approver, bytes32 indexed proposalHash);
    event Rejected(address indexed rejector, bytes32 indexed proposalHash);
    event Executed(address indexed executor, bytes32 indexed proposalHash);

    constructor() {} // Remove constructor arguments

    function setUp(bytes memory initializeParams) public override {
        require(initializeParams.length > 0, "DelegatedMultiSigModule: Invalid initializeParams");
        (address _avatar, uint256 _threshold) = abi.decode(initializeParams, (address, uint256));

        avatar = _avatar;
        target = _avatar;
        threshold = _threshold;
    }

    modifier onlyProposer() {
        require(proposers[msg.sender], "DelegatedMultiSigModule: Only proposer can propose transactions");
        _;
    }

    function setThreshold(uint256 _threshold) external onlyOwner {
        threshold = _threshold;
    }

    function setProposer(address _proposer, bool _status) external onlyOwner {
        proposers[_proposer] = _status;
    }

    function proposeTransaction(address target, uint256 value, bytes memory data) external onlyProposer returns (bytes32) {
        bytes32 proposalHash = keccak256(abi.encodePacked(target, value, data));
        approvals[proposalHash].add(msg.sender);

        emit ProposalCreated(msg.sender, proposalHash);
        return proposalHash;
    }

    function approveTransaction(bytes32 proposalHash) external onlyOwner {
        require(!approvals[proposalHash].contains(msg.sender), "DelegatedMultiSigModule: Already approved");
        approvals[proposalHash].add(msg.sender);

        emit Approved(msg.sender, proposalHash);
    }

    function rejectTransaction(bytes32 proposalHash) external onlyOwner {
        require(approvals[proposalHash].contains(msg.sender), "DelegatedMultiSigModule: Not yet approved");
        approvals[proposalHash].remove(msg.sender);

        emit Rejected(msg.sender, proposalHash);
    }

    function executeTransaction(address target, uint256 value, bytes memory data, bytes32 proposalHash) external onlyOwner {
        require(approvals[proposalHash].length() >= threshold, "DelegatedMultiSigModule: Threshold not met");
        delete approvals[proposalHash];

        (bool success,) = execAndReturnData(target, value, data, Enum.Operation.Call);
        require(success, "DelegatedMultiSigModule: Execution failed");

        emit Executed(msg.sender, proposalHash);
    }
}
