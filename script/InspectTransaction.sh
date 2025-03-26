#!/bin/bash

# Exit if any command fails
set -e

# Check if a transaction hash was provided
if [ -z "$1" ]; then
  echo "Error: Transaction hash is required"
  echo "Usage: $0 <transaction_hash>"
  exit 1
fi

TX_HASH=$1

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
echo "Inspecting transaction:"
echo "$TX_HASH"
echo "----------------------------------------"

# Use curl to get transaction receipt from RPC
echo "Fetching transaction receipt..."
curl -s -X POST -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getTransactionReceipt\",\"params\":[\"$TX_HASH\"],\"id\":1}" "$RPC_URL" > tx_receipt.json

# Extract logs from transaction receipt
echo "Transaction receipt saved to tx_receipt.json"

# Print helpful info
echo "----------------------------------------"
echo "To find the project ID in the logs, look for:"
echo "ProjectCreated(bytes32 indexed projectId, address indexed owner, address token, uint256 reward)"
echo ""
echo "The first indexed parameter is the real project ID to use for submissions."
echo "----------------------------------------"
echo "You can view the full transaction receipt in tx_receipt.json"
echo "Sample command to extract project ID from logs (bash with jq):"
echo "cat tx_receipt.json | jq -r '.result.logs[] | select(.topics[0] == \"0x1f3dc198bd6f3f6589fee9752c292e933c07ba7feca3131d96bb7e070cd94a42\") | .topics[1]'"
echo "----------------------------------------" 