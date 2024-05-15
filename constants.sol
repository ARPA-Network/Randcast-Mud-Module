// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_TABLE, RESOURCE_SYSTEM, RESOURCE_NAMESPACE } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ROOT_NAMESPACE } from "@latticexyz/world/src/constants.sol";

bytes16 constant MODULE_NAME = bytes16("randcast");
bytes16 constant SYSTEM_NAME = bytes16("RandcastSystem");
bytes16 constant RANDCAST_TABLE_NAME = bytes16("randcast");
bytes16 constant CONFIG_TABLE_NAME = bytes16("randcastConfig");

address constant CONSUMER_WRAPPER_ADDRESS = address(0x2cB80F6C909193Dd97E7597338b4106fdAA91ad0);

ResourceId constant RANDCAST_TABLE_ID =
  ResourceId.wrap(bytes32(abi.encodePacked(RESOURCE_TABLE, ROOT_NAMESPACE, RANDCAST_TABLE_NAME)));
ResourceId constant CONFIG_TABLE_ID =
  ResourceId.wrap(bytes32(abi.encodePacked(RESOURCE_TABLE, ROOT_NAMESPACE, CONFIG_TABLE_NAME)));
ResourceId constant SYSTEM_ID =
  ResourceId.wrap((bytes32(abi.encodePacked(RESOURCE_SYSTEM, ROOT_NAMESPACE, SYSTEM_NAME))));
