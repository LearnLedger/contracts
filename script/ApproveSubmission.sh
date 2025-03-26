#!/bin/bash

# Exit if any command fails
set -e

# Check if a submission ID was provided
if [ -z "$1" ]; then
  echo "Error: Submission ID is required"
  echo "Usage: $0 <submission_id>"
  exit 1
fi

SUBMISSION_ID=$1

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

# Map the private key from .env to the expected variable name in the Solidity script
export COMPANY_PRIVATE_KEY="$PRIVATE_KEY_COMPANY_2"

echo "----------------------------------------"
echo "Approving submission with ID:"
echo "$SUBMISSION_ID"
echo "----------------------------------------"

# Run the script to approve the submission
forge script script/ApproveSubmission.sol:ApproveSubmission --sig "run(bytes32)" "$SUBMISSION_ID" --rpc-url "$RPC_URL" --private-key "$COMPANY_PRIVATE_KEY" --broadcast --skip-simulation 