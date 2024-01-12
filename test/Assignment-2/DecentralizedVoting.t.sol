// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {DecentralizedVoting} from "../../src/Assignment-2/DecentralizedVoting.sol";

contract DecentralizedVotingTest is Test {
    DecentralizedVoting dv;
    address voter1;

    function setUp() public {
        dv = new DecentralizedVoting();
        voter1 = address(1);
    }

    // test voter registration
    function testRegisterVoter() public {
        dv.registerVoter(voter1);
        (bool isRegistered,,) = dv.voters(voter1);
        assertTrue(isRegistered);
    }

    // test duplicate voter registration
    function testDuplicateVoter() public {
        dv.registerVoter(voter1);
        (bool isRegistered,,) = dv.voters(voter1);
        assertTrue(isRegistered);

        // Testing duplicate registration should revert
        vm.expectRevert("Voter is already registered");
        dv.registerVoter(voter1);
    }

    // test adding candidate by owner
    function testAddCandidateByOwner() public {
        string memory candidateName = "Candidate 1";
        vm.prank(address(this));
        dv.addCandidate(candidateName);

        (, string memory name, ) = dv.candidates(0);
        assertEq(name, candidateName);
    }

    // test adding candidate by non-owner
    function testAddCandidateByNonOwner() public {
        vm.expectRevert("Only owner can perform this action");
        vm.prank(address(2)); // Mock a non-owner address
        dv.addCandidate("Candidate 2");
    }

    // test successful vote casting
    function testSuccessfulVoting() public {
        address voter = address(1);
        dv.registerVoter(voter);
        dv.addCandidate("Candidate 1");

        vm.prank(voter);
        dv.vote(0);

        (,,uint voteCount) = dv.candidates(0);
        assertEq(voteCount, 1);
    }

    // test double vote casting
    function testDoubleVoting() public {
        address voter = address(1);
        dv.registerVoter(voter);
        dv.addCandidate("Candidate 1");

        vm.prank(voter);
        dv.vote(0);

        vm.expectRevert("You have already voted!!");
        vm.prank(voter);
        dv.vote(0);
    }

    // test vote for non existent candidate
    function testVotingForNonExistentCandidate() public {
        address voter = address(1);
        dv.registerVoter(voter);

        vm.expectRevert("Invalid candidate ID");
        vm.prank(voter);
        dv.vote(0); // No candidate with ID 0 has been added yet
    }

    // test to view results
    function testViewResults() public {
        dv.addCandidate("Candidate 1");
        dv.addCandidate("Candidate 2");
        dv.registerVoter(address(1));
        dv.registerVoter(address(2));

        vm.prank(address(1));
        dv.vote(0);
        vm.prank(address(2));
        dv.vote(1);

        DecentralizedVoting.Candidate[] memory results = dv.viewResults();
        assertEq(results[0].voteCount, 1);
        assertEq(results[1].voteCount, 1);
    }

    // test contract initialization and ownership
    function testContractInitializationAndOwnership() public {
        address expectedOwner = address(this); // As the contract is deployed by this test
        assertEq(dv.owner(), expectedOwner, "Owner should be the contract deployer");
    }

    // test vote count math
    function testVoteCountIntegrity() public {
        dv.addCandidate("Candidate 1");
        dv.addCandidate("Candidate 2");

        dv.registerVoter(voter1);
        dv.registerVoter(address(2));

        vm.prank(voter1);
        dv.vote(0);
        vm.prank(address(2));
        dv.vote(1);

        (,,uint voteCount1) = dv.candidates(0);
        (,,uint voteCount2) = dv.candidates(1);
        assertEq(voteCount1, 1, "Candidate 1 should have 1 vote");
        assertEq(voteCount2, 1, "Candidate 2 should have 1 vote");
    }

    // vote without registration
    function testVoteWithoutRegistration() public {
        address unregisteredVoter = address(3);
        dv.addCandidate("Candidate 1"); // Adding a candidate for voting

        vm.expectRevert("You must be registered to vote!");
        vm.prank(unregisteredVoter);
        dv.vote(0);
    }

    // test reverts
    function testRegisterWithInvalidInput() public {
        vm.expectRevert("Invalid voter address");
        dv.registerVoter(address(0));
    }

    function testAddCandidateWithInvalidInput() public {
        vm.expectRevert("Candidate name cannot be empty");
        dv.addCandidate("");
    }
}