// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {FunctionsClient} from "@chainlink/contracts@1.1.1/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts@1.1.1/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts@1.1.1/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

/**
 * @title HabitChallenge
 * @notice This contract allows the creation and management of fitness challenges and integrates Chainlink Functions to fetch data from an external API.
 */
contract HabitChallenge is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

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
    event ResponseReceived(bytes32 indexed requestId, uint256 steps, bytes response, bytes err);

    bytes32 public s_lastRequestId;
    uint256 public s_lastSteps;
    bytes public s_lastResponse;
    bytes public s_lastError;

    address router = 0xf9B8fc078197181C841c296C876945aaa425B278;
    bytes32 donID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;
   
    string source = 
        "const config = { url: 'https://powerhabits-server.vercel.app/api/health' };"
        "const response = await Functions.makeHttpRequest(config);"
        "const steps = response.data.steps;"
        "return Functions.encodeUint256(steps);";
    
    uint32 gasLimit = 300000;

    constructor() FunctionsClient(router) ConfirmedOwner(msg.sender) {}


    function createAirdropChallenge(string memory title, uint256 reward, uint256 goal) external onlyOwner {
        require(address(this).balance >= reward, "Insufficient contract balance");
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

    function joinAirdropChallenge(uint256 challengeId) external {
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

    function getAirdropChallenge(uint256 challengeId) public view returns (string memory title, uint256 reward, uint256 goal, bool exists) {
        AirdropChallenge storage challenge = airdropChallenges[challengeId];
        return (challenge.title, challenge.reward, challenge.goal, challenge.exists);
    }

    function getCustomChallenge(uint256 challengeId) public view returns (string memory title, uint256 goal, uint256 stake, bool exists) {
        CustomChallenge storage challenge = customChallenges[challengeId];
        return (challenge.title, challenge.goal, challenge.stake, challenge.exists);
    }

    function sendRequest(uint64 subscriptionId) external onlyOwner returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;

        req.initializeRequestForInlineJavaScript(source);

        s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, gasLimit, donID);
        return s_lastRequestId;
    }

    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if (s_lastRequestId != requestId) {
            revert("Unexpected request ID"); // Check if request IDs match
        }
        s_lastResponse = response;
        s_lastError = err;
        s_lastSteps = abi.decode(response, (uint256));
        emit ResponseReceived(requestId, s_lastSteps, response, err);
    }

    function completeAirdropChallenge(uint256 challengeId, address user) external onlyOwner {
        require(airdropChallenges[challengeId].exists, "Challenge does not exist");
        require(airdropChallenges[challengeId].participants[user], "Not a participant");
        uint256 goalResult = s_lastSteps; // Use the Chainlink response

        require(goalResult >= airdropChallenges[challengeId].goal, "Goal not met");
        airdropChallenges[challengeId].participants[user] = false;
        payable(user).transfer(airdropChallenges[challengeId].reward);
        emit CompletedAirdropChallenge(user, challengeId);
    }

    function completeCustomChallenge(uint256 challengeId, address user) external onlyOwner {
        require(customChallenges[challengeId].exists, "Challenge does not exist");
        require(customChallenges[challengeId].participants[user], "Not a participant");
        uint256 goalResult = s_lastSteps; // Use the Chainlink response

        require(goalResult >= customChallenges[challengeId].goal, "Goal not met");
        customChallenges[challengeId].participants[user] = false;
        uint256 reward = customChallenges[challengeId].stake * 2; // Example reward logic
        payable(user).transfer(reward);
        emit CompletedCustomChallenge(user, challengeId, reward);
    }
}
