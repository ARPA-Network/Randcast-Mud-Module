// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { Test } from "forge-std/Test.sol";
import { GasReporter } from "@latticexyz/gas-report/src/GasReporter.sol";

import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { World } from "@latticexyz/world/src/World.sol";
import { IModule } from "@latticexyz/world/src/IModule.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { IWorldErrors } from "@latticexyz/world/src/IWorldErrors.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";

import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";

import { NAMESPACE, SYSTEM_ID, NAMESPACE_ID, CONFIG_TABLE_ID, RANDCAST_TABLE_ID, WORLD_BALANCE_TABLE_ID } from "../constants.sol";
import { ROOT_NAMESPACE_ID, ROOT_NAMESPACE } from "@latticexyz/world/src/constants.sol";
import { RandcastModule } from "../RandcastModule.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_TABLE } from "@latticexyz/world/src/worldResourceTypes.sol";
import "../RandcastLib.sol" as RandcastLib;
import { AdapterForTest } from "./AdapterForTest.sol";
import { ConsumerWrapperForTest } from "./ConsumerWrapperForTest.sol";
import { RandcastConfig } from "../tables/RandcastConfig.sol";
import { Randcast } from "../tables/Randcast.sol";
import { RandcastSystem } from "../RandcastSys.sol";
import { Balances } from "@latticexyz/world/src/codegen/tables/Balances.sol";

contract RandcastTestSystem is System {
  function getRandomness(uint64 subId, bytes32 entityId) public returns (bytes32) {
    return RandcastLib.getRandomness(subId, entityId);
  }

  function estimateRequestFee(uint32 callBackGas, uint64 subId) public returns (uint256) {
    return RandcastLib.estimateRequestFee(callBackGas, subId);
  }

  // user transaction
  function createSubscription() external returns (uint64) {
    return RandcastLib.createSubscription();
  }

  function addConsumer(uint64 subId, address consumer) external {
    return RandcastLib.addConsumer(subId, consumer);
  }

  function fundSubscription(uint64 subId, uint256 fundAmount) external payable {
    RandcastLib.fundSubscription(subId, fundAmount);
  }
}

contract RandcastModuleTest is MudTest, GasReporter {
  using WorldResourceIdInstance for ResourceId;

  address deployerAddr;
  AdapterForTest adapter;
  ConsumerWrapperForTest wrapper;

  RandcastModule randcastModule = new RandcastModule();

  function setUp() public override {
    deployerAddr = vm.addr(vm.envUint("PRIVATE_KEY"));
    adapter = new AdapterForTest();
    wrapper = new ConsumerWrapperForTest(address(adapter));
    super.setUp();
  }

  function testInstallRoot() public {
    vm.startPrank(deployerAddr);
    IBaseWorld world = IBaseWorld(worldAddress);
    world.installRootModule(randcastModule, abi.encode(address(wrapper), address(adapter)));
    vm.stopPrank();
  }

  function testInstallRootTwice() public {
    vm.startPrank(deployerAddr);
    IBaseWorld world = IBaseWorld(worldAddress);
    world.installRootModule(randcastModule, abi.encode(address(wrapper), address(adapter)));
    vm.expectRevert(IModule.Module_AlreadyInstalled.selector);
    world.installRootModule(randcastModule, abi.encode(address(wrapper), address(adapter)));
    vm.stopPrank();
  }

  function testAccess() public {
    RandcastTestSystem randcastTestSystem = new RandcastTestSystem();
    vm.startPrank(deployerAddr);
    IBaseWorld world = IBaseWorld(worldAddress);
    world.installRootModule(randcastModule, abi.encode(address(wrapper), address(adapter)));
    assertEq(address(adapter), RandcastConfig.getAdapterAddress(CONFIG_TABLE_ID, bytes32(0)));
    assertEq(address(wrapper), RandcastConfig.getConsumerWrapperAddress(CONFIG_TABLE_ID, bytes32(0)));

    ResourceId randcastSystemId =
      WorldResourceIdLib.encode({ typeId: RESOURCE_SYSTEM, namespace: ROOT_NAMESPACE, name: "RandcastSystem" });
    world.registerSystem(randcastSystemId, randcastTestSystem, false);

    worldAddress.call{ value: 1000000000000000000 }("");
    address alice = address(bytes20(keccak256("alice")));
    vm.stopPrank();

    // Anyone without access to the world should not be able to call the system
    vm.startPrank(alice);
    vm.expectRevert();
    world.call(randcastSystemId, abi.encodeCall(RandcastTestSystem.estimateRequestFee, (0, 0)));
    vm.stopPrank();

    vm.startPrank(deployerAddr);
    world.grantAccess(SYSTEM_ID, alice);
    world.grantAccess(randcastSystemId, alice);
    vm.stopPrank();

    bytes32 entityId = bytes32(keccak256("entity"));
    vm.prank(alice);
    bytes32 requestId = abi.decode(
      world.call(randcastSystemId, abi.encodeCall(RandcastTestSystem.getRandomness, (0, entityId))), (bytes32)
    );

    uint256 randomness = 123;

    vm.expectRevert();
    adapter.fulfillRandomness(requestId, randomness);
    vm.prank(deployerAddr);
    world.grantAccess(SYSTEM_ID, address(wrapper));
    adapter.fulfillRandomness(requestId, randomness);

    assertEq(Randcast.getRandomness(RANDCAST_TABLE_ID, entityId), randomness);
    vm.stopPrank();
  }

  function testAccessFormNonRoot() public {
    vm.startPrank(deployerAddr);
    IBaseWorld world = IBaseWorld(worldAddress);
    world.installRootModule(randcastModule, abi.encode(address(wrapper), address(adapter)));
    assertEq(address(adapter), RandcastConfig.getAdapterAddress(CONFIG_TABLE_ID, bytes32(0)));
    assertEq(address(wrapper), RandcastConfig.getConsumerWrapperAddress(CONFIG_TABLE_ID, bytes32(0)));
    worldAddress.call{ value: 1000000000000000000 }("");
    IBaseWorld(worldAddress).transferBalanceToAddress(ROOT_NAMESPACE_ID, RandcastLib.getSystemAddress() , 1000000000000000000);
    address alice = address(bytes20(keccak256("alice")));
    world.grantAccess(SYSTEM_ID, alice);
    vm.stopPrank();

    // Anyone without access to the world should not be able to call the system
    vm.startPrank(alice);
    RandcastLib.estimateRequestFee(0, 0);
    bytes32 entityId = bytes32(keccak256("entity"));
    
    
    bytes32 requestId = RandcastLib.getRandomness(0, entityId);
    vm.stopPrank();

    uint256 randomness = 123;

    vm.expectRevert();
    adapter.fulfillRandomness(requestId, randomness);
    
    vm.prank(deployerAddr);
    world.grantAccess(SYSTEM_ID, address(wrapper));

    adapter.fulfillRandomness(requestId, randomness);
    assertEq(Randcast.getRandomness(RANDCAST_TABLE_ID, entityId), randomness);
  }
}
