// pragma solidity ^0.8.0;

// contract DecentralizedVoting {

//     // struct to store voters
//     struct Voter {
//         bool isRegistered;
//         bool hasVoted;
//         uint vote;
//     }

//     // struct to store candidates
//     struct Candidate {
//         uint id;
//         string name;
//         uint voteCount;
//     }

//     address public owner;
//     mapping(address => Voter) public voters;
//     Candidate[] public candidates;

//     constructor() {
//         owner = msg.sender;
//     }


//     modifier onlyOwner() {
//         require(msg.sender == owner, "Only owner can perform this action");
//         _;
//     }

//     // events
//     event CandidateAdded(uint candidateId, string name);
//     event Voted(address voter, uint candidateId);

//     // register a voter
//     function registerVoter(address voterAddress) public {
//         require(voterAddress != address(0), "Invalid voter address");
//         require(!voters[voterAddress].isRegistered, "Voter is already registered, cannot vote twice");
//         voters[voterAddress] = Voter(true, false, 0);
//     }

//     // add a candidate
//     function addCandidate(string memory name) public onlyOwner {
//         require(bytes(name).length > 0, "Candidate name cannot be empty");
//         candidates.push(Candidate(candidates.length, name, 0));
//     }

//     // cast a vote
//     function vote(uint candidateId) public {
//         Voter storage sender = voters[msg.sender];
//         require(sender.isRegistered, "You must be registered to vote!");
//         require(!sender.hasVoted, "You have already voted!!");

//         require(candidateId < candidates.length, "Invalid candidate ID");

//         sender.hasVoted = true;
//         sender.vote = candidateId;

//         candidates[candidateId].voteCount += 1;

//         emit Voted(msg.sender, candidateId);
//     }

//     // view results of the poll
//     function viewResults() public view returns (Candidate[] memory) {
//         return candidates;
//     }

// }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DecentralizedVoting is ReentrancyGuard {

    // struct to store voters
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint vote;
    }

    // struct to store candidates
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    address public owner;
    mapping(address => Voter) public voters;
    Candidate[] public candidates;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    // events
    event CandidateAdded(uint candidateId, string name);
    event Voted(address voter, uint candidateId);

    // register a voter
    function registerVoter(address voterAddress) public {
        require(voterAddress != address(0), "Invalid voter address");
        require(!voters[voterAddress].isRegistered, "Voter is already registered");
        voters[voterAddress] = Voter(true, false, 0);
    }

    // add a candidate
    function addCandidate(string memory name) public onlyOwner {
        require(bytes(name).length > 0, "Candidate name cannot be empty");
        candidates.push(Candidate(candidates.length, name, 0));
        emit CandidateAdded(candidates.length - 1, name);
    }

    // cast a vote
    function vote(uint candidateId) public nonReentrant {
        Voter storage sender = voters[msg.sender];
        require(sender.isRegistered, "You must be registered to vote!");
        require(!sender.hasVoted, "You have already voted!!");
        require(candidateId < candidates.length, "Invalid candidate ID");

        sender.hasVoted = true;
        sender.vote = candidateId;

        candidates[candidateId].voteCount += 1;

        emit Voted(msg.sender, candidateId);
    }

    // view results of the poll
    function viewResults() public view returns (Candidate[] memory) {
        return candidates;
    }
}
