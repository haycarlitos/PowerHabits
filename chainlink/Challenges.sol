// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract HabitChallenge is Ownable {

    struct AirdropChallenge {
        string title;
        uint256 reward;
        uint256 goal;
        mapping(address => bool) participants;
        bool exists;
    }

    struct CustomChallenge {
        string title;
        uint256 goal;
        uint256 stake;
        mapping(address => bool) participants;
        bool exists;
    }

    mapping(uint256 => AirdropChallenge) public airdropChallenges;
    mapping(uint256 => CustomChallenge) public customChallenges;

    uint256 public airdropChallengeCount;
    uint256 public customChallengeCount;

    event AirdropChallengeCreated(uint256 challengeId, string title, uint256 reward, uint256 goal);
    event CustomChallengeCreated(uint256 challengeId, string title, uint256 goal, uint256 stake);
    event JoinedAirdropChallenge(address participant, uint256 challengeId);
    event JoinedCustomChallenge(address participant, uint256 challengeId);
    event CompletedAirdropChallenge(address participant, uint256 challengeId);
    event CompletedCustomChallenge(address participant, uint256 challengeId, uint256 reward);

    constructor() Ownable(msg.sender) {}

    function createAirdropChallenge(string memory title, uint256 reward, uint256 goal) external onlyOwner {
        airdropChallenges[airdropChallengeCount].title = title;
        airdropChallenges[airdropChallengeCount].reward = reward;
        airdropChallenges[airdropChallengeCount].goal = goal;
        airdropChallenges[airdropChallengeCount].exists = true;
        emit AirdropChallengeCreated(airdropChallengeCount, title, reward, goal);
        airdropChallengeCount++;
    }

    function createCustomChallenge(string memory title, uint256 goal) external payable {
        require(msg.value > 0, "Stake amount must be greater than zero");
        
        customChallenges[customChallengeCount].title = title;
        customChallenges[customChallengeCount].goal = goal;
        customChallenges[customChallengeCount].stake = msg.value;
        customChallenges[customChallengeCount].exists = true;
        emit CustomChallengeCreated(customChallengeCount, title, goal, msg.value);
        customChallengeCount++;
    }

    function joinAirdropChallenge(uint256 challengeId) external payable {
        require(airdropChallenges[challengeId].exists, "Challenge does not exist");
        require(!airdropChallenges[challengeId].participants[msg.sender], "Already joined");
        airdropChallenges[challengeId].participants[msg.sender] = true;
        emit JoinedAirdropChallenge(msg.sender, challengeId);
    }

    function joinCustomChallenge(uint256 challengeId) external payable {
        require(customChallenges[challengeId].exists, "Challenge does not exist");
        require(!customChallenges[challengeId].participants[msg.sender], "Already joined");
        require(msg.value == customChallenges[challengeId].stake, "Incorrect stake amount");
        customChallenges[challengeId].participants[msg.sender] = true;
        emit JoinedCustomChallenge(msg.sender, challengeId);
    }

    function completeAirdropChallenge(uint256 challengeId, uint256 goalResult, address user) external onlyOwner {
        require(airdropChallenges[challengeId].exists, "Challenge does not exist");
        require(airdropChallenges[challengeId].participants[user], "Not a participant");
        /// CHAINLINK LOGIC
        require(goalResult >= airdropChallenges[challengeId].goal, "Goal not met");
        
        airdropChallenges[challengeId].participants[user] = false; // Prevent re-entry
        payable(user).transfer(airdropChallenges[challengeId].reward);
        
        emit CompletedAirdropChallenge(user, challengeId);
    }

    function completeCustomChallenge(uint256 challengeId, uint256 goalResult, address user) external onlyOwner {
        require(customChallenges[challengeId].exists, "Challenge does not exist");
        require(customChallenges[challengeId].participants[user], "Not a participant");
        /// CHAINLINK LOGIC

        require(goalResult >= customChallenges[challengeId].goal, "Goal not met");
        
        customChallenges[challengeId].participants[user] = false; // Prevent re-entry
        uint256 reward = customChallenges[challengeId].stake * 2; // Example reward logic
        
        payable(user).transfer(reward);
        
        emit CompletedCustomChallenge(user, challengeId, reward);
    }
}