// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MetaMultiSigWallet.sol";
import "./ModuleRegistry.sol";

contract Deployer {
    function deployMetaMultiSigWalletWithModules(
        uint256 _chainId,
        address[] memory _owners,
        uint256 _requiredSignatures,
        address _allowedModuleType,
        ModuleRegistry moduleRegistry,
        bytes32[] memory _moduleTypes
    ) external returns (MetaMultiSigWallet) {
        MetaMultiSigWallet wallet = new MetaMultiSigWallet(_chainId, _owners, _requiredSignatures, _allowedModuleType);

        for (uint256 i = 0; i < _moduleTypes.length; i++) {
            address moduleAddress = moduleRegistry.modules(_moduleTypes[i]);
            require(moduleAddress != address(0), "Deployer: Invalid module type");

            Module module = Module(moduleAddress);
            wallet.enableModule(address(module));
        }

        return wallet;
    }
}
