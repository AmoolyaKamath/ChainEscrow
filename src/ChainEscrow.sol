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

        uint256 total=0;

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
    function submitMilestone(
    uint256 jobId,
    uint256 milestoneId
) external {
    Job storage job = jobs[jobId];

    require(msg.sender == job.freelancer, "Only freelancer");

    require(
        milestoneId < job.milestones.length,
        "Invalid milestone"
    );

    require(
        job.milestones[milestoneId].status == MilestoneStatus.Pending,
        "Milestone not pending"
    );

    job.milestones[milestoneId].status = MilestoneStatus.Submitted;
}
    function getMilestone(
    uint256 jobId,
    uint256 milestoneId
) external view returns (
    uint256 amount,
    MilestoneStatus status
) {
    Milestone storage milestone = jobs[jobId].milestones[milestoneId];

    return (
        milestone.amount,
        milestone.status
    );
}
    function approveMilestone(
    uint256 jobId,
    uint256 milestoneId
) external {
    Job storage job = jobs[jobId];

    require(msg.sender == job.client, "Only client");

    require(
        milestoneId < job.milestones.length,
        "Invalid milestone"
    );

    Milestone storage milestone = job.milestones[milestoneId];

    require(
        milestone.status == MilestoneStatus.Submitted,
        "Milestone not submitted"
    );

    // EFFECT-change status first and then transfer eth
    milestone.status = MilestoneStatus.Approved;

    // INTERACTION
    (bool success, ) = payable(job.freelancer).call{
        value: milestone.amount
    }("");

    require(success, "Payment failed");
}
}