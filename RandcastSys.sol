// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IConsumerWrapper } from "./interfaces/IConsumerWrapper.sol";
import { IAdapter } from "./interfaces/IAdapter.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { RANDCAST_TABLE_ID, CONFIG_TABLE_ID, WORLD_BALANCE_TABLE_ID } from "./constants.sol";
import { Randcast } from "./tables/Randcast.sol";
import { RandcastConfig } from "./tables/RandcastConfig.sol";
import { WorldBalance } from "./tables/WorldBalance.sol";
// solhint-disable-next-line no-global-import

contract RandcastSystem is System {
  error RequestFailed();
  error CallbackFailed();
  error SubscriptionCreationFailed();
  error ConsumerAdditionFailed();
  error SubscriptionFundingFailed();
  error ConsumerRemovalFailed();
  error InsufficientBalance();

  function getRandomNumber(uint64 subId, bytes32 entityId) external payable returns (bytes32 requestId) {
    uint32 callbackGas = estimateCallbackGas(0);
    uint256 msgValue = subId == 0 ? estimateRequestFee(callbackGas, subId) : 0;
    address consumerWapper = RandcastConfig.getConsumerWrapperAddress(CONFIG_TABLE_ID, bytes32(0));
    if (address(this).balance < msgValue || (address(this) != _world() && WorldBalance.getBalance(WORLD_BALANCE_TABLE_ID, _world()) < msgValue)){
      revert InsufficientBalance();
    }
    requestId = IConsumerWrapper(consumerWapper).getRandomNumber{ value: msgValue }(
      subId, entityId, callbackGas, _world(), this.fulfillRandomness.selector
    );
    if (requestId == 0) {
      revert RequestFailed();
    }
  }

  function getRandomNumberWithCallback(uint64 subId, bytes32 entityId, uint32 callbackGas, bytes4 callbackSelector)
    external
    payable
    returns (bytes32 requestId)
  {
    Randcast.setCallbackFunctionSelector(RANDCAST_TABLE_ID, entityId, callbackSelector);
    callbackGas = estimateCallbackGas(callbackGas);
    uint256 msgValue = subId == 0 ? estimateRequestFee(callbackGas, subId) : 0;
    address consumerWapper = RandcastConfig.getConsumerWrapperAddress(CONFIG_TABLE_ID, bytes32(0));
    if (address(this).balance < msgValue || (address(this) != _world() && WorldBalance.getBalance(WORLD_BALANCE_TABLE_ID, _world()) < msgValue)){
      revert InsufficientBalance();
    }
    requestId = IConsumerWrapper(consumerWapper).getRandomNumber{ value: msgValue }(
      subId, entityId, callbackGas, _world(), this.fulfillRandomness.selector
    );
    if (requestId == 0) {
      revert RequestFailed();
    }
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness, bytes32 entityId) external {
    Randcast.setRandomness(RANDCAST_TABLE_ID, entityId, randomness);
    Randcast.setRequestId(RANDCAST_TABLE_ID, entityId, requestId);
    bytes4 callbackFunctionSelector = Randcast.getCallbackFunctionSelector(RANDCAST_TABLE_ID, entityId);
    if (callbackFunctionSelector != 0) {
      (bool success,) =
        _world().call(abi.encodeWithSelector(callbackFunctionSelector, abi.encode(requestId, randomness, entityId)));
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
    address consumerWapper = RandcastConfig.getConsumerWrapperAddress(CONFIG_TABLE_ID, bytes32(0));
    return IConsumerWrapper(consumerWapper).estimateFee(subId, callBackGas);
  }

  function createSubscription() external returns (uint64) {
    address adapter = RandcastConfig.getAdapterAddress(CONFIG_TABLE_ID, bytes32(0));
    (bool success, bytes memory data) =
      adapter.call(abi.encodeWithSelector(IAdapter(adapter).createSubscription.selector));
    if (!success || data.length == 0) {
      revert SubscriptionCreationFailed();
    }
    return abi.decode(data, (uint64));
  }

  function addConsumer(uint64 subId, address consumer) external {
    address adapter = RandcastConfig.getAdapterAddress(CONFIG_TABLE_ID, bytes32(0));
    (bool success,) = adapter.call(abi.encodeWithSelector(IAdapter(adapter).addConsumer.selector, subId, consumer));
    if (!success) {
      revert ConsumerAdditionFailed();
    }
  }

  function fundSubscription(uint64 subId, uint256 fundAmount) external payable {
    address adapter = RandcastConfig.getAdapterAddress(CONFIG_TABLE_ID, bytes32(0));
    if (address(this).balance < fundAmount || (address(this) != _world() && WorldBalance.getBalance(WORLD_BALANCE_TABLE_ID, _world()) < fundAmount)){
      revert InsufficientBalance();
    }
    (bool success,) =
      adapter.call{ value: fundAmount }(abi.encodeWithSelector(IAdapter(adapter).fundSubscription.selector, subId));
    if (!success) {
      revert SubscriptionFundingFailed();
    }
  }

  function removeConsumer(uint64 subId, address consumer) external {
    address adapter = RandcastConfig.getAdapterAddress(CONFIG_TABLE_ID, bytes32(0));
    (bool success,) = adapter.call(abi.encodeWithSelector(IAdapter(adapter).removeConsumer.selector, subId, consumer));
    if (!success) {
      revert ConsumerRemovalFailed();
    }
  }

  function getLastSubscription(address consumer) external view returns (uint64) {
    address adapter = RandcastConfig.getAdapterAddress(CONFIG_TABLE_ID, bytes32(0));
    return IAdapter(adapter).getLastSubscription(consumer);
  }

  function getSubscription(uint64 subId)
    external
    view
    returns (
      address owner,
      address[] memory consumers,
      uint256 balance,
      uint256 inflightCost,
      uint64 reqCount,
      uint64 freeRequestCount,
      uint64 referralSubId,
      uint64 reqCountInCurrentPeriod,
      uint256 lastRequestTimestamp
    )
  {
    address adapter = RandcastConfig.getAdapterAddress(CONFIG_TABLE_ID, bytes32(0));
    return IAdapter(adapter).getSubscription(subId);
  }

  function getCurrentSubId() external view returns (uint64) {
    address adapter = RandcastConfig.getAdapterAddress(CONFIG_TABLE_ID, bytes32(0));
    return IAdapter(adapter).getCurrentSubId();
  }

  function getSystemAddress() external view returns (address) {
    return RandcastConfig.getSystemAddress(CONFIG_TABLE_ID, bytes32(0));
  }

  receive() external payable {
    uint256 balance = WorldBalance.getBalance(WORLD_BALANCE_TABLE_ID, _world());
    WorldBalance.setBalance(WORLD_BALANCE_TABLE_ID, _world(), balance + msg.value);
  }
}
