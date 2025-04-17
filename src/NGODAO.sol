// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import OpenZeppelin contracts for upgradeability.
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// Define the structure for a proposal.
struct Proposal {
    string title;
    string description; // Description of the donation proposal.
    address target; // Target address to call.
    uint256 value; // Amount of ETH (in wei) to send.
    bytes data; // Call data (could be empty for a plain ETH transfer).
    uint256 deadline; // Voting deadline timestamp.
    uint256 yesVotes; // Count of yes votes.
    uint256 noVotes; // Count of no votes.
    bool executed; // Whether the proposal has been executed.
}

contract NGODAO is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // Array to store proposals.
    Proposal[] public proposals;

    // Nested mapping to track if an address has voted on a specific proposal.
    mapping(uint256 => mapping(address => bool)) public voted;

    // Optional: Track donor contributions.
    mapping(address => uint256) public donations;

    // Total donations accumulated in the DAO treasury.
    uint256 public totalDonations;

    // Voting period duration (in seconds).
    uint256 public votingPeriod;

    // Events for logging contract activities.
    event DonationReceived(address indexed donor, uint256 amount);
    event ProposalCreated(
        uint256 indexed proposalId, string title, string description, address target, uint256 value, uint256 deadline
    );
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @notice Initializes the contract.
     * @param _votingPeriod The duration for each proposal's voting period (in seconds).
     */
    function initialize(uint256 _votingPeriod) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        votingPeriod = _votingPeriod;
    }

    /**
     * @notice Authorizes upgrades. Only the owner can upgrade the contract.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Donate ETH to the NGO treasury.
     */
    function donate() public payable {
        require(msg.value > 0, "Donation must be greater than 0");
        donations[msg.sender] += msg.value;
        totalDonations += msg.value;
        emit DonationReceived(msg.sender, msg.value);
    }

    /**
     * @notice Fallback function to accept ETH directly.
     */
    receive() external payable {
        donations[msg.sender] += msg.value;
        totalDonations += msg.value;
        emit DonationReceived(msg.sender, msg.value);
    }

    /**
     * @notice Get all the proposals made in this DAO.
     * @return the list with all the Proposal.
     */
    function getAllProposals() external view returns (Proposal[] memory) {
        return proposals;
    }

    /**
     * @notice Create a proposal to transfer funds from the DAO treasury.
     * @param _description A description of the proposal.
     * @param _target The wallet or contract to receive the ETH.
     * @param _value The amount of ETH (in wei) to transfer.
     * @param _data The call data for the function call (use empty bytes for a plain ETH transfer).
     * @return proposalId The ID of the newly created proposal.
     */
    function createProposal(string memory _title, string memory _description, address _target, uint256 _value, bytes memory _data)
        public
        returns (uint256 proposalId)
    {
        require(address(this).balance >= _value, "DAO treasury doesn't have enough funds");
        uint256 deadline = block.timestamp + votingPeriod;
        proposals.push(
            Proposal({
                title: _title,
                description: _description,
                target: _target,
                value: _value,
                data: _data,
                deadline: deadline,
                yesVotes: 0,
                noVotes: 0,
                executed: false
            })
        );
        proposalId = proposals.length - 1;
        emit ProposalCreated(proposalId, _title, _description, _target, _value, deadline);
    }

    /**
     * @notice Vote on an active proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True to vote in favor, false to vote against.
     */
    function vote(uint256 proposalId, bool support) public {
        require(proposalId < proposals.length, "Proposal does not exist");
        Proposal storage proposal = proposals[proposalId];
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
     * @notice Execute a proposal if it has passed.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public {
        require(proposalId < proposals.length, "Proposal does not exist");
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.deadline, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.yesVotes > proposal.noVotes, "Proposal did not pass");
        require(address(this).balance >= proposal.value, "Insufficient funds in DAO treasury");
        proposal.executed = true;
        (bool success,) = proposal.target.call{value: proposal.value}(proposal.data);
        require(success, "Proposal execution failed");
        emit ProposalExecuted(proposalId, success);
    }
}
