// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

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
    event ResponseReceived(bytes32 requestId, uint256 steps);

    bytes32 public s_lastRequestId;
    uint256 public s_lastSteps;
    bytes public s_lastResponse;
    bytes public s_lastError;

    address router = 0xf9B8fc078197181C841c296C876945aaa425B278;
    bytes32 donID =
        0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;

    uint32 gasLimit = 300000;

    constructor() FunctionsClient(router) ConfirmedOwner(msg.sender) {}

    function sendRequest(uint64 subscriptionId, string memory userId) public onlyOwner returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        string memory source = string(abi.encodePacked(
            "const config = { url: 'https://powerhabits-server.vercel.app/api/health?userId=", userId, "' };",
            "const response = await Functions.makeHttpRequest(config);",
            "const steps = response.data.steps;",
            "return Functions.encodeUint256(steps);"
        ));
        req.initializeRequestForInlineJavaScript(source);
        s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, gasLimit, donID);
        return s_lastRequestId;
    }

    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        require(s_lastRequestId == requestId, "Unexpected request ID");
        s_lastResponse = response;
        s_lastError = err;
        s_lastSteps = abi.decode(response, (uint256));
        emit ResponseReceived(requestId, s_lastSteps);
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
