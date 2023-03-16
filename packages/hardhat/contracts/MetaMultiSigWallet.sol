// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@gnosis.pm/zodiac/contracts/interfaces/IAvatar.sol";

contract MetaMultiSigWallet is IAvatar, EIP712 {
    using ECDSA for bytes32;
    
    event ExecuteTransaction(address indexed owner, address payable to, uint256 value, bytes data, uint256 nonce, bytes32 hash, bytes result);
    event Owner(address indexed owner, bool added);
    event Deposit(address indexed sender, uint amount, uint balance);

    mapping(address => bool) public isOwner;
    uint public signaturesRequired;
    uint public nonce;
    uint public chainId;
    address public owner;
    address public allowedModuleType;
    bytes32 constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    string constant public name = "MetaMultiSigWallet";
    string constant public version = "1";


    // Linked list of modules
    address public sentinel;
    mapping(address => address) public modules;

    // EIP-712 related variables and structs
    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("Transaction(uint256 nonce,address to,uint256 value,bytes data)");

    struct Transaction {
        uint256 nonce;
        address to;
        uint256 value;
        bytes data;
    }
    
    // Add constructor and other functions here


    modifier onlySelf() {
        require(msg.sender == address(this), "Not Self");
        _;
    }
    

    modifier onlyModuleType() {
        require(modules[msg.sender] != address(0), "Not a module");
        require(msg.sender == allowedModuleType, "Not the allowed module type");
        _;
    }

    constructor(uint256 _chainId, address[] memory _owners, uint _signaturesRequired, address _allowedModuleType)
        EIP712("MetaMultiSigWallet", "1") {
        require(_signaturesRequired > 0, "constructor: must be non-zero sigs required");
        owner = msg.sender;
        signaturesRequired = _signaturesRequired;
        allowedModuleType = _allowedModuleType;
        for (uint i = 0; i < _owners.length; i++) {
            _addOwner(_owners[i]);
        }
        chainId = _chainId;

        // Set up the sentinel for the module linked list
        sentinel = address(0x1);

        // EIP-712 related initialization
        _HASHED_NAME = keccak256(bytes("MetaMultiSigWallet"));
        _HASHED_VERSION = keccak256(bytes("1"));
    }

function domainSeparator() private view returns (bytes32) {
    return keccak256(
        abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId,
            address(this)
        )
    );
}



        function _hashTransaction(Transaction memory transaction) private view returns (bytes32) {
        bytes32 typeHash = _TYPE_HASH;
        bytes32 hashedName = _HASHED_NAME;
        bytes32 hashedVersion = _HASHED_VERSION;
        uint256 chainID = chainId;

        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator(),
                keccak256(abi.encode(typeHash, transaction.nonce, transaction.to, transaction.value, keccak256(transaction.data)))
            )
        );
    }
    

    function _addOwner(address _owner) private {
        require(_owner != address(0), "constructor: zero address");
        require(!isOwner[_owner], "constructor: owner not unique");
        isOwner[_owner] = true;
        emit Owner(_owner, isOwner[_owner]);
    }

    function addSigner(address newSigner, uint256 newSignaturesRequired) public onlySelf {
        _addOwner(newSigner);
        signaturesRequired = newSignaturesRequired;
    }

    function removeSigner(address oldSigner, uint256 newSignaturesRequired) public onlySelf {
        require(isOwner[oldSigner], "removeSigner: not owner");
        require(newSignaturesRequired > 0, "removeSigner: must be non-zero sigs required");
        isOwner[oldSigner] = false;
        signaturesRequired = newSignaturesRequired;
        emit Owner(oldSigner, isOwner[oldSigner]);
    }

    function executeTransaction(address payable to, uint256 value, bytes memory data, bytes[] memory signatures)
        public
        onlyModuleType
        returns (bytes memory)
    {
        Transaction memory transaction = Transaction({
            nonce: nonce,
            to: to,
            value: value,
            data: data
        });

        bytes32 transactionHash = _hashTransaction(transaction);
        nonce++;

        uint256 validSignatures;
        address duplicateGuard;
        for (uint i = 0; i < signatures.length; i++) {
            address recovered = ECDSA.recover(transactionHash, signatures[i]);
            require(recovered > duplicateGuard, "executeTransaction: duplicate or unordered signatures");
            duplicateGuard = recovered;
            if(isOwner[recovered]){
                validSignatures++;
            }
        }

        require(validSignatures >= signaturesRequired, "executeTransaction: not enough valid signatures");

        (bool success, bytes memory result) = to.call{value: value}(data);
        require(success, "executeTransaction: tx failed");

        emit ExecuteTransaction(msg.sender, to, value, data, nonce - 1, transactionHash, result);
        return result;
    }

    function getTransactionHash(uint256 _nonce, address to, uint256 value, bytes memory data) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), chainId, _nonce, to, value, data));
    }

    function recover(bytes32 _hash, bytes memory _signature) public pure returns (address) {
        return _hash.toEthSignedMessageHash().recover(_signature);
    }

    receive() payable external {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
function enableModule(address module) external override onlySelf {
        require(module != address(0) && module != sentinel, "Invalid module");
        require(modules[module] == address(0), "Module already added");
        modules[module] = modules[sentinel];
        modules[sentinel] = module;
        emit EnabledModule(module);
    }

    function disableModule(address prevModule, address module) external override onlySelf {
        require(module != sentinel, "Invalid module");
        require(modules[prevModule] == module, "Invalid prevModule");
        modules[prevModule] = modules[module];
        modules[module] = address(0);
        emit DisabledModule(module);
    }

    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external override onlyModuleType returns (bool success) {
        if (operation == Enum.Operation.Call) {
            (success, ) = to.call{value: value}(data);
        } else if (operation == Enum.Operation.DelegateCall) {
            (success, ) = to.delegatecall(data);
        } else {
            revert("Invalid operation");
        }

        if (success) {
            emit ExecutionFromModuleSuccess(msg.sender);
        } else {
            emit ExecutionFromModuleFailure(msg.sender);
        }
    }

    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external override onlyModuleType returns (bool success, bytes memory returnData) {
        if (operation == Enum.Operation.Call) {
            (success, returnData) = to.call{value: value}(data);
        } else if (operation == Enum.Operation.DelegateCall) {
            (success, returnData) = to.delegatecall(data);
        } else {
            revert("Invalid operation");
        }

        if (success) {
            emit ExecutionFromModuleSuccess(msg.sender);
        } else {
            emit ExecutionFromModuleFailure(msg.sender);
        }
    }

    function isModuleEnabled(address module) external view override returns (bool) {
        return modules[module] != address(0);
    }

    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        override
        returns (address[] memory array, address next)
    {
        // Init array with length of pageSize or the remaining number of modules
        uint256 moduleCount = 0;
        address currentModule = modules[start == address(0) ? sentinel : start];
        while (currentModule != sentinel && moduleCount < pageSize) {
            moduleCount++;
            currentModule = modules[currentModule];
        }

        array = new address[](moduleCount);

        // Populate array and find next module for pagination
        currentModule = modules[start == address(0) ? sentinel : start];
        for (uint256 i = 0; i < moduleCount; i++) {
            array[i] = currentModule;
            currentModule = modules[currentModule];
        }

        next = currentModule == sentinel ? address(0) : currentModule;
    }
}
