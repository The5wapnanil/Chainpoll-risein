# 🗳️ ChainPoll(Created by - Swapnanil Ghosh)

A simple, beginner-friendly smart contract that lets anyone create public polls, vote on options, and see transparent, on-chain results visible to everyone. Perfect for learning Solidity and showcasing trustless, tamper-evident polling on Ethereum-like networks! 🚀
<img width="1897" height="863" alt="Screenshot 2025-10-29 135923" src="https://github.com/user-attachments/assets/094ee2a6-c27b-4f86-b6c6-f93c0b11c1fc" />

## 📖 Project Description

ChainPoll is a minimal on-chain polling system where users can create polls with multiple options, cast one vote per address, and view results at any time. It focuses on clarity, safety, and transparency, making it ideal for first projects and tutorials.

## ✨ What it does

- Create polls 📝 with a question and 2–10 options, emitting events for easy tracking.  
- Allow addresses to vote 🗳️ exactly once per poll, preventing duplicates.  
- View poll info and results 📊 via public read functions for frontend or explorer use.  
- Let poll creators close polls 🔒 to stop further voting while preserving results permanently.  

## 🎯 Features

- Simple API: createPoll, vote, closePoll, getPollInfo, getOption, getPollResults, hasVotedOnPoll  
- Transparent results: all poll votes and tallies are readable on-chain 🔍  
- Event logs: PollCreated, VoteCast, PollClosed for off-chain indexing 📡  
- Beginner-friendly: clear patterns, input validation, and logical structure 🎓  

## 🌐 Deployed Smart Contract Link

0x70c383c62b05ecbf186805db3dd2ada5d7531f69

Deployed Smart Contract Link:[ link](https://celo-sepolia.blockscout.com/address/0x70C383C62B05eCBf186805dB3DD2AdA5D7531f69?tab=index)

## 📜 Smart Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChainPoll
 * @dev A simple on-chain polling system where users can create polls and vote
 * @notice This contract allows creating polls with multiple options and transparent voting
 */
contract ChainPoll {
    
    // Structure to represent a single poll option
    struct Option {
        string name;        // Name of the option (e.g., "Yes", "No", "Maybe")
        uint256 voteCount;  // Number of votes this option has received
    }
    
    // Structure to represent a complete poll
    struct Poll {
        uint256 id;                    // Unique identifier for the poll
        string question;               // The poll question
        Option[] options;              // Array of voting options
        address creator;               // Address of the poll creator
        uint256 createdAt;            // Timestamp when poll was created
        bool active;                   // Whether the poll is still accepting votes
        mapping(address => bool) hasVoted;  // Track which addresses have voted
    }
    
    // State variables
    uint256 public pollCount;                    // Total number of polls created
    mapping(uint256 => Poll) public polls;       // Mapping from poll ID to Poll struct
    
    // Events for logging important actions
    event PollCreated(uint256 indexed pollId, string question, address indexed creator);
    event VoteCast(uint256 indexed pollId, uint256 optionIndex, address indexed voter);
    event PollClosed(uint256 indexed pollId);
    
    /**
     * @dev Creates a new poll with the given question and options
     * @param _question The question to ask in the poll
     * @param _optionNames Array of option names (e.g., ["Yes", "No", "Maybe"])
     */
    function createPoll(string memory _question, string[] memory _optionNames) public {
        require(_optionNames.length >= 2, "Poll must have at least 2 options");
        require(_optionNames.length <= 10, "Poll cannot have more than 10 options");
        require(bytes(_question).length > 0, "Question cannot be empty");
        
        // Increment poll count to get new poll ID
        pollCount++;
        uint256 newPollId = pollCount;
        
        // Create the new poll
        Poll storage newPoll = polls[newPollId];
        newPoll.id = newPollId;
        newPoll.question = _question;
        newPoll.creator = msg.sender;
        newPoll.createdAt = block.timestamp;
        newPoll.active = true;
        
        // Add all options to the poll
        for (uint256 i = 0; i < _optionNames.length; i++) {
            require(bytes(_optionNames[i]).length > 0, "Option name cannot be empty");
            newPoll.options.push(Option({
                name: _optionNames[i],
                voteCount: 0
            }));
        }
        
        emit PollCreated(newPollId, _question, msg.sender);
    }
    
    /**
     * @dev Allows a user to vote on a specific poll option
     * @param _pollId The ID of the poll to vote on
     * @param _optionIndex The index of the option to vote for (0-based)
     */
    function vote(uint256 _pollId, uint256 _optionIndex) public {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        
        Poll storage poll = polls[_pollId];
        
        require(poll.active, "This poll is closed");
        require(!poll.hasVoted[msg.sender], "You have already voted on this poll");
        require(_optionIndex < poll.options.length, "Invalid option index");
        
        // Mark that this address has voted
        poll.hasVoted[msg.sender] = true;
        
        // Increment the vote count for the selected option
        poll.options[_optionIndex].voteCount++;
        
        emit VoteCast(_pollId, _optionIndex, msg.sender);
    }
    
    /**
     * @dev Closes a poll (only the creator can close their poll)
     * @param _pollId The ID of the poll to close
     */
    function closePoll(uint256 _pollId) public {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        
        Poll storage poll = polls[_pollId];
        
        require(msg.sender == poll.creator, "Only the poll creator can close this poll");
        require(poll.active, "Poll is already closed");
        
        poll.active = false;
        
        emit PollClosed(_pollId);
    }
    
    /**
     * @dev Gets basic information about a poll
     * @param _pollId The ID of the poll
     * @return question The poll question
     * @return creator Address of the poll creator
     * @return createdAt Timestamp when poll was created
     * @return active Whether the poll is still active
     * @return optionCount Number of options in the poll
     */
    function getPollInfo(uint256 _pollId) public view returns (
        string memory question,
        address creator,
        uint256 createdAt,
        bool active,
        uint256 optionCount
    ) {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        
        Poll storage poll = polls[_pollId];
        
        return (
            poll.question,
            poll.creator,
            poll.createdAt,
            poll.active,
            poll.options.length
        );
    }
    
    /**
     * @dev Gets information about a specific option in a poll
     * @param _pollId The ID of the poll
     * @param _optionIndex The index of the option
     * @return name The option name
     * @return voteCount Number of votes the option has received
     */
    function getOption(uint256 _pollId, uint256 _optionIndex) public view returns (
        string memory name,
        uint256 voteCount
    ) {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        
        Poll storage poll = polls[_pollId];
        require(_optionIndex < poll.options.length, "Invalid option index");
        
        Option storage option = poll.options[_optionIndex];
        
        return (option.name, option.voteCount);
    }
    
    /**
     * @dev Gets all options and their vote counts for a poll
     * @param _pollId The ID of the poll
     * @return names Array of option names
     * @return voteCounts Array of vote counts for each option
     */
    function getPollResults(uint256 _pollId) public view returns (
        string[] memory names,
        uint256[] memory voteCounts
    ) {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        
        Poll storage poll = polls[_pollId];
        uint256 optionCount = poll.options.length;
        
        names = new string[](optionCount);
        voteCounts = new uint256[](optionCount);
        
        for (uint256 i = 0; i < optionCount; i++) {
            names[i] = poll.options[i].name;
            voteCounts[i] = poll.options[i].voteCount;
        }
        
        return (names, voteCounts);
    }
    
    /**
     * @dev Checks if an address has voted on a specific poll
     * @param _pollId The ID of the poll
     * @param _voter The address to check
     * @return bool True if the address has voted, false otherwise
     */
    function hasVotedOnPoll(uint256 _pollId, address _voter) public view returns (bool) {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        return polls[_pollId].hasVoted[_voter];
    }
}

```

## 🧰 Install & Run Guide

Beginner-friendly steps to clone, install, test, and deploy ChainPoll using Remix or Hardhat.

### 🚀 Quick Start (Remix - easiest)

- Open Remix (browser).  
- Create ChainPoll.sol and paste your contract code.  
- Compile with Solidity 0.8.20 (or compatible).  
- Deploy via Deploy & Run:  
  - Environment: Injected Provider (MetaMask) for testnet/mainnet, or Remix VM.  
  - Click Deploy and confirm.  
- Interact under “Deployed Contracts”: call createPoll, vote, getPollResults, etc.  
- Optional: Verify contract on an explorer to use Read/Write tabs easily.

### 🧪 Local Development (Hardhat)

Prerequisites: Node.js 18+, Git, a wallet (MetaMask), RPC URL(s) for networks.

1) Clone and install
```
git clone <your-repo-url>
cd <your-repo>
npm install
# or
yarn install
```

If starting fresh:
```
npm install --save-dev hardhat
npx hardhat
# Choose "Create a JavaScript project"
```

Recommended structure:
```
.
├─ contracts/
│  └─ ChainPoll.sol
├─ scripts/
│  ├─ deploy.js
│  └─ interact.js
├─ test/
│  └─ chainpoll.test.js
├─ .env
├─ hardhat.config.js
└─ package.json
```

Example deploy script (scripts/deploy.js):
```js
const hre = require("hardhat");

async function main() {
  const ChainPoll = await hre.ethers.getContractFactory("ChainPoll");
  const chainPoll = await ChainPoll.deploy();
  await chainPoll.deployed();
  console.log("ChainPoll deployed to:", chainPoll.address);
}
main().catch((e) => { console.error(e); process.exitCode = 1; });
```

Hardhat config (hardhat.config.js):
```js
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const { SEPOLIA_RPC_URL, PRIVATE_KEY, ETHERSCAN_API_KEY } = process.env;

module.exports = {
  solidity: "0.8.20",
  networks: {
    hardhat: {},
    sepolia: {
      url: SEPOLIA_RPC_URL || "",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
  },
  etherscan: { apiKey: ETHERSCAN_API_KEY || "" },
};
```

Run a local node and deploy:
```
npx hardhat node
npx hardhat run scripts/deploy.js --network localhost
```

Deploy to Sepolia:
```
npx hardhat run scripts/deploy.js --network sepolia
```

Interact script (scripts/interact.js):
```js
const hre = require("hardhat");
async function main() {
  const addr = process.env.CHAINPOLL_ADDRESS;
  const chainPoll = await hre.ethers.getContractAt("ChainPoll", addr);
  const tx = await chainPoll.createPoll("Best color?", ["Red","Blue","Green"]);
  await tx.wait();
  const [names, counts] = await chainPoll.getPollResults(1);
  console.log("Options:", names);
  console.log("Votes:", counts.map(c => c.toString()));
}
main().catch((e)=>{console.error(e);process.exitCode=1;});
```

Verify (optional):
```
npx hardhat verify --network sepolia 0xYourDeployedAddress
```

Package scripts (package.json):
```json
{
  "scripts": {
    "compile": "hardhat compile",
    "node": "hardhat node",
    "deploy:local": "hardhat run scripts/deploy.js --network localhost",
    "deploy:sepolia": "hardhat run scripts/deploy.js --network sepolia",
    "verify:sepolia": "hardhat verify --network sepolia",
    "test": "hardhat test"
  }
}
```

## 🧭 Usage Cheatsheet

- Create: createPoll("Question?", ["A","B","C"])  
- Vote: vote(1, 0) // option index 0 for poll #1  
- Results: getPollResults(1)  
- Close: closePoll(1) // only poll creator  

## 🧪 Testing (optional)

Example test (test/chainpoll.test.js):
```js
const { expect } = require("chai");

describe("ChainPoll", function () {
  it("creates a poll and records votes", async function () {
    const ChainPoll = await ethers.getContractFactory("ChainPoll");
    const cp = await ChainPoll.deploy();
    await cp.deployed();
    await cp.createPoll("Best color?", ["Red","Blue"]);
    await cp.vote(1, 0);
    const res = await cp.getPollResults(1);
    expect(res[0][0]).to.equal("Red");
    expect(res[1][0]).to.equal(1n);
  });
});
```

Run:
```
npx hardhat test
```

## 🧭 Software Development Plan

Step 1: Smart Contract Core (MVP)  
- Variables: pollCount, polls mapping.  
- Structs: Option { name, voteCount }, Poll { id, question, options[], creator, createdAt, active, hasVoted }.  
- Events: PollCreated, VoteCast, PollClosed.  
- Functions: createPoll, vote, closePoll, getPollInfo, getOption, getPollResults, hasVotedOnPoll.

Step 2: Enhancements  
- Time windows: startAt, endAt; isPollOpen.  
- Admin: optional moderators, pause/unpause.  
- QoL: totalVotes, getAllPollsMeta with pagination.  
- Use custom errors to reduce gas.

Step 3: Testing & Security  
- Unit tests for validation, duplicates, bounds, permissions.  
- Fuzz tests for invariants (one vote per address).  
- Static analysis, gas profiling.

Step 4: Front-End App  
- Stack: React + Vite/Next.js, ethers/viem, wagmi + wallet kit.  
- Pages: Home list, Create Poll, Poll Detail (vote, tallies, creator-only close).  
- UX: network detection, tx toasts, read-only mode.

Step 5: Deployment & Verification  
- Deploy to testnet, record addresses.  
- Verify on explorer for Read/Write tabs.  
- Deploy frontend (Vercel/Netlify), add envs.  
- Smoke test with a sample poll.

## 🌟 Vision Statement

ChainPoll aims to make decision-making open, fair, and verifiable for everyone. By putting polls on-chain, it removes hidden manipulation, enables instant transparency, and builds trust without relying on a central authority. Anyone can create a poll, vote once, and see results that cannot be altered. This project empowers communities, DAOs, classrooms, and teams to make clear, data-driven choices. With simple tools and a friendly interface, ChainPoll lowers barriers to participation and education, inspiring people to learn Web3 while solving real coordination problems at scale.

## 🤝 Contributing

- Open issues for enhancements like time-bound polls ⏰, multi-select voting ☑️, or token-weighted voting 💰.  
- PRs welcome with clear descriptions and tests. ✅

## 📄 License

MIT — Free for personal, educational, and commercial use. 💫

***

⭐ If you like this project, give it a star! ⭐

[1](https://github.com/smartcontractkit/smart-contract-examples)
[2](https://github.com/cleanunicorn/ethereum-smartcontract-template)
[3](https://www.youtube.com/watch?v=eVGEea7adDM)
[4](https://www.makeareadme.com)
[5](https://dev.to/sumonta056/github-readme-template-for-personal-projects-3lka)
[6](https://dev.algorand.co/algokit/official-algokit-templates/)
[7](https://www.youtube.com/watch?v=rCt9DatF63I)
[8](https://bulldogjob.com/readme/how-to-write-a-good-readme-for-your-github-project)
[9](https://www.reddit.com/r/webdev/comments/18sozpf/how_do_you_write_your_readmemd_or_docs_for_your/)
[10](https://readme.so)
