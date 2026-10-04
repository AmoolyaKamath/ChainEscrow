// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ChainEscrow} from "../src/ChainEscrow.sol";

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
}