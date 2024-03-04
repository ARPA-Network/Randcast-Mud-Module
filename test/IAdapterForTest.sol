// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IAdapterForTest {
    // user transaction
    function createSubscription() external returns (uint64);

    function addConsumer(uint64 subId, address consumer) external;

    function fundSubscription(uint64 subId) external payable;

    function removeConsumer(uint64 subId, address consumer) external;

    function getLastSubscription(address consumer) external view returns (uint64);

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
        );

    function getCurrentSubId() external view returns (uint64);

    function estimatePaymentAmountInETH(
        uint32 callbackGasLimit,
        uint32 gasExceptCallback,
        uint32 fulfillmentFlatFeeEthPPM,
        uint256 weiPerUnitGas,
        uint32 groupSize
    ) external view returns (uint256);

    function cancelSubscription(uint64 subId, address to) external;

    function getAdapterConfig()
        external
        view
        returns (
            uint16 minimumRequestConfirmations,
            uint32 maxGasLimit,
            uint32 gasAfterPaymentCalculation,
            uint32 gasExceptCallback,
            uint256 signatureTaskExclusiveWindow,
            uint256 rewardPerSignature,
            uint256 committerRewardPerSignature
        );

    function getFlatFeeConfig()
        external
        view
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
        );

    function getFeeTier(uint64 reqCount) external view returns (uint32);
    function requestRandomness(bytes4 callbackFunctionSelector) external returns (bytes32 requestId);
}
