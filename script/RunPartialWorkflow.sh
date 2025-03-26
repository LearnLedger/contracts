#!/bin/bash

# Exit if any command fails
set -e

# Source the .env file
if [ -f .env ]; then
  echo "Loading configuration from .env file..."
  source .env
else
  echo "Error: .env file not found"
  exit 1
fi

# Check if we have the RPC URL and chain ID
if [ -z "$RPC_URL" ] || [ -z "$CHAIN_ID" ]; then
  echo "Error: RPC_URL or CHAIN_ID not found in .env file"
  exit 1
fi

# Map the private keys from .env to the expected variable names in the Solidity script
export EXECUTOR_PRIVATE_KEY="$EXECUTOR_PRIVATE_KEY"
export COMPANY_PRIVATE_KEY="$PRIVATE_KEY_COMPANY_2"
export FREELANCER_PRIVATE_KEY="$PRIVATE_KEY_FREELANCER_2"

# Set the contract addresses
LLEDU_TOKEN="0x29668302bf1E11FDc0CC2E01aAEC1e10966F779e"
PROJECT_LEDGER="0xc3F785e76e0E07daa7FdE8c2f190bcb8f11a429F"
EXECUTOR="0xB92749d0769EB9fb1B45f2dE0CD51c97aa220f93"
COMPANY_WALLET="0xDC17577cb8A3e647c49a8d4717D6819D28932bAf"
FREELANCER_WALLET="0xB75682F7bBa3caB29972452DA8737AebFf684e39"

# Check for the argument
if [ -z "$1" ]; then
  echo "Please specify which part of the workflow to run:"
  echo "  1: Executor operations (whitelist token, transfer tokens, register wallets)"
  echo "  2: Company operations (approve tokens, create project)"
  echo "  3: Freelancer operations (create submission) - requires project ID"
  echo "  4: Company approval (approve submission) - requires submission ID"
  echo "  5: Show balances"
  echo "  6: List recently created projects (helps find project IDs)"
  echo "  all: Run all steps (may encounter errors due to timing)"
  exit 1
fi

STEP=$1

# Handle parameter based on step
if [ "$STEP" == "3" ]; then
  if [ -z "$2" ]; then
    echo "ERROR: Project ID is required for step 3 (freelancer operations)"
    echo "Usage: $0 3 <project_id>"
    exit 1
  fi
  PROJECT_ID=$2
  SUBMISSION_ID="0x0000000000000000000000000000000000000000000000000000000000000000"
elif [ "$STEP" == "4" ]; then
  if [ -z "$2" ]; then
    echo "ERROR: Submission ID is required for step 4 (company approval)"
    echo "Usage: $0 4 <submission_id>"
    exit 1
  fi
  SUBMISSION_ID=$2
  PROJECT_ID="0x0000000000000000000000000000000000000000000000000000000000000000"
else
  # For other steps
  PROJECT_ID=${2:-"0x0000000000000000000000000000000000000000000000000000000000000000"}
  SUBMISSION_ID=${3:-"0x0000000000000000000000000000000000000000000000000000000000000000"}
fi

# Display information about what we're going to do
echo "----------------------------------------"
echo "Running Partial Testnet Workflow with:"
echo "- LLEDU Token: $LLEDU_TOKEN"
echo "- Project Ledger: $PROJECT_LEDGER"
echo "- Executor: $EXECUTOR"
echo "- Company Wallet: $COMPANY_WALLET"
echo "- Freelancer Wallet: $FREELANCER_WALLET"
echo "- RPC URL: $RPC_URL"
echo "- Chain ID: $CHAIN_ID"
echo "- Running step: $STEP"

if [ "$PROJECT_ID" != "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
  echo "- Project ID: $PROJECT_ID"
fi

if [ "$SUBMISSION_ID" != "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
  echo "- Submission ID: $SUBMISSION_ID"
fi
echo "----------------------------------------"

# Run the appropriate Forge script with the right step
if [ "$STEP" == "all" ]; then
  forge script script/RealTestnetWorkflow.s.sol:RealTestnetWorkflow --sig "run()" --rpc-url "$RPC_URL" --private-key "$EXECUTOR_PRIVATE_KEY" --broadcast --skip-simulation
else
  forge script script/RealTestnetWorkflow.s.sol:RealTestnetWorkflow --sig "runStep(uint256,bytes32,bytes32)" $STEP $PROJECT_ID $SUBMISSION_ID --rpc-url "$RPC_URL" --private-key "$EXECUTOR_PRIVATE_KEY" --broadcast --skip-simulation
fi 