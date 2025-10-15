#!/bin/bash

# ============================================================================
# setup-lit3-subgraph.sh
# Setup Lit3Ledger Subgraph
# Usage: ./setup-lit3-subgraph.sh
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== SETTING UP LIT3 LEDGER SUBGRAPH ===${NC}"

# Check if subgraph directory exists
if [ -d "subgraph" ]; then
    echo -e "${YELLOW}Subgraph directory already exists. Continuing...${NC}"
else
    echo -e "${BLUE}Creating subgraph directory structure...${NC}"
    mkdir -p subgraph/abis
    mkdir -p subgraph/src
fi

# Check for 'pnpm' command and configure if necessary
if ! command -v pnpm &> /dev/null; then
    echo -e "${RED}Error: pnpm is not installed.${NC}"
    echo -e "${YELLOW}Please install pnpm first (e.g., using 'npm install -g pnpm').${NC}"
    exit 1
fi

# Check if the global 'graph' command is available
if ! command -v graph &> /dev/null; then
    echo -e "${BLUE}Installing Graph CLI globally with pnpm...${NC}"
    
    if ! pnpm install -g @graphprotocol/graph-cli@latest; then
        echo -e "${RED}----------------------------------------------------------------------${NC}"
        echo -e "${RED}⚠️ CRITICAL ERROR: Global pnpm directory is not set up!${NC}"
        echo -e "${RED}The global installation failed because pnpm doesn't know where to put the executable.${NC}"
        echo -e "${RED}----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}ACTION REQUIRED:${NC}"
        echo -e "${YELLOW}1. Run: ${GREEN}pnpm setup${YELLOW} to configure your shell.${NC}"
        echo -e "${YELLOW}2. Close and reopen your terminal.${NC}"
        echo -e "${YELLOW}3. Run this setup script again.${NC}"
        echo -e "${RED}----------------------------------------------------------------------${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}Graph CLI already installed${NC}"
fi

cd subgraph

# Install dependencies locally using pnpm
echo -e "${BLUE}Installing subgraph dependencies...${NC}"
pnpm install

# Generate subgraph code
echo -e "${BLUE}Generating subgraph code...${NC}"
graph codegen

# Build subgraph
echo -e "${BLUE}Building subgraph...${NC}"
graph build

echo ""
echo -e "${GREEN}✅ Subgraph setup complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Visit https://thegraph.com/studio/"
echo "2. Create a new subgraph"
echo "3. Get your deploy key"
echo "4. Run: graph auth <YOUR_DEPLOY_KEY>"
echo "5. Run: graph deploy <YOUR_SUBGRAPH_NAME>"
echo ""
echo -e "${BLUE}Test queries will be available at your Studio subgraph URL${NC}"
