// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ChainEscrow} from "../src/ChainEscrow.sol";
import {ReentrancyAttacker} from "./ReentrancyAttacker.sol";

contract ChainEscrowTest is Test {

    ChainEscrow escrow;

    address client = address(1);
    address freelancer = address(2);
    address arbiter = address(3);

    function setUp() public {
        escrow = new ChainEscrow();
    }

    function testCreateJob() public {
    uint256[] memory amounts = new uint256[](3);

    amounts[0] = 1 ether;
    amounts[1] = 2 ether;
    amounts[2] = 1 ether;

    vm.deal(client, 10 ether);

    vm.prank(client);

    escrow.createJob{value: 4 ether}(
        freelancer,
        arbiter,
        amounts
    );

    assertEq(escrow.nextJobId(), 1);

    (
        address storedClient,
        address storedFreelancer,
        address storedArbiter
    ) = escrow.jobs(0);

    assertEq(storedClient, client);
    assertEq(storedFreelancer, freelancer);
    assertEq(storedArbiter, arbiter);
}
    function testCreateJobIncorrectDeposit() public {
    uint256[] memory amounts = new uint256[](3);

    amounts[0] = 1 ether;
    amounts[1] = 2 ether;
    amounts[2] = 1 ether;

    vm.deal(client, 10 ether);

    vm.prank(client);

    vm.expectRevert("Incorrect deposit");

    escrow.createJob{value: 3 ether}(
        freelancer,
        arbiter,
        amounts
    );
}
    function testCreateJobNeedsAtLeastTwoMilestones() public {
    uint256[] memory amounts = new uint256[](1);

    amounts[0] = 4 ether;

    vm.deal(client, 10 ether);

    vm.prank(client);

    vm.expectRevert("Need at least 2 milestones");

    escrow.createJob{value: 4 ether}(
        freelancer,
        arbiter,
        amounts
    );
}
    function testCreateJobInvalidFreelancer() public {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = 1 ether;
    amounts[1] = 1 ether;

    vm.deal(client, 10 ether);

    vm.prank(client);

    vm.expectRevert("Invalid freelancer");

    escrow.createJob{value: 2 ether}(
        address(0),
        arbiter,
        amounts
    );
}
    function testSubmitMilestone() public {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = 1 ether;
    amounts[1] = 2 ether;

    vm.deal(client, 10 ether);

    vm.prank(client);
    escrow.createJob{value: 3 ether}(
        freelancer,
        arbiter,
        amounts
    );

    vm.prank(freelancer);
    escrow.submitMilestone(0, 0);

    (
        uint256 amount,
        ChainEscrow.MilestoneStatus status
    ) = escrow.getMilestone(0, 0);

    assertEq(amount, 1 ether);
    assertEq(
        uint8(status),
        uint8(ChainEscrow.MilestoneStatus.Submitted)
    );
}
    function testOnlyFreelancerCanSubmit() public {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = 1 ether;
    amounts[1] = 2 ether;

    vm.deal(client, 10 ether);

    vm.prank(client);
    escrow.createJob{value: 3 ether}(
        freelancer,
        arbiter,
        amounts
    );

    // Client tries to submit the milestone
    vm.prank(client);

    vm.expectRevert("Only freelancer");

    escrow.submitMilestone(0, 0);
}
    function testCannotSubmitMilestoneTwice() public {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = 1 ether;
    amounts[1] = 2 ether;

    vm.deal(client, 10 ether);

    vm.prank(client);
    escrow.createJob{value: 3 ether}(
        freelancer,
        arbiter,
        amounts
    );

    // First submission — should work
    vm.prank(freelancer);
    escrow.submitMilestone(0, 0);

    // Second submission — should fail
    vm.prank(freelancer);

    vm.expectRevert("Milestone not pending");

    escrow.submitMilestone(0, 0);
}
    function testApproveMilestonePaysFreelancer() public {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = 1 ether;
    amounts[1] = 2 ether;

    vm.deal(client, 10 ether);

    vm.prank(client);
    escrow.createJob{value: 3 ether}(
        freelancer,
        arbiter,
        amounts
    );

    // Freelancer submits milestone
    vm.prank(freelancer);
    escrow.submitMilestone(0, 0);

    uint256 freelancerBalanceBefore = freelancer.balance;

    // Client approves milestone
    vm.prank(client);
    escrow.approveMilestone(0, 0);

    uint256 freelancerBalanceAfter = freelancer.balance;

    // Freelancer should receive exactly 1 ETH
    assertEq(
        freelancerBalanceAfter - freelancerBalanceBefore,
        1 ether
    );

    // Milestone should now be Approved
    (
        uint256 amount,
        ChainEscrow.MilestoneStatus status
    ) = escrow.getMilestone(0, 0);

    assertEq(amount, 1 ether);
    assertEq(
        uint8(status),
        uint8(ChainEscrow.MilestoneStatus.Approved)
    );
}
    function testOnlyClientCanApprove() public {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = 1 ether;
    amounts[1] = 2 ether;

    vm.deal(client, 10 ether);

    vm.prank(client);
    escrow.createJob{value: 3 ether}(
        freelancer,
        arbiter,
        amounts
    );

    // Freelancer submits milestone
    vm.prank(freelancer);
    escrow.submitMilestone(0, 0);

    // Freelancer tries to approve it
    vm.prank(freelancer);

    vm.expectRevert("Only client");

    escrow.approveMilestone(0, 0);
}
    function testCannotApprovePendingMilestone() public {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = 1 ether;
    amounts[1] = 2 ether;

    vm.deal(client, 10 ether);

    vm.prank(client);
    escrow.createJob{value: 3 ether}(
        freelancer,
        arbiter,
        amounts
    );

    // Milestone is still Pending.
    vm.prank(client);

    vm.expectRevert("Milestone not submitted");

    escrow.approveMilestone(0, 0);
}
    function testCannotApproveMilestoneTwice() public {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = 1 ether;
    amounts[1] = 2 ether;

    vm.deal(client, 10 ether);

    vm.prank(client);
    escrow.createJob{value: 3 ether}(
        freelancer,
        arbiter,
        amounts
    );

    // Freelancer submits
    vm.prank(freelancer);
    escrow.submitMilestone(0, 0);

    // Client approves — first payment
    vm.prank(client);
    escrow.approveMilestone(0, 0);

    // Client tries to approve again
    vm.prank(client);

    vm.expectRevert("Milestone not submitted");

    escrow.approveMilestone(0, 0);
}
    function testClientCanRaiseDispute() public {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = 1 ether;
    amounts[1] = 2 ether;

    vm.deal(client, 10 ether);

    // Create job
    vm.prank(client);
    escrow.createJob{value: 3 ether}(
        freelancer,
        arbiter,
        amounts
    );

    // Freelancer submits milestone
    vm.prank(freelancer);
    escrow.submitMilestone(0, 0);

    // Client raises dispute
    vm.prank(client);
    escrow.raiseDispute(0, 0);

    (, ChainEscrow.MilestoneStatus status) =
        escrow.getMilestone(0, 0);

    assertEq(
        uint8(status),
        uint8(ChainEscrow.MilestoneStatus.Disputed)
    );
}
    function testFreelancerCanRaiseDispute() public {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = 1 ether;
    amounts[1] = 2 ether;

    vm.deal(client, 10 ether);

    // Create job
    vm.prank(client);
    escrow.createJob{value: 3 ether}(
        freelancer,
        arbiter,
        amounts
    );

    // Freelancer submits milestone
    vm.prank(freelancer);
    escrow.submitMilestone(0, 0);

    // Freelancer raises dispute
    vm.prank(freelancer);
    escrow.raiseDispute(0, 0);

    (, ChainEscrow.MilestoneStatus status) =
        escrow.getMilestone(0, 0);

    assertEq(
        uint8(status),
        uint8(ChainEscrow.MilestoneStatus.Disputed)
    );
}
    function testOnlyClientOrFreelancerCanRaiseDispute() public {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = 1 ether;
    amounts[1] = 2 ether;

    vm.deal(client, 10 ether);

    vm.prank(client);
    escrow.createJob{value: 3 ether}(
        freelancer,
        arbiter,
        amounts
    );

    // Freelancer submits milestone
    vm.prank(freelancer);
    escrow.submitMilestone(0, 0);

    // Arbiter tries to raise dispute
    vm.prank(arbiter);

    vm.expectRevert("Not authorized");

    escrow.raiseDispute(0, 0);
}
    function testCannotDisputePendingMilestone() public {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = 1 ether;
    amounts[1] = 2 ether;

    vm.deal(client, 10 ether);

    vm.prank(client);
    escrow.createJob{value: 3 ether}(
        freelancer,
        arbiter,
        amounts
    );

    // Milestone is still Pending.
    vm.prank(client);

    vm.expectRevert("Milestone not submitted");

    escrow.raiseDispute(0, 0);
}
    function testResolveDispute() public {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = 1 ether;
    amounts[1] = 2 ether;

    vm.deal(client, 10 ether);

    // Create job
    vm.prank(client);
    escrow.createJob{value: 3 ether}(
        freelancer,
        arbiter,
        amounts
    );

    // Freelancer submits
    vm.prank(freelancer);
    escrow.submitMilestone(0, 0);

    // Client raises dispute
    vm.prank(client);
    escrow.raiseDispute(0, 0);

    uint256 clientBalanceBefore = client.balance;
    uint256 freelancerBalanceBefore = freelancer.balance;

    // Arbiter resolves: 0.5 ETH to client, 0.5 ETH to freelancer
    vm.prank(arbiter);
    escrow.resolveDispute(
        0,
        0,
        0.5 ether
    );

    uint256 clientBalanceAfter = client.balance;
    uint256 freelancerBalanceAfter = freelancer.balance;

    // Check payments
    assertEq(
        clientBalanceAfter - clientBalanceBefore,
        0.5 ether
    );

    assertEq(
        freelancerBalanceAfter - freelancerBalanceBefore,
        0.5 ether
    );

    // Check state
    (
        uint256 amount,
        ChainEscrow.MilestoneStatus status
    ) = escrow.getMilestone(0, 0);

    assertEq(amount, 1 ether);

    assertEq(
        uint8(status),
        uint8(ChainEscrow.MilestoneStatus.Resolved)
    );
}
    function testOnlyArbiterCanResolve() public {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = 1 ether;
    amounts[1] = 2 ether;

    vm.deal(client, 10 ether);

    // Create job
    vm.prank(client);
    escrow.createJob{value: 3 ether}(
        freelancer,
        arbiter,
        amounts
    );

    // Freelancer submits
    vm.prank(freelancer);
    escrow.submitMilestone(0, 0);

    // Client disputes
    vm.prank(client);
    escrow.raiseDispute(0, 0);

    // Client tries to resolve
    vm.prank(client);

    vm.expectRevert("Only arbiter");

    escrow.resolveDispute(
        0,
        0,
        0.5 ether
    );
}
    function testCannotResolveUndisputedMilestone() public {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = 1 ether;
    amounts[1] = 2 ether;

    vm.deal(client, 10 ether);

    // Create job
    vm.prank(client);
    escrow.createJob{value: 3 ether}(
        freelancer,
        arbiter,
        amounts
    );

    // Freelancer submits
    vm.prank(freelancer);
    escrow.submitMilestone(0, 0);

    // Milestone is Submitted, NOT Disputed.
    vm.prank(arbiter);

    vm.expectRevert("Milestone not disputed");

    escrow.resolveDispute(
        0,
        0,
        0.5 ether
    );
}
    function testClientShareCannotExceedMilestoneAmount() public {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = 1 ether;
    amounts[1] = 2 ether;

    vm.deal(client, 10 ether);

    // Create job
    vm.prank(client);
    escrow.createJob{value: 3 ether}(
        freelancer,
        arbiter,
        amounts
    );

    // Freelancer submits
    vm.prank(freelancer);
    escrow.submitMilestone(0, 0);

    // Client disputes
    vm.prank(client);
    escrow.raiseDispute(0, 0);

    // Arbiter tries to give client more than the 1 ETH milestone
    vm.prank(arbiter);

    vm.expectRevert("Invalid client share");

    escrow.resolveDispute(
        0,
        0,
        1.1 ether
    );
}
    function testContractKeepsFundsForUnresolvedMilestones() public {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = 1 ether;
    amounts[1] = 2 ether;

    vm.deal(client, 10 ether);

    // Client creates job and deposits 3 ETH
    vm.prank(client);
    escrow.createJob{value: 3 ether}(
        freelancer,
        arbiter,
        amounts
    );

    // Contract should now hold all 3 ETH
    assertEq(address(escrow).balance, 3 ether);

    // Freelancer submits milestone 0
    vm.prank(freelancer);
    escrow.submitMilestone(0, 0);

    // Client approves milestone 0
    vm.prank(client);
    escrow.approveMilestone(0, 0);

    // 1 ETH has been paid out.
    // 2 ETH for milestone 1 must still remain locked.
    assertEq(address(escrow).balance, 2 ether);
}
    function testReentrancyAttackFails() public {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = 1 ether;
    amounts[1] = 2 ether;

    vm.deal(client, 10 ether);

    ReentrancyAttacker attacker = new ReentrancyAttacker(escrow);

    // Create job
    vm.prank(client);
    escrow.createJob{value: 3 ether}(
        address(attacker),
        arbiter,
        amounts
    );

    // Attacker submits milestone
    attacker.submitMilestone(0, 0);

    // Client approves.
    // The malicious receive() will attempt reentrancy,
    // causing the transaction to revert.
    vm.prank(client);

    vm.expectRevert("Payment failed");

    escrow.approveMilestone(0, 0);

    // Because the whole transaction reverted,
    // the milestone should still be Submitted.
    (
        ,
        ChainEscrow.MilestoneStatus status
    ) = escrow.getMilestone(0, 0);

    assertEq(
        uint256(status),
        uint256(ChainEscrow.MilestoneStatus.Submitted)
    );

    // All 3 ETH should still be inside the escrow.
    assertEq(address(escrow).balance, 3 ether);
}
    function testCreateJobRejectsZeroMilestone() public {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = 0;
    amounts[1] = 3 ether;

    vm.deal(client, 3 ether);

    vm.prank(client);

    vm.expectRevert("Milestone amount must be positive");

    escrow.createJob{value: 3 ether}(
        freelancer,
        arbiter,
        amounts
    );
}
    function testMilestoneSubmittedEvent() public {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = 1 ether;
    amounts[1] = 2 ether;

    vm.deal(client, 3 ether);

    // Create job
    vm.prank(client);
    escrow.createJob{value: 3 ether}(
        freelancer,
        arbiter,
        amounts
    );

    // Tell Foundry what event we expect
    vm.expectEmit(true, true, false, true);

    emit ChainEscrow.MilestoneSubmitted(0, 0);

    // Freelancer submits milestone
    vm.prank(freelancer);
    escrow.submitMilestone(0, 0);
}
}