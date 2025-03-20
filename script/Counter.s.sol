// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {NGODAO} from "../src/NGODAO.sol";

contract CounterScript is Script {
    NGODAO public counter;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        counter = new NGODAO();

        vm.stopBroadcast();
    }
}
