# NGODAO Smart Contract

**NGODAO** is an upgradeable smart contract that implements a decentralized autonomous organization (DAO) for an NGO. It allows users to donate ETH into a treasury, create proposals for transferring funds from that treasury, vote on those proposals, and execute approved proposals.

The contract uses OpenZeppelin's upgradeable contracts and the UUPS (Universal Upgradeable Proxy Standard) pattern, ensuring the contract can be upgraded in the future without losing state.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Dependencies](#dependencies)
- [Contract Architecture](#contract-architecture)
    - [Data Structures](#data-structures)
    - [Key Functions](#key-functions)
- [Usage](#usage)
    - [Initialization](#initialization)
    - [Donations](#donations)
    - [Creating Proposals](#creating-proposals)
    - [Voting on Proposals](#voting-on-proposals)
    - [Executing Proposals](#executing-proposals)
- [Upgradeability](#upgradeability)

---

## Overview

The **NGODAO** contract enables decentralized governance for an NGO by:

- Accepting ETH donations into the DAO treasury.
- Allowing users to propose fund transfers (with optional call data for executing functions).
- Enabling voting on proposals.
- Executing proposals that pass the vote.

---

## Features

- **Donations:** Users can donate ETH to the DAO treasury.
- **Proposal Management:** Create proposals to transfer funds with an associated description, target, value, and optional call data.
- **Voting System:** Users can cast votes on active proposals.
- **Execution:** Approved proposals are executed, transferring ETH (and optionally invoking functions) to the target address.
- **Upgradeable:** Implements the UUPS upgradeable pattern for future improvements.

---

## Dependencies

- **Solidity Version:** ^0.8.20
- **OpenZeppelin Upgradeable Contracts:**
    - `Initializable`
    - `OwnableUpgradeable`
    - `UUPSUpgradeable`

---

## Contract Architecture

### Data Structures

- **Proposal Struct:**
    - `description`: A text description of the proposal.
    - `target`: The wallet or contract address to receive funds.
    - `value`: The amount of ETH (in wei) to be transferred.
    - `data`: Optional call data for function invocation on the target (empty for a plain ETH transfer).
    - `deadline`: The timestamp until which voting is allowed.
    - `yesVotes`: The number of votes in favor.
    - `noVotes`: The number of votes against.
    - `executed`: Boolean flag indicating whether the proposal has been executed.

- **Mappings:**
    - `voted`: Nested mapping that tracks if an address has voted on a given proposal (`proposalId => (voter address => bool)`).
    - `donations`: Records the total ETH donated by each address.

### Key Functions

- **initialize(uint256 _votingPeriod):**  
  Initializes the contract with a specified voting period. This function replaces the constructor in upgradeable contracts.

- **donate():**  
  Allows users to donate ETH to the DAO treasury. Also handles donations via the `receive()` function.

- **getAllProposals():**  
  Returns an array containing all proposals.

- **createProposal(string memory _description, address _target, uint256 _value, bytes memory _data):**  
  Creates a new proposal to transfer funds. Checks that the DAO treasury has sufficient funds, sets a voting deadline, stores the proposal, and emits a `ProposalCreated` event.

- **vote(uint256 proposalId, bool support):**  
  Allows a user to vote on an active proposal. Each address can vote only once per proposal. Votes are recorded in the `voted` mapping.

- **executeProposal(uint256 proposalId):**  
  Executes a proposal if it has passed (more yes votes than no votes, voting period ended, and sufficient treasury funds). Executes a low-level call to the target address with the specified value and call data.

---

## Usage

### Initialization

Deploy the proxy for the NGODAO contract and call the `initialize` function with your desired voting period (in seconds):

```solidity
function initialize(uint256 _votingPeriod) public initializer {
    __Ownable_init(msg.sender);
    __UUPSUpgradeable_init();
    votingPeriod = _votingPeriod;
}
```

For example, to set a voting period of 3 days (259200 seconds):
```solidity
initialize(259200);
```

### Donations

Users can donate ETH to the DAO treasury by calling the `donate()` function:
```solidity
function donate() public payable {
    require(msg.value > 0, "Donation must be greater than 0");
    donations[msg.sender] += msg.value;
    emit DonationReceived(msg.sender, msg.value);
}
```

Alternatively, users can send ETH directly to the contract, triggering the receive() function.

### Creating Proposals

To create a proposal for transferring funds:
```solidity
function createProposal(
    string memory _description,
    address _target,
    uint256 _value,
    bytes memory _data
) public returns (uint256 proposalId) {
    // Ensure DAO has enough funds
    require(address(this).balance >= _value, "DAO treasury doesn't have enough funds");

    uint256 deadline = block.timestamp + votingPeriod;
    proposals.push(Proposal({
        description: _description,
        target: _target,
        value: _value,
        data: _data,
        deadline: deadline,
        yesVotes: 0,
        noVotes: 0,
        executed: false
    }));

    proposalId = proposals.length - 1;
    emit ProposalCreated(proposalId, _description, _target, _value, deadline);
}
```
### Voting on Proposals

Users vote on proposals by calling the vote function:
```solidity
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
```

### Executing Proposals

Once the voting period is over and the proposal has more yes votes than no votes, the proposal can be executed:
```solidity
function executeProposal(uint256 proposalId) public {
    require(proposalId < proposals.length, "Proposal does not exist");
    Proposal storage proposal = proposals[proposalId];
    require(block.timestamp >= proposal.deadline, "Voting period not ended");
    require(!proposal.executed, "Proposal already executed");
    require(proposal.yesVotes > proposal.noVotes, "Proposal did not pass");
    require(address(this).balance >= proposal.value, "Insufficient funds in DAO treasury");
    
    proposal.executed = true;
    (bool success, ) = proposal.target.call{value: proposal.value}(proposal.data);
    require(success, "Proposal execution failed");
    
    emit ProposalExecuted(proposalId, success);
}
```

This function will transfer the specified amount of ETH (and optionally execute a function via encoded call data) from the DAO treasury to the target address.

---

## Upgradeability

The contract is upgradeable via the UUPS pattern. Upgrade authorization is handled by the `_authorizeUpgrade` function:
```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
```

Only the owner (chairperson) can authorize an upgrade, ensuring controlled evolution of the contract.