// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ChainEscrow {

    enum MilestoneStatus {
        Pending,
        Submitted,
        Approved,
        Disputed,
        Resolved
    }

    struct Milestone {
        uint256 amount;
        MilestoneStatus status;
    }

    struct Job {
        address client;
        address freelancer;
        address arbiter;
        Milestone[] milestones;
    }

    mapping(uint256 => Job) public jobs;

    uint256 public nextJobId;
}