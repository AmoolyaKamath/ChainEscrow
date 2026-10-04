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
    function createJob(
        address freelancer,
        address arbiter,
        uint256[] calldata amounts
    ) external payable {

        require(freelancer != address(0), "Invalid freelancer");
        require(arbiter != address(0), "Invalid arbiter");
        require(amounts.length >= 2, "Need at least 2 milestones");

        uint256 total;

        for (uint256 i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }

        require(total == msg.value, "Incorrect deposit");

        Job storage job = jobs[nextJobId];

        job.client = msg.sender;
        job.freelancer = freelancer;
        job.arbiter = arbiter;

        for (uint256 i = 0; i < amounts.length; i++) {
            job.milestones.push(
                Milestone({
                    amount: amounts[i],
                    status: MilestoneStatus.Pending
                })
            );
        }

        nextJobId++;
    }
}