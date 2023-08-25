// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployBox} from "../script/DeployBox.s.sol";
import {UpgradeBox} from "../script/UpgradeBox.s.sol";
import {BoxV1} from "../src/BoxV1.sol";
import {BoxV2} from "../src/BoxV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployAndUpgradeBoxTest is Test {
    DeployBox deployer;
    UpgradeBox upgrader;
    address user = makeAddr("user");
    uint256 START_BALANCE = 10 ether;
    address proxy;

    function setUp() external {
        deployer = new DeployBox();
        upgrader = new UpgradeBox();

        proxy = deployer.run();

        vm.deal(user, START_BALANCE);
    }

    function test_Proxy_ReturnsV1() public {
        uint256 actualVersion = BoxV1(proxy).version();

        assertEq(actualVersion, 1);
    }

    function test_Proxy_ValueOfNumisZero() public {
        uint256 num = BoxV1(proxy).getNumber();

        assertEq(num, 0);
    }

    function test_setNumber_Reverts_If_ImplementationIsV1() public {
        vm.expectRevert();
        BoxV2(proxy).setNumber(1);
    }

    function test_Proxy_UpgradesToBoxV2() public {
        BoxV2 boxV2 = new BoxV2();

        upgrader.upgradeBox(proxy, address(boxV2));
        
        bytes32 implementationStorageSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        bytes32 actualImplementation = vm.load(proxy, implementationStorageSlot);
        address actualImplementationAddress = address(uint160(uint256(actualImplementation)));

        uint256 actualVersion = BoxV2(proxy).version();
        uint256 myNumber = 229169;
        BoxV2(proxy).setNumber(myNumber);
        uint256 actualNumber = BoxV2(proxy).getNumber();

        assertEq(actualVersion, 2);
        assertEq(actualNumber, myNumber);
        assertEq(actualImplementationAddress, address(boxV2));
    }
}