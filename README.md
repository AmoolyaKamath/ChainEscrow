# ChainEscrow
ChainEscrow is a decentralized milestone-based escrow application for freelance payments. The client deposits the total payment into a smart contract, and the money is released milestone by milestone when the client approves the submitted work. If there is a dispute, an arbiter can decide how the milestone amount should be divided between the client and freelancer.
## Features
- Create a job with multiple milestones
- Client deposits the full job amount when creating the job
- Freelancer can submit milestones
- Client can approve milestones and release payment
- Client or freelancer can raise a dispute
- Arbiter can resolve a disputed milestone
- MetaMask wallet connection
- Role-based actions for client, freelancer and arbiter
- View job and milestone status directly from the blockchain
- Deployed on Ethereum Sepolia testnet
## How it works
The client creates a job by providing the freelancer address, arbiter address and milestone amounts. The total of the milestone amounts must match the ETH deposited into the contract.
A milestone starts as `Pending`. The freelancer submits it, changing its status to `Submitted`. The client can then approve it, which changes the status to `Approved` and transfers the milestone amount to the freelancer.
If there is a disagreement, either the client or freelancer can raise a dispute. The milestone becomes `Disputed`. The arbiter can then resolve it by specifying how much should go to the client. The remaining amount is sent to the freelancer and the milestone becomes `Resolved`.
## Milestone states
`Pending → Submitted → Approved`
or
`Pending → Submitted → Disputed → Resolved`
The contract checks the current state before allowing each action, so milestones cannot be submitted, approved or resolved more than once.
## Smart contract
The main contract is located at `src/ChainEscrow.sol`.
Important functions include:
- `createJob()` - creates a job and deposits the total amount
- `submitMilestone()` - submits a milestone as the freelancer
- `approveMilestone()` - approves and pays a milestone as the client
- `raiseDispute()` - raises a dispute
- `resolveDispute()` - resolves a dispute as the arbiter
- `getMilestone()` - gets milestone details
- `getMilestoneCount()` - gets the number of milestones in a job
## Security
The contract uses the Checks-Effects-Interactions pattern when sending ETH. The milestone status is changed before the external payment call.
A reentrancy attack test is also included. The test uses a malicious contract which tries to call `approveMilestone()` again during the payment. Since the milestone has already been changed to `Approved`, the second call fails and the transaction is reverted.
The contract also checks that only the correct client, freelancer or arbiter can perform each action and validates milestone IDs, amounts and milestone states.
## Testing
The project uses Foundry.
Run:
`forge test`
Current result:
`23 tests passed, 0 failed`
The tests cover job creation, milestone submission, payments, disputes, access control, fund custody and reentrancy.
## Deployment
The contract is deployed on the Sepolia testnet.
Contract address:
`0x5eEF60af6DFfE9ef826ba6c54C21Bf2FBD12828F`
Etherscan:
https://sepolia.etherscan.io/address/0x5eef60af6dffe9ef826ba6c54c21bf2fbd12828f
## Frontend
The frontend is built using React, Vite and ethers.js.
It allows users to connect MetaMask, create and view jobs, submit milestones, approve payments, raise disputes and resolve disputes depending on their role.
The frontend is inside the `frontend` folder.
To run it:
`cd frontend`
`npm install`
`npm run dev`
The application runs at `http://localhost:5173`.
MetaMask should be connected to the Sepolia network.
## Project structure
`src/` contains the smart contract.
`test/` contains the Foundry tests.
`script/` contains the deployment script.
`frontend/` contains the React frontend.
## Tech stack
Solidity, Foundry, React, Vite, ethers.js, MetaMask and Ethereum Sepolia.
## Future improvements
Some possible improvements are ERC-20 token support, deadlines and refunds, OpenZeppelin ReentrancyGuard, better transaction error messages and an activity history in the frontend.
