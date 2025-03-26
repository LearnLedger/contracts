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

# Display information about what we're going to do
echo "----------------------------------------"
echo "Running Real Testnet Workflow with:"
echo "- LLEDU Token: $LLEDU_TOKEN_ADDRESS"
echo "- Project Ledger: $PROJECT_LEDGER_ADDRESS"
echo "- Executor: $EXECUTOR_PUBLIC_KEY"
echo "- Company Wallet: $PUBLIC_KEY_COMPANY_2"
echo "- Freelancer Wallet: $PUBLIC_KEY_FREELANCER_2"
echo "- RPC URL: $RPC_URL"
echo "- Chain ID: $CHAIN_ID"
echo "----------------------------------------"

# Run the script with proper verbosity and broadcast flag
# Adding --skip-simulation since the company is already registered
forge script script/RealTestnetWorkflow.s.sol:RealTestnetWorkflow \
  --rpc-url "$RPC_URL" \
  --chain-id "$CHAIN_ID" \
  --broadcast \
  --skip-simulation \
  -vvv 