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
if [ -z "$RPC_URL" ]; then
  echo "Error: RPC_URL not found in .env file"
  exit 1
fi

echo "----------------------------------------"
echo "Checking submission with ID:"
echo "$SUBMISSION_ID"
echo "----------------------------------------"

# Run the script to check the submission
forge script script/ApproveSubmission.sol:ApproveSubmission --sig "checkSubmission(bytes32)" "$SUBMISSION_ID" --rpc-url "$RPC_URL" 