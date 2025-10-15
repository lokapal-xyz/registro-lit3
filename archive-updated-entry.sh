#!/bin/bash

# ============================================================================
# archive-updated-entry.sh
# Archive an updated entry and deprecate the previous version
# Usage: ./archive-updated-entry.sh <network> <deprecate_index> <title> <source> \
#                                    <timestamp1> <timestamp2> <curator_note> \
#                                    [nft_address] [nft_id] [text_file]
# ============================================================================

set -e

source .env

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to show usage
show_usage() {
    echo -e "${BLUE}Archive Updated Entry Script for Lit3 Ledger${NC}"
    echo ""
    echo "Usage: $0 <network> <deprecate_index> <title> <source> <timestamp1> <timestamp2> <curator_note> [nft_address] [nft_id] [text_file]"
    echo ""
    echo "Required Arguments:"
    echo "  network            : base-sepolia or base"
    echo "  deprecate_index    : Index of entry to deprecate and replace"
    echo "  title              : Updated entry title"
    echo "  source             : Source/location of the entry"
    echo "  timestamp1         : First timestamp (e.g., reception time)"
    echo "  timestamp2         : Second timestamp (e.g., source transmission time)"
    echo "  curator_note       : Updated observations from the Curator"
    echo ""
    echo "Optional Arguments:"
    echo "  nft_address        : NFT contract address (0x0 or 'none' for no NFT)"
    echo "  nft_id             : NFT token ID (0 if no NFT)"
    echo "  text_file          : Path to text file for hashing (omit to skip hashing)"
    echo ""
    echo "Examples:"
    echo "  $0 base-sepolia 0 \"Chapter One v2\" \"Archive\" \"2025-10-11 15:00:00 UTC\" \"Lanka Time\" \"Updated with corrections\""
    echo "  $0 base-sepolia 0 \"Chapter One v2\" \"Archive\" \"2025-10-11 15:00:00 UTC\" \"Lanka Time\" \"Updated\" 0x1234...abcd 42 chapter-one-v2.md"
    echo ""
    exit 1
}

# Check minimum arguments (7 required)
if [ $# -lt 7 ]; then
    echo -e "${RED}Error: Insufficient arguments${NC}"
    show_usage
fi

NETWORK=$1
DEPRECATE_INDEX=$2
TITLE=$3
SOURCE=$4
TIMESTAMP1=$5
TIMESTAMP2=$6
CURATOR_NOTE=$7
NFT_ADDRESS=${8:-"none"}
NFT_ID=${9:-0}
TEXT_FILE=${10:-""}

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

# Set RPC URL based on network
case $NETWORK in
    "base-sepolia")
        RPC_URL="base-sepolia"
        EXPLORER_URL="https://sepolia.basescan.org"
        ;;
    "base")
        RPC_URL="base"
        EXPLORER_URL="https://basescan.org"
        ;;
esac

# Validate DEPRECATE_INDEX is a number
if ! [[ "$DEPRECATE_INDEX" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Error: deprecate_index must be a number${NC}"
    exit 1
fi

# Normalize NFT address
if [[ "$NFT_ADDRESS" == "none" || "$NFT_ADDRESS" == "" || ! "$NFT_ADDRESS" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
    NFT_ADDRESS="0x0000000000000000000000000000000000000000"
fi

# Validate NFT_ID is a number
if ! [[ "$NFT_ID" =~ ^[0-9]+$ ]]; then
    NFT_ID=0
fi

# Initialize content hash to zeros
CONTENT_HASH="0x0000000000000000000000000000000000000000000000000000000000000000"

# If text file is provided, normalize and hash it
if [ -n "$TEXT_FILE" ]; then
    if [ ! -f "$TEXT_FILE" ]; then
        echo -e "${RED}Error: Text file not found: $TEXT_FILE${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Normalizing and hashing text file...${NC}"
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        echo -e "${RED}Error: Node.js is not installed${NC}"
        echo -e "${YELLOW}Please install Node.js to use text hashing functionality${NC}"
        exit 1
    fi
    
    # Run the normalization and hashing utility
    HASH_OUTPUT=$(node scripts/normalize-and-hash.js "$TEXT_FILE" 2>&1)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error during normalization and hashing:${NC}"
        echo "$HASH_OUTPUT"
        exit 1
    fi
    
    CONTENT_HASH=$HASH_OUTPUT
    echo -e "${GREEN}✅ Content hash: ${CONTENT_HASH}${NC}"
fi

echo -e "${BLUE}=== ARCHIVING UPDATED ENTRY TO LIT3 LEDGER ===${NC}"
echo -e "${YELLOW}Network:${NC} $NETWORK"
echo -e "${YELLOW}Deprecating Entry Index:${NC} $DEPRECATE_INDEX"
echo -e "${YELLOW}Title:${NC} $TITLE"
echo -e "${YELLOW}Source:${NC} $SOURCE"
echo -e "${YELLOW}Timestamp 1:${NC} $TIMESTAMP1"
echo -e "${YELLOW}Timestamp 2:${NC} $TIMESTAMP2"
echo -e "${YELLOW}Curator Note:${NC} $CURATOR_NOTE"
echo -e "${YELLOW}NFT Address:${NC} $NFT_ADDRESS"
echo -e "${YELLOW}NFT ID:${NC} $NFT_ID"
echo -e "${YELLOW}Content Hash:${NC} $CONTENT_HASH"
echo ""

# Confirmation prompt
read -p "Continue with archiving updated entry? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Archiving cancelled${NC}"
    exit 0
fi

# Set environment variables for forge script
export ACTION="archive-updated"
export TITLE="$TITLE"
export SOURCE="$SOURCE"
export TIMESTAMP1="$TIMESTAMP1"
export TIMESTAMP2="$TIMESTAMP2"
export CURATOR_NOTE="$CURATOR_NOTE"
export NFT_ADDRESS="$NFT_ADDRESS"
export NFT_ID="$NFT_ID"
export CONTENT_HASH="$CONTENT_HASH"
export DEPRECATE_INDEX="$DEPRECATE_INDEX"

# Execute the forge script
echo -e "${BLUE}Executing updated entry archive transaction...${NC}"

forge script script/InteractWithLit3.s.sol:InteractWithLit3 \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --broadcast

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Updated entry archived successfully!${NC}"
    echo -e "${GREEN}Previous entry (index $DEPRECATE_INDEX) has been deprecated${NC}"
    echo ""
    echo -e "${BLUE}You can verify the transaction on: ${EXPLORER_URL}${NC}"
else
    echo -e "${RED}❌ Archive updated entry operation failed${NC}"
    exit 1
fi