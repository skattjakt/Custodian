// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {ImplementationContract, PausableContract, Pausable} from "../src/PausableOpenZeppelin.sol";

contract PausableTest is Test {
    ImplementationContract public impl;
    address public addr1;

    function setUp() public {
        impl = new ImplementationContract(address(this));
        addr1 = vm.addr(1);
    }

    function test_OwnerIsSet() public {
        assertEq(impl.owner(), address(this));
    }

    function test_Pause() public {
        impl.pause();
        vm.expectRevert(Pausable.EnforcedPause.selector);
        impl.pausedProtectedFunction();
    }

    function test_Unpause() public {
        impl.pause();
        impl.unpause();
        impl.pausedProtectedFunction();
    }

    function test_ChangeOwner() public {
        impl.transferOwnership(addr1);
    }

    function test_ChangeOwnerAndPause() public {
        impl.transferOwnership(addr1);
        vm.prank(addr1);
        impl.pause();
        vm.expectRevert(Pausable.EnforcedPause.selector);
        impl.pausedProtectedFunction();
    }
}
