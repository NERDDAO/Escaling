// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@gnosis.pm/zodiac/contracts/core/Module.sol";

contract ModuleRegistry {
    mapping(bytes32 => address) public modules;

    event ModuleAdded(bytes32 indexed moduleId, address indexed moduleAddress);
    event ModuleRemoved(bytes32 indexed moduleId);
    event ModuleUpdated(bytes32 indexed moduleId, address indexed newModuleAddress);

    function addModule(bytes32 moduleId, address moduleAddress) external {
        require(moduleAddress != address(0), "ModuleRegistry: Invalid module address");
        require(modules[moduleId] == address(0), "ModuleRegistry: Module already exists");

        modules[moduleId] = moduleAddress;

        emit ModuleAdded(moduleId, moduleAddress);
    }

    function removeModule(bytes32 moduleId) external {
        require(modules[moduleId] != address(0), "ModuleRegistry: Module not found");

        delete modules[moduleId];

        emit ModuleRemoved(moduleId);
    }

    function updateModule(bytes32 moduleId, address newModuleAddress) external {
        require(newModuleAddress != address(0), "ModuleRegistry: Invalid new module address");
        require(modules[moduleId] != address(0), "ModuleRegistry: Module not found");

        modules[moduleId] = newModuleAddress;

        emit ModuleUpdated(moduleId, newModuleAddress);
    }
}
