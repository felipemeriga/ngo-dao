// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

    struct Proposal {
        bytes16 id; // UUID as bytes16
        string title;
        string description;
        address target;
        uint256 value;
        bytes data;
        uint256 deadline;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

contract NGODAO is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // Mapping from UUID to Proposal
    mapping(bytes16 => Proposal) public proposals;

    // Array to store all proposal UUIDs
    bytes16[] public proposalIds;

    // Mapping from UUID to voter status
    mapping(bytes16 => mapping(address => bool)) public voted;

    mapping(address => uint256) public donations;
    uint256 public totalDonations;
    uint256 public votingPeriod;

    // Add nonce for UUID generation
    uint256 private nonce;

    // Events
    event DonationReceived(address indexed donor, uint256 amount);
    event ProposalCreated(
        bytes16 indexed proposalId,
        string title,
        string description,
        address target,
        uint256 value,
        uint256 deadline
    );
    event VoteCast(bytes16 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(bytes16 indexed proposalId, bool success);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(uint256 _votingPeriod) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        votingPeriod = _votingPeriod;
        nonce = 0;
    }

    /**
     * @notice Generate a UUID using current parameters
     */
    function _generateUUID() private returns (bytes16) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                block.timestamp,
                msg.sender,
                nonce++,
                block.prevrandao,
                block.number
            )
        );
        return bytes16(hash);
    }

    /**
     * @notice Create a proposal with a UUID
     */
    function createProposal(
        string memory _title,
        string memory _description,
        address _target,
        uint256 _value,
        bytes memory _data
    ) public returns (bytes16) {
        require(address(this).balance >= _value, "DAO treasury doesn't have enough funds");

        bytes16 uuid = _generateUUID();
        uint256 deadline = block.timestamp + votingPeriod;

        proposals[uuid] = Proposal({
            id: uuid,
            title: _title,
            description: _description,
            target: _target,
            value: _value,
            data: _data,
            deadline: deadline,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        proposalIds.push(uuid);

        emit ProposalCreated(uuid, _title, _description, _target, _value, deadline);
        return uuid;
    }

    /**
     * @notice Vote on a proposal using UUID
     */
    function vote(bytes16 proposalId, bool support) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.deadline > 0, "Proposal does not exist");
        require(block.timestamp < proposal.deadline, "Voting period has ended");
        require(!voted[proposalId][msg.sender], "Already voted on this proposal");

        voted[proposalId][msg.sender] = true;
        if (support) {
            proposal.yesVotes += 1;
        } else {
            proposal.noVotes += 1;
        }

        emit VoteCast(proposalId, msg.sender, support);
    }

    /**
     * @notice Execute a proposal using UUID
     */
    function executeProposal(bytes16 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.deadline > 0, "Proposal does not exist");
        require(block.timestamp >= proposal.deadline, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.yesVotes > proposal.noVotes, "Proposal did not pass");
        require(address(this).balance >= proposal.value, "Insufficient funds in DAO treasury");

        proposal.executed = true;
        (bool success,) = proposal.target.call{value: proposal.value}(proposal.data);
        require(success, "Proposal execution failed");

        emit ProposalExecuted(proposalId, success);
    }

    /**
     * @notice Get all proposals
     */
    function getAllProposals() external view returns (Proposal[] memory) {
        Proposal[] memory allProposals = new Proposal[](proposalIds.length);
        for (uint i = 0; i < proposalIds.length; i++) {
            allProposals[i] = proposals[proposalIds[i]];
        }
        return allProposals;
    }

    /**
     * @notice Clear all proposals (only owner)
     */
    function clearProposals() external onlyOwner {
        for(uint i = 0; i < proposalIds.length; i++) {
            delete proposals[proposalIds[i]];
        }
        delete proposalIds;
    }

    // Keep existing functions unchanged
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success,) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function donate() public payable {
        require(msg.value > 0, "Donation must be greater than 0");
        donations[msg.sender] += msg.value;
        totalDonations += msg.value;
        emit DonationReceived(msg.sender, msg.value);
    }

    receive() external payable {
        donations[msg.sender] += msg.value;
        totalDonations += msg.value;
        emit DonationReceived(msg.sender, msg.value);
    }
}