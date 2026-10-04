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
}