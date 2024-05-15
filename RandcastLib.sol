// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { System } from "@latticexyz/world/src/System.sol";
import { RandcastSystem } from "../Randcast-Mud-Module/RandcastSys.sol";
import { SystemSwitch } from "@latticexyz/world-modules/src/utils/SystemSwitch.sol";
import { SYSTEM_ID } from "../Randcast-Mud-Module/constants.sol";
import { Randcast } from "../Randcast-Mud-Module/tables/Randcast.sol";
import { CONSUMER_WRAPPER_ADDRESS } from "../Randcast-Mud-Module/constants.sol";

function getRandomness(uint64 subId, bytes32 entityId) returns (bytes32 requestId) {
  return abi.decode(
    SystemSwitch.call(SYSTEM_ID, abi.encodeCall(RandcastSystem.getRandomNumber, (subId, entityId))), (bytes32)
  );
}

function getRandomnessWithCallback(uint64 subId, bytes32 entityId, uint32 callbackGas, bytes4 callbackSelector)
  returns (bytes32 requestId)
{
  return abi.decode(
    SystemSwitch.call(
      SYSTEM_ID,
      abi.encodeCall(RandcastSystem.getRandomNumberWithCallback, (subId, entityId, callbackGas, callbackSelector))
    ),
    (bytes32)
  );
}

function getRandomnessByKey(bytes32 entityId) returns (uint256 randomness) {
  return abi.decode(
    SystemSwitch.call(SYSTEM_ID, abi.encodeCall(RandcastSystem.getRandomnessByEntityId, (entityId))), (uint256)
  );
}

function getRandomnessByEntityId(bytes32 entityId) returns (uint256 randomNumber) {
  return abi.decode(
    SystemSwitch.call(SYSTEM_ID, abi.encodeCall(RandcastSystem.getRandomnessByEntityId, (entityId))), (uint256)
  );
}

// The callback gas is estimated by adding 1,000,000 to the provided callback gas
function estimateRequestFee(uint32 callBackGas, uint64 subId) returns (uint256) {
  return abi.decode(
    SystemSwitch.call(SYSTEM_ID, abi.encodeCall(RandcastSystem.estimateRequestFee, (callBackGas, subId))), (uint256)
  );
}

function getSystemAddress() returns (address) {
  return abi.decode(SystemSwitch.call(SYSTEM_ID, abi.encodeCall(RandcastSystem.getSystemAddress, ())), (address));
}

function getCoreComponentAddress() view returns (address wrapper) {
  return CONSUMER_WRAPPER_ADDRESS;
}
