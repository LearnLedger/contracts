# <h1 align="center"> Forge Template </h1>

**Template repository for getting started quickly with Foundry projects**

![Github Actions](https://github.com/foundry-rs/forge-template/workflows/CI/badge.svg)

## Getting Started

Click "Use this template" on [GitHub](https://github.com/foundry-rs/forge-template) to create a new repository with this repo as the initial state.

Or, if your repo already exists, run:
```sh
forge init
forge build
forge test
```

## Writing your first test

All you need is to `import forge-std/Test.sol` and then inherit it from your test contract. Forge-std's Test contract comes with a pre-instatiated [cheatcodes environment](https://book.getfoundry.sh/cheatcodes/), the `vm`. It also has support for [ds-test](https://book.getfoundry.sh/reference/ds-test.html)-style logs and assertions. Finally, it supports Hardhat's [console.log](https://github.com/brockelmore/forge-std/blob/master/src/console.sol). The logging functionalities require `-vvvv`.

```solidity
pragma solidity 0.8.10;

import "forge-std/Test.sol";

contract ContractTest is Test {
    function testExample() public {
        vm.roll(100);
        console.log(1);
        emit log("hi");
        assertTrue(true);
    }
}
```

## Development

This project uses [Foundry](https://getfoundry.sh). See the [book](https://book.getfoundry.sh/getting-started/installation.html) for instructions on how to install and use Foundry.

## Project Ledger MVP

### Running Testnet Tests

The testnet test workflow demonstrates the following:

1. Transfers half of LLEDU tokens from the executor wallet to a target wallet
2. Creates a project with the target wallet as the company
3. Makes a submission on behalf of a freelancer wallet
4. Approves the submission
5. Shows token balances at each step

#### Prerequisites

- Foundry installed
- testnet config
- The executor's private key

#### Setup

1. Set the executor's private key as an environment variable:

```bash
export EXECUTOR_PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE
```

2. Run the testnet test script:

```bash
./script/RunTestnetTest.sh
```

This will:
- Connect to the EDUCHAIN testnet
- Transfer half of the LLEDU tokens from the executor to the target wallet (0xDC17577cb8A3e647c49a8d4717D6819D28932bAf)
- Register both company and freelancer wallets
- Create a project using the target wallet
- Create a submission from the freelancer wallet (0xB75682F7bBa3caB29972452DA8737AebFf684e39)
- Approve the submission
- Display token balances throughout the process

#### Testnet Config

-
- RPC_URL=https://rpc.open-campus-codex.gelato.digital
- CHAIN_ID=656476


### Running Real Testnet Workflow

This project includes scripts to run transactions on the actual EDUCHAIN testnet, not in a simulated environment. The workflow demonstrates:

1. Transferring half of LLEDU tokens from the executor wallet to the company wallet
2. Creating a project using the company wallet
3. Submitting work as the freelancer
4. Approving the submission from the company wallet
5. Showing token balances at key steps in the process

#### Prerequisites

- Foundry installed
- Access to EDUCHAIN testnet
- Private keys for all three wallets:
  - Executor (the wallet that deployed the contracts)
  - Company (the wallet that will create the project)
  - Freelancer (the wallet that will make a submission)

#### Setup Private Keys

You have two options for setting up the private keys:

1. **Option 1**: Set them as environment variables:

```bash
export EXECUTOR_PRIVATE_KEY=0xYOUR_EXECUTOR_PRIVATE_KEY
export COMPANY_PRIVATE_KEY=0xYOUR_COMPANY_PRIVATE_KEY
export FREELANCER_PRIVATE_KEY=0xYOUR_FREELANCER_PRIVATE_KEY
```

2. **Option 2**: Add them to your `.env` file:

```
EXECUTOR_PRIVATE_KEY=0xYOUR_EXECUTOR_PRIVATE_KEY
PRIVATE_KEY_COMPANY_2=0xYOUR_COMPANY_PRIVATE_KEY
PRIVATE_KEY_FREELANCER_2=0xYOUR_FREELANCER_PRIVATE_KEY
```

#### Running the Full Workflow

Execute the complete workflow on the real testnet:

```bash
./script/RunRealWorkflow.sh
```

This script will:
1. Check for required private keys and load them if available
2. Connect to the EDUCHAIN testnet
3. Execute the workflow with real transactions
4. Show token balances at each step

#### Running the Partial Workflow

Since testnet transactions may take time to process, you might want to run the workflow in steps:

```bash
./script/RunPartialWorkflow.sh [step] [projectId] [submissionId]
```

Where `[step]` is one of:
- `1`: Executor operations (whitelist token, transfer tokens, register wallets)
- `2`: Company operations (approve tokens, create project)
- `3`: Freelancer operations (create submission) - requires project ID
- `4`: Company approval (approve submission) - requires submission ID
- `5`: Show balances
- `all`: Run all steps (may encounter errors due to timing)

The workflow with parameters:

```bash
# Step 1: Setup executor operations (no parameters needed)
./script/RunPartialWorkflow.sh 1

# Step 2: Run company operations to create a project (no parameters needed)
./script/RunPartialWorkflow.sh 2
# This will output a project ID - COPY IT!

# Step 3: Create a submission using the project ID from step 2
./script/RunPartialWorkflow.sh 3 0x981767e0d5f6713d382ff5e2efdec703dcd847585e8eb2a1ced2654f7560d080
# Replace with your actual project ID
# This will output a submission ID - COPY IT!

# Step 4: Approve submission using the submission ID from step 3
./script/RunPartialWorkflow.sh 4 0x423b12ab3c7fe0bccda08eab23dd4feb56b30e48c26cca9d1d3be16cd33c58e2
# Replace with your actual submission ID

# Step 5: Show final balances
./script/RunPartialWorkflow.sh 5
```

After running step 2, you'll see a clearly marked project ID in the console output that looks like:

```
************************************************
PROJECT CREATED WITH ID:
0x981767e0d5f6713d382ff5e2efdec703dcd847585e8eb2a1ced2654f7560d080
SAVE THIS ID FOR STEP 3
************************************************
```

Similarly, after running step 3, you'll see a submission ID that you'll need for step 4.

#### Project Parameters

The workflow uses the following parameters:
- 1000 LLEDU tokens per project
- The company wallet creates all projects
- The freelancer wallet submits work for each project

#### Direct Scripts for Submissions and Approvals

We've also provided direct scripts for working with projects and submissions by ID:

```bash
# Submit to a project by ID directly:
./script/SubmitToProject.sh <project_id>

# Approve a submission by ID directly:
./script/ApproveSubmission.sh <submission_id>
```

These scripts are easier to use when you already know the project or submission ID from blockchain events or previous transactions.

#### Finding Valid Project IDs

If you're having trouble with project IDs, use the following:

```bash
# List projects and search for valid IDs:
./script/ListAllProjects.sh
```

**Important note about project IDs:** The actual project ID that matters is in the on-chain transaction events. When running step 2 of the workflow, pay close attention to the transaction output in the blockchain explorer, specifically the `ProjectCreated` event which contains the real project ID.

To view the event details:
1. Watch the transaction hash output after running step 2
2. Open that transaction on the EDUCHAIN block explorer
3. Look for the "ProjectCreated" event in the transaction logs
4. Use the project ID from that event when submitting

#### Troubleshooting Project ID Issues

**There's a critical mismatch between returned project IDs and actual stored project IDs.**

The `createProject` function returns a project ID like:
```
0xfc47b858740e1527db0c1ffaa5b1356a5c65398b5b1c6e4eb45c134d524f3f91
```

But the actual project ID saved in the contract (found in the event logs) is different:
```
0x6f8997e2c10931753fadc42be7d4cedcdfacb8624c471689fa609b2c0160b1f3
```

**Solution:** Always use the project ID from the event logs (ProjectCreated event), not the one returned by the function.

**Helpful Tools:**

1. To check submission details:
```bash
./script/CheckSubmission.sh <submission_id>
```

2. To extract project IDs from transaction receipts:
```bash
# Fetch transaction receipt and extract logs
./script/InspectTransaction.sh <transaction_hash>

# This will create a tx_receipt.json file containing the transaction logs
# You can then find the project ID in the topics of the ProjectCreated event
```

#### Wallets & Contracts

- **SMART_CONTRACT_ADDRESS** : 0xc3F785e76e0E07daa7FdE8c2f190bcb8f11a429F
- **LLEDU_TOKEN_ADDRESS** : 0x29668302bf1E11FDc0CC2E01aAEC1e10966F779e
- **Executor Wallet**: 0xB92749d0769EB9fb1B45f2dE0CD51c97aa220f93
- **Company Wallet**: 0xDC17577cb8A3e647c49a8d4717D6819D28932bAf
- **Freelancer Wallet**: 0xB75682F7bBa3caB29972452DA8737AebFf684e39
