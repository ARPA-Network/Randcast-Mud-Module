// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {IBaseWorld} from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import {InstalledModules} from "@latticexyz/world/src/codegen/index.sol";

import {Module} from "@latticexyz/world/src/Module.sol";
import {WorldContextConsumer} from "@latticexyz/world/src/WorldContext.sol";
import {revertWithBytes} from "@latticexyz/world/src/revertWithBytes.sol";

import {Randcast} from "./tables/Randcast.sol";
import {RandcastConfig} from "./tables/RandcastConfig.sol";
import {RandcastSystem} from "./RandcastSys.sol";

import {MODULE_NAME, TABLE_ID, CONFIG_TABLE_ID, SYSTEM_ID, NAMESPACE_ID} from "./constants.sol";

/**
 * This module creates a table that stores a nonce, and
 * a public system that returns an incremented nonce each time.
 */
contract RandcastModule is Module {
    event SystemAddress(address);
    // Since the UniqueEntitySystem only exists once per World and writes to
    // known tables, we can deploy it once and register it in multiple Worlds.

    RandcastSystem private immutable randcastSystem = new RandcastSystem();

    function getName() public pure returns (bytes16) {
        return MODULE_NAME;
    }

    function installRoot(bytes memory args) public {
        // Naive check to ensure this is only installed once
        // TODO: only revert if there's nothing to do
        requireNotInstalled(getName(), args);

        IBaseWorld world = IBaseWorld(_world());

        // // Register namespace
        (bool success, bytes memory data) =
            address(world).delegatecall(abi.encodeCall(world.registerNamespace, (NAMESPACE_ID)));
        if (!success) revertWithBytes(data);

        // Register table
        Randcast._register(TABLE_ID);
        RandcastConfig._register(CONFIG_TABLE_ID);

        // Register system
        (success, data) =
            address(world).delegatecall(abi.encodeCall(world.registerSystem, (SYSTEM_ID, randcastSystem, false)));
        if (!success) revertWithBytes(data);
        emit SystemAddress(address(randcastSystem));

        // Register system's functions
        (success, data) = address(world).delegatecall(
            abi.encodeCall(
                world.registerRootFunctionSelector,
                (SYSTEM_ID, "fulfillRandomness(bytes32,uint256,bytes32)", randcastSystem.fulfillRandomness.selector)
            )
        );
        if (!success) revertWithBytes(data);
        (address consumerWrapperAddress, address adapterAddress) = abi.decode(args, (address, address));
        RandcastConfig.setConsumerWrapperAddress(CONFIG_TABLE_ID, bytes32(0), consumerWrapperAddress);
        RandcastConfig.setAdapterAddress(CONFIG_TABLE_ID, bytes32(0), adapterAddress);
    }

    function install(bytes memory args) public {
        revert Module_NonRootInstallNotSupported();
    }
}
