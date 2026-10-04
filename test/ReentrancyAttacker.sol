// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ChainEscrow} from "../src/ChainEscrow.sol";

contract ReentrancyAttacker {

    ChainEscrow public escrow;

    uint256 public jobId;
    uint256 public milestoneId;

    constructor(ChainEscrow _escrow) {
        escrow = _escrow;
    }

    function attack(
        uint256 _jobId,
        uint256 _milestoneId
    ) external {
        jobId = _jobId;
        milestoneId = _milestoneId;

        escrow.approveMilestone(
            _jobId,
            _milestoneId
        );
    }

    receive() external payable {
        // Try to call approveMilestone again
        escrow.approveMilestone(
            jobId,
            milestoneId
        );
    }
    function submitMilestone(
    uint256 _jobId,
    uint256 _milestoneId
) external {
    escrow.submitMilestone(_jobId, _milestoneId);
}
}