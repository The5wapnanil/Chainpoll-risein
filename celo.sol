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
