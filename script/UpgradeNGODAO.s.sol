// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {NGODAO} from "../src/NGODAO.sol";

contract NGODAOScript is Script {
    NGODAO public dao;

    function run() public {
        vm.startBroadcast();

        address PROXY_ADDRESS = 0xe53f2315Ae1fbFd91250de7199b21AF4F0b968A2;

        dao = new NGODAO();
        console.log("new NGO DAO Implementation Address:", address(dao));

        // Upgrade the proxy
        NGODAO(payable(PROXY_ADDRESS)).upgradeToAndCall(address(dao), "");

        console.log("Upgrade successful!");
        vm.stopBroadcast();
    }
}
