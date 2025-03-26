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

# Check if we have the RPC URL
if [ -z "$RPC_URL" ]; then
  echo "Error: RPC_URL not found in .env file"
  exit 1
fi

echo "----------------------------------------"
echo "Searching for valid projects..."
echo "----------------------------------------"

# Run the script to list all projects
forge script script/ListAllProjects.sol:ListAllProjects --rpc-url "$RPC_URL" 