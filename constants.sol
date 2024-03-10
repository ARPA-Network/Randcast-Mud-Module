// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {ResourceId} from "@latticexyz/world/src/WorldResourceId.sol";
import {RESOURCE_TABLE, RESOURCE_SYSTEM, RESOURCE_NAMESPACE} from "@latticexyz/world/src/worldResourceTypes.sol";

bytes14 constant NAMESPACE = bytes14("randcast");
bytes16 constant MODULE_NAME = bytes16("randcast");
bytes16 constant SYSTEM_NAME = bytes16("RandcastSystem");
bytes16 constant RANDCAST_TABLE_NAME = bytes16("randcast");
bytes16 constant CONFIG_TABLE_NAME = bytes16("randcastConfig");
bytes16 constant WORLD_BALANCE_TABLE_NAME = bytes16("worldBalance");

ResourceId constant NAMESPACE_ID = ResourceId.wrap(bytes32(abi.encodePacked(RESOURCE_NAMESPACE, NAMESPACE)));
ResourceId constant RANDCAST_TABLE_ID = ResourceId.wrap(bytes32(abi.encodePacked(RESOURCE_TABLE, NAMESPACE, RANDCAST_TABLE_NAME)));
ResourceId constant CONFIG_TABLE_ID =
    ResourceId.wrap(bytes32(abi.encodePacked(RESOURCE_TABLE, NAMESPACE, CONFIG_TABLE_NAME)));
ResourceId constant WORLD_BALANCE_TABLE_ID =
    ResourceId.wrap(bytes32(abi.encodePacked(RESOURCE_TABLE, NAMESPACE, WORLD_BALANCE_TABLE_NAME)));
ResourceId constant SYSTEM_ID = ResourceId.wrap((bytes32(abi.encodePacked(RESOURCE_SYSTEM, NAMESPACE, SYSTEM_NAME))));
