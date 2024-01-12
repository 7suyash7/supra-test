// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {DecentralizedVoting} from "../../src/Assignment-2/DecentralizedVoting.sol";

contract DecentralizedVotingScript is Script {
    DecentralizedVoting decentralizedVoting;

    function setUp() public {
        decentralizedVoting = new DecentralizedVoting();
    }

    function run() public {
        // register some voters
        console.log("Registering voters");
        address voter1 = vm.addr(1);
        vm.broadcast(voter1);
        decentralizedVoting.registerVoter(voter1);

        address voter2 = vm.addr(2);
        vm.broadcast(voter2);
        decentralizedVoting.registerVoter(voter2);
        console.log("Voters Registered!");

        // add candidates
        console.log("Adding Alice as a Candidate");
        vm.broadcast(address(this));
        decentralizedVoting.addCandidate("Alice");
        console.log("Added Alice as a Candidate");

        console.log("Adding Bob as a Candidate");
        vm.broadcast(address(this));
        decentralizedVoting.addCandidate("Bob");
        console.log("Added Bob as a Candidate");

        // voting process
        console.log("Starting the voting process");
        vm.broadcast(voter1);
        decentralizedVoting.vote(0);

        vm.broadcast(voter2);
        decentralizedVoting.vote(1);
        console.log("Voting process finished");

        DecentralizedVoting.Candidate[] memory results = decentralizedVoting.viewResults();

        console.log("Voting Results: ");
        for (uint i = 0; i < results.length; i++) {
            console.log("Candidate ID:", results[i].id);
            console.log("Name:", results[i].name);
            console.log("Vote Count:", results[i].voteCount);
        }
    }
}
