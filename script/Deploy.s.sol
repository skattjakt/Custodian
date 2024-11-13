// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {Custodian} from "../src/Custodian.sol";

contract CostodianScript is Script {
    Custodian public custodian;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        custodian = new Custodian();

        vm.stopBroadcast();
    }
}
