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
- Enabling voting on proposals using a UUID-based identification system.
- Executing proposals that pass the vote.

---

## Features

- **UUID-Based Proposals:** Each proposal is assigned a unique UUID for better identification and tracking.
- **Donations Tracking:** Records both individual donations and total donations in the treasury.
- **Proposal Management:** Create proposals with title, description, target address, value, and optional call data.
- **Voting System:** Users can cast votes on active proposals with duplicate vote prevention.
- **Execution:** Approved proposals are executed, transferring ETH (and optionally invoking functions) to the target address.
- **Administrative Controls:** Owner can clear all proposals if needed.
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
  - `id`: UUID as bytes16 for unique identification
  - `title`: Title of the proposal
  - `description`: A text description of the proposal
  - `target`: The wallet or contract address to receive funds
  - `value`: The amount of ETH (in wei) to be transferred
  - `data`: Optional call data for function invocation
  - `deadline`: The timestamp until which voting is allowed
  - `yesVotes`: The number of votes in favor
  - `noVotes`: The number of votes against
  - `executed`: Boolean flag indicating execution status

- **State Variables:**
  - `proposals`: Mapping from UUID to Proposal
  - `proposalIds`: Array of all proposal UUIDs
  - `voted`: Tracks if an address has voted on a given proposal
  - `donations`: Records individual donor contributions
  - `totalDonations`: Tracks total donations received
  - `votingPeriod`: Duration of voting window
  - `nonce`: Used for UUID generation

### Key Functions

- **initialize(uint256 _votingPeriod):**  
  Initializes the contract with a specified voting period.

- **createProposal(string _title, string _description, address _target, uint256 _value, bytes _data):**  
  Creates a new proposal with a unique UUID and returns the identifier.

- **vote(bytes16 proposalId, bool support):**  
  Allows voting on proposals using their UUID.

- **executeProposal(bytes16 proposalId):**  
  Executes a passed proposal and updates total donations.

- **getAllProposals():**  
  Returns an array of all proposals.

- **clearProposals():**  
  Administrative function to clear all proposals (owner only).

---

## Upgradeability

The contract is upgradeable via the UUPS pattern. Upgrade authorization is handled by the `_authorizeUpgrade` function:
```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
```

Only the owner (chairperson) can authorize an upgrade, ensuring controlled evolution of the contract.

---
## Installing

To install dependencies, you need to execute the following commands:

```shell
forge install foundry-rs/forge-std --no-commit
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit
```

Since the `remappings.txt` file is already present, there is no need to
adjust the dependencies in Solidity code.

## Running

For building the smart-contract, you can run:
```shell
forge build
```

For executing tests:
```shell
forge test -vv
```

## Deploying

Since we are using a proxy smart-contract, we have a first deployment script, and another script
for updating the proxy contract to point to the new implementation contract.

### First time deployment:

To deploy this smart-contract to Sepolia network, you can execute the following command:

```shell
forge script script/DeployNGODAO.s.sol --rpc-url $SEPOLIA_RPC --private-key $PRIVATE_KEY --broadcast
```
Remember to set the `SEPOLIA_RPC`, and `PRIVATE_KEY` environment variables.

### Update deployment:

As we are using a proxy contract, by default, you don't need to change the proxy contract, you just point it to the new
implementation contract address.
Therefore, remember to add the proxy address on `./script/UpgradeNGODAO.sol`.

To update this smart-contract on Sepolia network, you can execute the following command:
```shell
forge script script/UpgradeNGODAO.s.sol --rpc-url $SEPOLIA_RPC --private-key $PRIVATE_KEY --broadcast
```

Remember to set the `SEPOLIA_RPC`, and `PRIVATE_KEY` environment variables.

## Generating ABI

After building the smart-contract, you can generate the ABI with that command:
```shell
make abi
```

If you are using a tool like `abigen`, for interacting with the smart-contract in your
Go code, you can execute this following command:
```shell
make go-bindings
```

If you want to generate Typescript bindings, you can execute the following command:
```shell
make typescript-bindings
```

For the same ABI generator in Rust, you could use: [ethers-contract-abigen](https://crates.io/crates/ethers-contract-abigen)
