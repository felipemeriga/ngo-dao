// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {NGODAO} from "../src/NGODAO.sol";

contract NGODAOScript is Script {
    NGODAO public dao;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        dao = new NGODAO();

        vm.stopBroadcast();
    }
}
