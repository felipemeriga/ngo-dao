// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {NGODAO} from "../src/NGODAO.sol";

contract NGODAOScript is Script {
    NGODAO public dao;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        dao = new NGODAO();
        console.log("NGO DAO Implementation Address:", address(dao));

        uint256 votingPeriod = 259200;
        // Deploy the proxy with encoded initializer call
        ERC1967Proxy proxy =
            new ERC1967Proxy(address(dao), abi.encodeWithSignature("initialize(uint256)", votingPeriod));
        console.log("NGO DAO Proxy Address:", address(proxy));

        vm.stopBroadcast();
    }
}
