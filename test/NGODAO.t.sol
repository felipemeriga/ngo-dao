// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {NGODAO} from "../src/NGODAO.sol";

contract NGODAOTest is Test {
    NGODAO public ngodao;
    ERC1967Proxy public proxy;
    address public user = address(0x123);

    function setUp() public {
        // Create a new implementation contract
        NGODAO implementation = new NGODAO();

        // Deploy proxy with initialization
        proxy = new ERC1967Proxy(address(implementation), abi.encodeWithSignature("initialize(uint256)", 259200));

        // casting the proxy contract to NGODAO interface, because we are going to interact with the proxy
        ngodao = NGODAO(payable(address(proxy)));

        // Transfer 5 ethers to user wallet
        payable(address(user)).transfer(100 ether);
    }

    function testDonate() public {
        vm.startPrank(user);
        // execute the first donation
        ngodao.donate{value: 5 ether}();

        // get the donations made by the user
        uint256 firstDonation = ngodao.donations(address(user));
        assertEq(5 ether, firstDonation);

        // donate plus 5 ether
        ngodao.donate{value: 5 ether}();

        // This variable will be the sum of all donations for the current user
        uint256 secondDonation = ngodao.donations(address(user));

        // assert that the total donations is equal 10 ether
        assertEq(10 ether, ngodao.totalDonations());
        assertEq(10 ether, secondDonation);

        vm.stopPrank();
    }
}
