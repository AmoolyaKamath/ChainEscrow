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
    event JobCreated(
    uint256 indexed jobId,
    address indexed client,
    address indexed freelancer,
    address arbiter
);

event MilestoneSubmitted(
    uint256 indexed jobId,
    uint256 indexed milestoneId
);

event MilestoneApproved(
    uint256 indexed jobId,
    uint256 indexed milestoneId,
    uint256 amount
);

event DisputeRaised(
    uint256 indexed jobId,
    uint256 indexed milestoneId,
    address indexed raisedBy
);

event DisputeResolved(
    uint256 indexed jobId,
    uint256 indexed milestoneId,
    uint256 clientShare,
    uint256 freelancerShare
);
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
            require(amounts[i] > 0, "Milestone amount must be positive");
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
        emit JobCreated(
    nextJobId - 1,
    msg.sender,
    freelancer,
    arbiter
);
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
    emit MilestoneSubmitted(
    jobId,
    milestoneId
);
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
    emit MilestoneApproved(
    jobId,
    milestoneId,
    milestone.amount
);
}
    function raiseDispute(
    uint256 jobId,
    uint256 milestoneId
) external {
    Job storage job = jobs[jobId];

    require(
        msg.sender == job.client || msg.sender == job.freelancer,
        "Not authorized"
    );

    require(
        milestoneId < job.milestones.length,
        "Invalid milestone"
    );

    require(
        job.milestones[milestoneId].status == MilestoneStatus.Submitted,
        "Milestone not submitted"
    );

    job.milestones[milestoneId].status = MilestoneStatus.Disputed;
    emit DisputeRaised(
    jobId,
    milestoneId,
    msg.sender
);
}
    function resolveDispute(
    uint256 jobId,
    uint256 milestoneId,
    uint256 clientShare
) external {
    Job storage job = jobs[jobId];

    require(msg.sender == job.arbiter, "Only arbiter");

    require(
        milestoneId < job.milestones.length,
        "Invalid milestone"
    );

    Milestone storage milestone = job.milestones[milestoneId];

    require(
        milestone.status == MilestoneStatus.Disputed,
        "Milestone not disputed"
    );

    require(
        clientShare <= milestone.amount,
        "Invalid client share"
    );

    uint256 freelancerShare = milestone.amount - clientShare;

    // EFFECT
    milestone.status = MilestoneStatus.Resolved;

    // INTERACTIONS
    (bool clientPaid, ) = payable(job.client).call{
        value: clientShare
    }("");

    require(clientPaid, "Client payment failed");

    (bool freelancerPaid, ) = payable(job.freelancer).call{
        value: freelancerShare
    }("");

    require(freelancerPaid, "Freelancer payment failed");
    emit DisputeResolved(
    jobId,
    milestoneId,
    clientShare,
    freelancerShare
);
}
}