// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IAdapter {
    struct PartialSignature {
        uint256 index;
        uint256 partialSignature;
    }

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
}
