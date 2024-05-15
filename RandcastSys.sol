// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { IConsumerWrapper } from "./interfaces/IConsumerWrapper.sol";
import { IRequestTypeBase } from "./interfaces/IRequestTypeBase.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { RANDCAST_TABLE_ID, CONFIG_TABLE_ID } from "./constants.sol";
import { Randcast } from "./tables/Randcast.sol";
import { RandcastConfig } from "./tables/RandcastConfig.sol";
import { SystemRegistry } from "@latticexyz/world/src/codegen/tables/SystemRegistry.sol";
import { ResourceId, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { ROOT_NAMESPACE_ID } from "@latticexyz/world/src/constants.sol";
import { Balances } from "@latticexyz/world/src/codegen/tables/Balances.sol";
// solhint-disable-next-line no-global-import

contract RandcastSystem is System {
  using WorldResourceIdInstance for ResourceId;

  error RequestFailed();
  error CallbackFailed();
  error SubscriptionCreationFailed();
  error ConsumerAdditionFailed();
  error SubscriptionFundingFailed();
  error ConsumerRemovalFailed();
  error InsufficientBalance();

  function getRandomNumber(uint64 subId, bytes32 entityId) external returns (bytes32 requestId) {
    uint32 callbackGas = estimateCallbackGas(0);
    uint256 msgValue = subId == 0 ? estimateRequestFee(callbackGas, subId) : 0;
    _spendBalance(msgValue);
    address consumerWapper = RandcastConfig.getConsumerWrapperAddress(CONFIG_TABLE_ID);
    requestId =
      IConsumerWrapper(consumerWapper).getRandomness{ value: msgValue }(subId, entityId, callbackGas, _world());
    if (requestId == 0) {
      revert RequestFailed();
    }
  }

  function getRandomNumberWithCallback(uint64 subId, bytes32 entityId, uint32 callbackGas, bytes4 callbackSelector)
    external
    returns (bytes32 requestId)
  {
    Randcast.setCallbackFunctionSelector(RANDCAST_TABLE_ID, entityId, callbackSelector);
    callbackGas = estimateCallbackGas(callbackGas);
    uint256 msgValue = subId == 0 ? estimateRequestFee(callbackGas, subId) : 0;
    _spendBalance(msgValue);
    address consumerWapper = RandcastConfig.getConsumerWrapperAddress(CONFIG_TABLE_ID);
    requestId =
      IConsumerWrapper(consumerWapper).getRandomness{ value: msgValue }(subId, entityId, callbackGas, _world());
    if (requestId == 0) {
      revert RequestFailed();
    }
  }

  function fulfillRandomness(bytes32 entityId, bytes32 requestId, uint256 randomness) external {
    Randcast.setRandomness(RANDCAST_TABLE_ID, entityId, randomness);
    Randcast.setRequestId(RANDCAST_TABLE_ID, entityId, requestId);
    bytes4 callbackFunctionSelector = Randcast.getCallbackFunctionSelector(RANDCAST_TABLE_ID, entityId);
    if (callbackFunctionSelector != 0) {
      (bool success,) = _world().delegatecall(
        abi.encodeWithSelector(callbackFunctionSelector, abi.encode(requestId, randomness, entityId))
      );
      if (!success) {
        revert CallbackFailed();
      }
    }
  }

  function getRandomnessByEntityId(bytes32 entityId) external view returns (uint256 randomNumber) {
    return Randcast.getRandomness(RANDCAST_TABLE_ID, entityId);
  }

  function estimateCallbackGas(uint32 callBackGas) public pure returns (uint32) {
    return callBackGas + 200000;
  }

  function estimateRequestFee(uint32 callBackGas, uint64 subId) public view returns (uint256) {
    address consumerWapper = RandcastConfig.getConsumerWrapperAddress(CONFIG_TABLE_ID);
    bytes memory params;
    return
      IConsumerWrapper(consumerWapper).estimateFee(IRequestTypeBase.RequestType.Randomness, subId, params, callBackGas);
  }

  function _spendBalance(uint256 amount) internal {
    ResourceId fromNamespaceId = _msgSenderNamespace();
    uint256 balance = Balances._get(fromNamespaceId);
    if (balance < amount) {
      revert InsufficientBalance();
    }
    Balances._set(fromNamespaceId, balance - amount);
  }

  function _msgSenderNamespace() internal view returns (ResourceId) {
    ResourceId systemId = SystemRegistry._getSystemId(_msgSender());
    if (ResourceId.unwrap(systemId) == 0) {
      return ROOT_NAMESPACE_ID;
    } else {
      return systemId.getNamespaceId();
    }
  }

  function getSystemAddress() external view returns (address) {
    return RandcastConfig.getSystemAddress(CONFIG_TABLE_ID);
  }
}
