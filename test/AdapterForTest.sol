// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IAdapterForTest} from "./IAdapterForTest.sol";

contract AdapterForTest is IAdapterForTest {
    /* solhint-disable */
    uint64 currentSubId = 0;

    struct RequestData {
        address callbackAddress;
        bytes4 callbackFunctionSelector;
    }

    mapping(bytes32 => RequestData) public pendingRequests;

    function createSubscription() external returns (uint64) {
        currentSubId += 1;
        return currentSubId;
    }

    function addConsumer(uint64 subId, address consumer) external {}

    function fundSubscription(uint64 subId) external payable {

    }

    function removeConsumer(uint64 subId, address consumer) external {}

    function getLastSubscription(address /* consumer */ ) external view returns (uint64) {
        return currentSubId;
    }

    function getSubscription(uint64 subId)
        external
        pure
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
        return (address(0), new address[](0), subId != 0 ? 1000000000 : 0, 0, 0, 0, 0, 0, 0);
    }

    function getCurrentSubId() external view returns (uint64) {
        return currentSubId;
    }

    function estimatePaymentAmountInETH(
        uint32, /* callbackGasLimit */
        uint32, /* gasExceptCallback */
        uint32, /* fulfillmentFlatFeeEthPPM */
        uint256, /* weiPerUnitGas */
        uint32 /* groupSize */
    ) external pure returns (uint256) {
        return 1000000000;
    }

    function cancelSubscription(uint64 subId, address to) external {}

    function getAdapterConfig()
        external
        pure
        returns (
            uint16 minimumRequestConfirmations,
            uint32 maxGasLimit,
            uint32 gasAfterPaymentCalculation,
            uint32 gasExceptCallback,
            uint256 signatureTaskExclusiveWindow,
            uint256 rewardPerSignature,
            uint256 committerRewardPerSignature
        )
    {
        return (3, 200000, 0, 0, 0, 0, 0);
    }

    function getFlatFeeConfig()
        external
        pure
        returns (
            uint32 fulfillmentFlatFeeLinkPPMTier1,
            uint32 fulfillmentFlatFeeLinkPPMTier2,
            uint32 fulfillmentFlatFeeLinkPPMTier3,
            uint32 fulfillmentFlatFeeLinkPPMTier4,
            uint32 fulfillmentFlatFeeLinkPPMTier5,
            uint24 reqsForTier2,
            uint24 reqsForTier3,
            uint24 reqsForTier4,
            uint24 reqsForTier5,
            uint16 flatFeePromotionGlobalPercentage,
            bool isFlatFeePromotionEnabledPermanently,
            uint256 flatFeePromotionStartTimestamp,
            uint256 flatFeePromotionEndTimestamp
        )
    {
        return (100, 200, 300, 400, 500, 10, 20, 30, 40, 0, false, 0, 0);
    }

    function getFeeTier(uint64 /* reqCount */ ) external pure returns (uint32) {
        return 1;
    }

    function requestRandomness(bytes4 callbackFunctionSelector) public returns (bytes32 requestId) {
        requestId = keccak256(abi.encodePacked(block.timestamp, "test"));
        pendingRequests[requestId] = RequestData(msg.sender, callbackFunctionSelector);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) external {
        RequestData memory data = pendingRequests[requestId];
        (bool success,) =
            data.callbackAddress.call(abi.encodeWithSelector(data.callbackFunctionSelector, requestId, randomness));
        if (!success) {
            revert("Call back failed");
        }
    }
    /* solhint-enable */
}
