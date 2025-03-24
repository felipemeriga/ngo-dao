// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/NGODAO.sol";
import "../src/NGODAO.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {NGODAO} from "../src/NGODAO.sol";
import {Test, console} from "forge-std/Test.sol";

contract NGODAOTest is Test {
    NGODAO public ngodao;
    ERC1967Proxy public proxy;
    address public user = address(0x1000);
    address public user2 = address(0x1001);
    address public user3 = address(0x1010);
    address public church = address(0x1011);

    function setUp() public {
        // Create a new implementation contract
        NGODAO implementation = new NGODAO();

        // Deploy proxy with initialization
        proxy = new ERC1967Proxy(address(implementation), abi.encodeWithSignature("initialize(uint256)", 259200));

        // casting the proxy contract to NGODAO interface, because we are going to interact with the proxy
        ngodao = NGODAO(payable(address(proxy)));

        // Transfer 5 ethers to user wallet
        payable(address(user)).transfer(100 ether);
        payable(address(user2)).transfer(100 ether);
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

    function testDonateError() public {
        vm.startPrank(user);
        vm.expectRevert("Donation must be greater than 0");
        ngodao.donate();

        vm.stopPrank();
    }

    function testCreateProposal() public {
        vm.startPrank(user);
        vm.expectRevert("DAO treasury doesn't have enough funds");
        // Create a proposal without having funds in the NGO treasury
        ngodao.createProposal("Send money to a charity church", address(church), 5, "");

        // User donates some ether to the NGO
        ngodao.donate{value: 10 ether}();

        // Submitting the proposal again
        ngodao.createProposal("Send money to a charity church", address(church), 5, "");

        Proposal[] memory proposals = ngodao.getAllProposals();
        Proposal memory firstProposal = proposals[0];
        assertEq(1, proposals.length);
        assertEq(5, firstProposal.value);
        assertEq(address(church), firstProposal.target);
        assertEq("Send money to a charity church", firstProposal.description);

        vm.stopPrank();
    }

    function testVoteProposal() public {
        vm.startPrank(user);

        // User donates some ether to the NGO
        ngodao.donate{value: 10 ether}();

        // Creating the proposal
        uint256 proposalID = ngodao.createProposal("Send money to a charity church", address(church), 5 ether, "");
        ngodao.vote(proposalID, true);
        assertEq(true, ngodao.voted(proposalID, address(user)));
        vm.stopPrank();

        vm.startPrank(user2);

        // Second user votes
        ngodao.vote(proposalID, true);
        assertEq(true, ngodao.voted(proposalID, address(user2)));

        vm.stopPrank();

        // Warp time forward to let the voting period to expire
        uint256 warpTime = 10 * 86400;
        vm.warp(block.timestamp + warpTime);

        vm.startPrank(user3);
        vm.expectRevert("Voting period has ended");
        // Another user will try to vote after the expiration
        ngodao.vote(proposalID, true);

        // Execute the proposal
        ngodao.executeProposal(proposalID);

        // Make sure the ether has been sent to the proposal target
        assertEq(church.balance, 5 ether);
        vm.stopPrank();
    }

    function testVoteNonExistingProposal() public {
        vm.startPrank(user);
        vm.expectRevert("Proposal does not exist");
        ngodao.vote(0, true);

        vm.stopPrank();
    }

    function testVoteTwice() public {
        vm.startPrank(user);

        // User donates some ether to the NGO
        ngodao.donate{value: 10 ether}();

        // Creating the proposal
        uint256 proposalID = ngodao.createProposal("Send money to a charity church", address(church), 5 ether, "");

        ngodao.vote(proposalID, true);

        // User tries to vote twice on the same proposal
        vm.expectRevert("Already voted on this proposal");
        ngodao.vote(proposalID, true);
        vm.stopPrank();
    }

    function testExecuteUnexpiredProposal() public {
        vm.startPrank(user);

        // User donates some ether to the NGO
        ngodao.donate{value: 10 ether}();

        // Creating the proposal
        uint256 proposalID = ngodao.createProposal("Send money to a charity church", address(church), 5 ether, "");

        vm.expectRevert("Voting period not ended");
        // User tries to execute the proposal before the expiration
        ngodao.executeProposal(proposalID);

        vm.stopPrank();
    }

    function testInsufficientFundsToCreateProposal() public {
        vm.startPrank(user);

        // User donates some ether to the NGO
        ngodao.donate{value: 10 ether}();

        // Creating the proposal with more money than the treasury has
        vm.expectRevert("DAO treasury doesn't have enough funds");
        ngodao.createProposal("Send money to a charity church", address(church), 15 ether, "");

        vm.stopPrank();
    }

    function testInsufficientFundsExecutingProposal() public {
        vm.startPrank(user);

        // User donates some ether to the NGO
        ngodao.donate{value: 10 ether}();

        // Creating two proposals, for executing one of them, while when executing the another, the treasury will have insufficient funds
        uint256 firstProposalID = ngodao.createProposal("Send money to a charity church", address(church), 10 ether, "");
        uint256 secondProposalID =
            ngodao.createProposal("Send money to a second charity church", address(church), 5 ether, "");
        // Add a vote for approving the proposalI
        ngodao.vote(firstProposalID, true);
        ngodao.vote(secondProposalID, true);

        // Warp time forward to let the voting period to expire
        uint256 warpTime = 3 * 86400;
        vm.warp(block.timestamp + warpTime);

        // Executing the first proposal
        ngodao.executeProposal(firstProposalID);

        // Executing the second proposal will fail, due to insufficient funds in the NGO treasury
        vm.expectRevert("Insufficient funds in DAO treasury");
        ngodao.executeProposal(secondProposalID);

        vm.stopPrank();
    }

    function testProposalDidNotPass() public {
        vm.startPrank(user);

        // User donates some ether to the NGO
        ngodao.donate{value: 10 ether}();

        // Creating the proposal
        uint256 proposalID = ngodao.createProposal("Send money to a charity church", address(church), 5 ether, "");
        ngodao.vote(proposalID, true);
        vm.stopPrank();

        vm.startPrank(user2);

        // Second user votes as false
        ngodao.vote(proposalID, false);

        // Warp time forward to let the voting period to expire
        uint256 warpTime = 10 * 86400;
        vm.warp(block.timestamp + warpTime);

        // Execute the proposal
        vm.expectRevert("Proposal did not pass");
        ngodao.executeProposal(proposalID);

        vm.stopPrank();
    }

    function testProposalExecutedTwice() public {
        vm.startPrank(user);

        // User donates some ether to the NGO
        ngodao.donate{value: 10 ether}();

        // Creating the proposal
        uint256 proposalID = ngodao.createProposal("Send money to a charity church", address(church), 5 ether, "");
        ngodao.vote(proposalID, true);

        // Warp time forward to let the voting period to expire
        uint256 warpTime = 10 * 86400;
        vm.warp(block.timestamp + warpTime);

        // Execute the proposal for the first time
        ngodao.executeProposal(proposalID);

        // Execute the proposal for the second time
        vm.expectRevert("Proposal already executed");
        ngodao.executeProposal(proposalID);
        vm.stopPrank();
    }

    function testProposalExecutionError() public {
        vm.startPrank(user);

        // User donates some ether to the NGO
        ngodao.donate{value: 10 ether}();

        // Creating the proposal with wrong data
        uint256 proposalID =
            ngodao.createProposal("Send money to a charity church", address(church), 5 ether, "nasdunasudnaudnasudad");
        ngodao.vote(proposalID, true);

        // Warp time forward to let the voting period to expire
        uint256 warpTime = 10 * 86400;
        vm.warp(block.timestamp + warpTime);

        // Execute the proposal, generating an executing error
        ngodao.executeProposal(proposalID);

        vm.stopPrank();
    }
}
