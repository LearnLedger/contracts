#!/bin/bash

# Exit if any command fails
set -e

# Check if a project ID was provided
if [ -z "$1" ]; then
  echo "Error: Project ID is required"
  echo "Usage: $0 <project_id>"
  exit 1
fi

PROJECT_ID=$1

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
export FREELANCER_PRIVATE_KEY="$PRIVATE_KEY_FREELANCER_2"

echo "----------------------------------------"
echo "Submitting to project with ID:"
echo "$PROJECT_ID"
echo "----------------------------------------"

# Run the script to submit to the project
forge script script/SubmitToProject.sol:SubmitToProject --sig "run(bytes32)" "$PROJECT_ID" --rpc-url "$RPC_URL" --private-key "$FREELANCER_PRIVATE_KEY" --broadcast --skip-simulation 