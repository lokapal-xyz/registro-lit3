#!/bin/bash

# ============================================================================
# deploy-lit3ledger.sh
# Deploy Lit3Ledger to Base networks
# Usage: ./deploy-lit3ledger.sh <network>
# Networks: base-sepolia, base
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to show usage
show_usage() {
    echo -e "${BLUE}Deploy Lit3Ledger Script${NC}"
    echo ""
    echo "Usage: $0 <network>"
    echo ""
    echo "Networks:"
    echo "  base-sepolia  : Base Sepolia Testnet"
    echo "  base          : Base Mainnet"
    echo ""
    echo "Examples:"
    echo "  $0 base-sepolia"
    echo "  $0 base"
    echo ""
    exit 1
}

# Check arguments
if [ $# -ne 1 ]; then
    echo -e "${RED}Error: Network required${NC}"
    show_usage
fi

NETWORK=$1

# Validate network
case $NETWORK in
    "base-sepolia"|"base")
        ;;
    *)
        echo -e "${RED}Error: Invalid network '$NETWORK'${NC}"
        echo "Supported networks: base-sepolia, base"
        exit 1
        ;;
esac

# Set network configuration
case $NETWORK in
    "base-sepolia")
        CHAIN_ID=84532
        RPC_URL="base-sepolia"
        NETWORK_NAME="Base Sepolia"
        EXPLORER_URL="https://sepolia.basescan.org"
        ;;
    "base")
        CHAIN_ID=8453
        RPC_URL="base"
        NETWORK_NAME="Base Mainnet"
        EXPLORER_URL="https://basescan.org"
        ;;
esac

echo -e "${BLUE}=== DEPLOYING LIT3 LEDGER TO ${NETWORK_NAME} ===${NC}"

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

source .env

if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}Error: PRIVATE_KEY not set in .env file${NC}"
    exit 1
fi

echo -e "${YELLOW}Network:${NC} ${NETWORK_NAME}"
echo -e "${YELLOW}Chain ID:${NC} ${CHAIN_ID}"
echo -e "${YELLOW}RPC:${NC} ${RPC_URL}"
echo ""

# Create deployments directory
mkdir -p deployments

# Confirmation prompt - extra warning for mainnet
if [ "$NETWORK" = "base" ]; then
    echo -e "${RED}WARNING: You are deploying to BASE MAINNET${NC}"
    echo -e "${RED}This will use real ETH and cost real money!${NC}"
    echo ""
fi

read -p "Continue with deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled${NC}"
    exit 0
fi

echo -e "${BLUE}Deploying contract...${NC}"

# Deploy the contract and capture output
DEPLOY_OUTPUT=$(forge script script/DeployLit3Ledger.s.sol:DeployLit3Ledger \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --broadcast 2>&1)

echo "$DEPLOY_OUTPUT"

# Check if deployment was successful
if echo "$DEPLOY_OUTPUT" | grep -q "DEPLOYMENT COMPLETE"; then
    # Extract information from the output
    CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep "Contract deployed to:" | grep -o "0x[a-fA-F0-9]*" | head -1)
    DEPLOYER_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep "Deployed by" | grep -o "0x[a-fA-F0-9]*" | head -1)
    BLOCK_NUMBER=$(echo "$DEPLOY_OUTPUT" | grep "Block number:" | grep -o "[0-9]*" | head -1)
    TIMESTAMP=$(echo "$DEPLOY_OUTPUT" | grep "Deployment timestamp:" | grep -o "[0-9]*" | head -1)
    
    if [ -z "$CONTRACT_ADDRESS" ]; then
        echo -e "${RED}❌ Failed to extract contract address from output${NC}"
        exit 1
    fi
    
    # Create deployment JSON file
    cat > "deployments/${NETWORK}.json" << EOF
{
  "contractAddress": "${CONTRACT_ADDRESS}",
  "deployerAddress": "${DEPLOYER_ADDRESS}",
  "blockNumber": ${BLOCK_NUMBER},
  "chainId": ${CHAIN_ID},
  "deploymentTimestamp": ${TIMESTAMP}
}
EOF

    echo ""
    echo -e "${GREEN}✅ Contract deployed successfully!${NC}"
    echo -e "${GREEN}Contract Address: ${CONTRACT_ADDRESS}${NC}"
    echo -e "${GREEN}Deployment file created: deployments/${NETWORK}.json${NC}"
    
    # Update .env file with contract address (use network-specific variable)
    CONTRACT_VAR="CONTRACT_ADDRESS_${NETWORK//-/_}"
    CONTRACT_VAR=$(echo "$CONTRACT_VAR" | tr '[:lower:]' '[:upper:]')

    # Update network-specific variable
    if grep -q "$CONTRACT_VAR=" .env; then
        sed -i.bak "s/${CONTRACT_VAR}=.*/${CONTRACT_VAR}=${CONTRACT_ADDRESS}/" .env
    else
        echo "${CONTRACT_VAR}=${CONTRACT_ADDRESS}" >> .env
    fi

    # Also update the generic CONTRACT_ADDRESS for current active network
    if grep -q "CONTRACT_ADDRESS=" .env; then
        sed -i.bak "s/CONTRACT_ADDRESS=.*/CONTRACT_ADDRESS=${CONTRACT_ADDRESS}/" .env
    else
        echo "CONTRACT_ADDRESS=${CONTRACT_ADDRESS}" >> .env
    fi
    
    echo -e "${GREEN}Updated .env with ${CONTRACT_VAR}=${CONTRACT_ADDRESS}${NC}"
    
    # Verify contract if API key is provided
    if [ ! -z "$BASESCAN_API_KEY" ] && [ "$BASESCAN_API_KEY" != "your_basescan_api_key_here" ]; then
        echo ""
        echo -e "${BLUE}Verifying contract on ${NETWORK_NAME}...${NC}"
        forge verify-contract \
            --chain-id "$CHAIN_ID" \
            --num-of-optimizations 200 \
            --watch \
            --etherscan-api-key "$BASESCAN_API_KEY" \
            --compiler-version v0.8.30+commit.d5aba93b \
            "$CONTRACT_ADDRESS" \
            src/Lit3Ledger.sol:Lit3Ledger || {
                echo -e "${YELLOW}⚠️  Verification failed, but deployment succeeded${NC}"
            }
    fi
    
    echo ""
    echo -e "${BLUE}View on Explorer: ${EXPLORER_URL}/address/${CONTRACT_ADDRESS}${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Test: ./query-lit3.sh ${NETWORK} status"
    echo "2. Archive: ./archive-entry.sh ${NETWORK} \"Title\" \"Source\" \"Time 1\" \"Time 2\" \"Log\" \"Link\" \"License\""
    
else
    echo -e "${RED}❌ Deployment failed${NC}"
    exit 1
fi