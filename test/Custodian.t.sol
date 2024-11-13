// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {Custodian} from "../src/Custodian.sol";

contract CustodianTest is Test {
    Custodian public custodian;

    function setUp() public {
        custodian = new Custodian();
    }
}