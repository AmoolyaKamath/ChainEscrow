import { useState, useEffect } from "react";
import { ethers } from "ethers";
import abi from "./abi.json";

const CONTRACT_ADDRESS =
  "0x5eEF60af6DFfE9ef826ba6c54C21Bf2FBD12828F";

function App() {
  const [account, setAccount] = useState("");

  // Create Job
  const [freelancer, setFreelancer] = useState("");
  const [arbiter, setArbiter] = useState("");
  const [amounts, setAmounts] = useState("");

  // View Job
  const [jobId, setJobId] = useState("");
  const [jobDetails, setJobDetails] = useState(null);
  const [userRole, setUserRole] = useState("");

  // Actions
  const [milestoneId, setMilestoneId] = useState("");
  const [clientShare, setClientShare] = useState("");

  const [message, setMessage] = useState("");

  // ---------------- ACCOUNT CHANGE LISTENER ----------------

  useEffect(() => {
    if (!window.ethereum) return;

    function handleAccountsChanged(accounts) {
      if (accounts.length === 0) {
        setAccount("");
        setJobDetails(null);
        setUserRole("");
        setMessage("Wallet disconnected.");
      } else {
        setAccount(accounts[0]);
        setJobDetails(null);
        setUserRole("");
        setMessage("Account changed. Click View Job again.");
      }
    }

    window.ethereum.on(
      "accountsChanged",
      handleAccountsChanged
    );

    return () => {
      window.ethereum.removeListener(
        "accountsChanged",
        handleAccountsChanged
      );
    };
  }, []);

  // ---------------- CONNECT WALLET ----------------

  async function connectWallet() {
    try {
      if (!window.ethereum) {
        alert("Please install MetaMask");
        return;
      }

      const provider = new ethers.BrowserProvider(
        window.ethereum
      );

      const accounts = await provider.send(
        "eth_requestAccounts",
        []
      );

      setAccount(accounts[0]);
      setMessage("Wallet connected.");
    } catch (error) {
      console.error(error);
      setMessage("Could not connect wallet.");
    }
  }

  // ---------------- CREATE JOB ----------------

  async function createJob() {
    try {
      if (!window.ethereum) {
        alert("Please install MetaMask");
        return;
      }

      const provider = new ethers.BrowserProvider(
        window.ethereum
      );

      const signer = await provider.getSigner();

      const contract = new ethers.Contract(
        CONTRACT_ADDRESS,
        abi,
        signer
      );

      const amountList = amounts
        .split(",")
        .map((amount) => amount.trim());

      if (amountList.length < 2) {
        setMessage(
          "Enter at least 2 milestone amounts."
        );
        return;
      }

      const milestoneAmounts = amountList.map(
        (amount) => ethers.parseEther(amount)
      );

      const total = milestoneAmounts.reduce(
        (sum, amount) => sum + amount,
        0n
      );

      setMessage(
        "Confirm the transaction in MetaMask..."
      );

      const tx = await contract.createJob(
        freelancer,
        arbiter,
        milestoneAmounts,
        {
          value: total,
        }
      );

      setMessage(
        "Transaction submitted. Waiting for confirmation..."
      );

      await tx.wait();

      setMessage(
        "Job created successfully!"
      );

      setFreelancer("");
      setArbiter("");
      setAmounts("");

    } catch (error) {
      console.error(error);
      setMessage(
        "Transaction failed. Check console."
      );
    }
  }

  // ---------------- VIEW JOB ----------------

  async function viewJob() {
    try {
      if (!window.ethereum) {
        alert("Please install MetaMask");
        return;
      }

      if (jobId === "") {
        setMessage("Enter a Job ID.");
        return;
      }

      const provider = new ethers.BrowserProvider(
        window.ethereum
      );

      const contract = new ethers.Contract(
        CONTRACT_ADDRESS,
        abi,
        provider
      );

      const job = await contract.jobs(jobId);

      const milestoneCount =
        await contract.getMilestoneCount(jobId);

      const milestones = [];

      for (
        let i = 0;
        i < Number(milestoneCount);
        i++
      ) {
        const milestone =
          await contract.getMilestone(
            jobId,
            i
          );

        milestones.push({
          id: i,
          amount: ethers.formatEther(
            milestone[0]
          ),
          status: Number(milestone[1]),
        });
      }

      setJobDetails({
        client: job[0],
        freelancer: job[1],
        arbiter: job[2],
        milestones: milestones,
      });

      // Determine role of connected wallet

      const connectedAddress =
        account.toLowerCase();

      if (
        connectedAddress ===
        job[0].toLowerCase()
      ) {
        setUserRole("client");
      } else if (
        connectedAddress ===
        job[1].toLowerCase()
      ) {
        setUserRole("freelancer");
      } else if (
        connectedAddress ===
        job[2].toLowerCase()
      ) {
        setUserRole("arbiter");
      } else {
        setUserRole("none");
      }

      setMessage("Job loaded.");

    } catch (error) {
      console.error(error);

      setMessage(
        "Could not load job. Check Job ID and contract."
      );
    }
  }

  // ---------------- SUBMIT MILESTONE ----------------

  async function submitMilestone() {
    try {
      const provider = new ethers.BrowserProvider(
        window.ethereum
      );

      const signer = await provider.getSigner();

      const contract = new ethers.Contract(
        CONTRACT_ADDRESS,
        abi,
        signer
      );

      setMessage(
        "Confirm submission in MetaMask..."
      );

      const tx =
        await contract.submitMilestone(
          jobId,
          milestoneId
        );

      await tx.wait();

      setMessage(
        "Milestone submitted successfully!"
      );

      await viewJob();

    } catch (error) {
      console.error(error);

      setMessage(
        "Could not submit milestone."
      );
    }
  }

  // ---------------- APPROVE MILESTONE ----------------

  async function approveMilestone() {
    try {
      const provider = new ethers.BrowserProvider(
        window.ethereum
      );

      const signer = await provider.getSigner();

      const contract = new ethers.Contract(
        CONTRACT_ADDRESS,
        abi,
        signer
      );

      setMessage(
        "Confirm approval in MetaMask..."
      );

      const tx =
        await contract.approveMilestone(
          jobId,
          milestoneId
        );

      await tx.wait();

      setMessage(
        "Milestone approved and paid!"
      );

      await viewJob();

    } catch (error) {
      console.error(error);

      setMessage(
        "Could not approve milestone."
      );
    }
  }

  // ---------------- RAISE DISPUTE ----------------

  async function raiseDispute() {
    try {
      const provider = new ethers.BrowserProvider(
        window.ethereum
      );

      const signer = await provider.getSigner();

      const contract = new ethers.Contract(
        CONTRACT_ADDRESS,
        abi,
        signer
      );

      setMessage(
        "Confirm dispute in MetaMask..."
      );

      const tx =
        await contract.raiseDispute(
          jobId,
          milestoneId
        );

      await tx.wait();

      setMessage(
        "Dispute raised successfully!"
      );

      await viewJob();

    } catch (error) {
      console.error(error);

      setMessage(
        "Could not raise dispute."
      );
    }
  }

  // ---------------- RESOLVE DISPUTE ----------------

  async function resolveDispute() {
    try {
      const provider = new ethers.BrowserProvider(
        window.ethereum
      );

      const signer = await provider.getSigner();

      const contract = new ethers.Contract(
        CONTRACT_ADDRESS,
        abi,
        signer
      );

      if (clientShare === "") {
        setMessage(
          "Enter the client's share."
        );
        return;
      }

      const clientShareWei =
        ethers.parseEther(clientShare);

      setMessage(
        "Confirm dispute resolution in MetaMask..."
      );

      const tx =
        await contract.resolveDispute(
          jobId,
          milestoneId,
          clientShareWei
        );

      await tx.wait();

      setMessage(
        "Dispute resolved successfully!"
      );

      await viewJob();

    } catch (error) {
      console.error(error);

      setMessage(
        "Could not resolve dispute."
      );
    }
  }

  // ---------------- STATUS TEXT ----------------

  function getStatus(status) {
    const statuses = [
      "Pending",
      "Submitted",
      "Approved",
      "Disputed",
      "Resolved",
    ];

    return statuses[status] || "Unknown";
  }

  // ---------------- UI ----------------

  return (
    <div className="container">

      <h1>ChainEscrow</h1>

      <p>
        Decentralized Milestone Escrow
      </p>

      {!account ? (

        <button onClick={connectWallet}>
          Connect MetaMask
        </button>

      ) : (

        <>

          {/* WALLET */}

          <div className="card">

            <h2>Wallet</h2>

            <p>
              Connected:
            </p>

            <small>
              {account}
            </small>

          </div>


          {/* CREATE JOB */}

          <div className="card">

            <h2>Create Job</h2>

            <input
              type="text"
              placeholder="Freelancer address"
              value={freelancer}
              onChange={(e) =>
                setFreelancer(e.target.value)
              }
            />

            <input
              type="text"
              placeholder="Arbiter address"
              value={arbiter}
              onChange={(e) =>
                setArbiter(e.target.value)
              }
            />

            <input
              type="text"
              placeholder="Milestones e.g. 0.001, 0.002"
              value={amounts}
              onChange={(e) =>
                setAmounts(e.target.value)
              }
            />

            <button onClick={createJob}>
              Create Job
            </button>

          </div>


          {/* VIEW JOB */}

          <div className="card">

            <h2>View Job</h2>

            <input
              type="number"
              placeholder="Job ID"
              value={jobId}
              onChange={(e) =>
                setJobId(e.target.value)
              }
            />

            <button onClick={viewJob}>
              View Job
            </button>

          </div>


          {/* JOB DETAILS */}

          {jobDetails && (

            <div className="card">

              <h2>
                Job #{jobId}
              </h2>

              <p>
                <strong>Client:</strong>{" "}
                {jobDetails.client}
              </p>

              <p>
                <strong>Freelancer:</strong>{" "}
                {jobDetails.freelancer}
              </p>

              <p>
                <strong>Arbiter:</strong>{" "}
                {jobDetails.arbiter}
              </p>

              <p>
                <strong>Your Role:</strong>{" "}
                {userRole.toUpperCase()}
              </p>

              <h3>
                Milestones
              </h3>

              {jobDetails.milestones.map(
                (milestone) => (

                  <div
                    className="milestone"
                    key={milestone.id}
                  >

                    <h4>
                      Milestone {milestone.id}
                    </h4>

                    <p>
                      Amount:{" "}
                      {milestone.amount} ETH
                    </p>

                    <p>
                      Status:{" "}
                      <strong>
                        {getStatus(
                          milestone.status
                        )}
                      </strong>
                    </p>

                  </div>

                )
              )}

            </div>

          )}


          {/* ROLE-BASED ACTIONS */}

          {jobDetails && (

            <div className="card">

              <h2>
                Milestone Actions
              </h2>

              <p>
                Your role:{" "}
                <strong>
                  {userRole.toUpperCase()}
                </strong>
              </p>

              <input
                type="number"
                placeholder="Milestone ID"
                value={milestoneId}
                onChange={(e) =>
                  setMilestoneId(
                    e.target.value
                  )
                }
              />


              {/* FREELANCER */}

              {userRole === "freelancer" && (

                <>

                  <button
                    onClick={submitMilestone}
                  >
                    Submit Milestone
                  </button>

                  <button
                    onClick={raiseDispute}
                  >
                    Raise Dispute
                  </button>

                </>

              )}


              {/* CLIENT */}

              {userRole === "client" && (

                <>

                  <button
                    onClick={approveMilestone}
                  >
                    Approve Milestone
                  </button>

                  <button
                    onClick={raiseDispute}
                  >
                    Raise Dispute
                  </button>

                </>

              )}


              {/* ARBITER */}

              {userRole === "arbiter" && (

                <>

                  <input
                    type="text"
                    placeholder="Client share in ETH"
                    value={clientShare}
                    onChange={(e) =>
                      setClientShare(
                        e.target.value
                      )
                    }
                  />

                  <button
                    onClick={resolveDispute}
                  >
                    Resolve Dispute
                  </button>

                  <p>
                    The remaining amount will
                    be paid to the freelancer.
                  </p>

                </>

              )}


              {/* NOT A PARTICIPANT */}

              {userRole === "none" && (

                <p>
                  You are not a participant
                  in this job.
                </p>

              )}

            </div>

          )}


          {/* MESSAGE */}

          <div className="message">
            {message}
          </div>

        </>

      )}

    </div>
  );
}

export default App;