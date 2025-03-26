#!/bin/bash

# Exit if any command fails
set -e

# Check if private key is provided
if [ -z "$EXECUTOR_PRIVATE_KEY" ]; then
  echo "Error: Please set the EXECUTOR_PRIVATE_KEY environment variable"
  echo "Example: export EXECUTOR_PRIVATE_KEY=0xabcdef..."
  exit 1
fi

# Set up RPC URL for testnet (Porcini)
PORCINI_RPC_URL="https://rpc.porcini.chainstack.io"

# Run the test with verbosity level 3 to see all logs
forge test --match-path test/ProjectLedgerTestnetTest.sol \
           --fork-url $PORCINI_RPC_URL \
           -vvv 