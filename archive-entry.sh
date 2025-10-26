#!/bin/bash

# ============================================================================
# archive-entry.sh
# Archive an entry to Lit3Ledger using named arguments (flags)
# Usage: ./archive-entry.sh -n <network> [OPTIONS...]
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
    echo -e "${BLUE}Archive Entry Script for Lit3 Ledger${NC}"
    echo ""
    echo "Usage: $0 -n <network> [OPTIONS...]"
    echo ""
    echo "Required Argument:"
    echo "  -n, --network            : base-sepolia or base"
    echo ""
    echo "Optional Arguments (Ledger Framework):"
    echo "  -t, --title              : Entry title (e.g., \"Chapter One\")"
    echo "  -s, --source             : Source/location of the entry (e.g., \"Archive Node\")"
    echo "  -a, --timestamp1         : First timestamp (e.g., \"2025-10-11 14:30:00 UTC\")"
    echo "  -b, --timestamp2         : Second timestamp (e.g., \"Lanka Time\")"
    echo "  -c, --curator-note       : Observations from the Curator"
    echo ""
    echo "Optional Arguments (Token Framework):"
    echo "  -f, --nft-address        : NFT contract address (0x0 or 'none' for no NFT)"
    echo "  -d, --nft-id             : NFT token ID (0 if no NFT)"
    echo ""
    echo "Optional Arguments (Permanence Framework):"
    echo "  -l, --text-file          : Path to text file for hashing (omit to skip hashing)"
    echo "  -x, --permaweb-link      : IPFS/Arweave link (e.g., ipfs://Qm..., empty for none)"
    echo "  -p, --license            : License declaration (e.g., 'CC BY-SA 4.0', empty for none)"
    echo ""
    echo "Examples:"
    echo "  # Minimal entry (only required field + title/note)"
    echo "  $0 -n base-sepolia -t \"Minimal Title\" -c \"Minimal entry note\""
    echo ""
    echo "  # Entry with content hash and NFT"
    echo "  $0 --network base-sepolia --title \"Chapter One\" --source \"Node\" \\"
    echo "     --nft-address 0x1234...abcd --nft-id 42 --text-file chapter-one.md"
    echo ""
    exit 1
}

# Check for GNU getopt (required for long options)
if getopt --test > /dev/null 2>&1; GETOPT_EXIT=$?; [ $GETOPT_EXIT -ne 4 ]; then
    echo -e "${RED}Error: GNU getopt is required but not found${NC}"
    echo -e "${YELLOW}On macOS, install with: brew install gnu-getopt${NC}"
    echo -e "${YELLOW}Then add to PATH: export PATH=\"/usr/local/opt/gnu-getopt/bin:\$PATH\"${NC}"
    exit 1
fi

# --- Default Values and Argument Parsing ---

# Set initial default values
NETWORK=""
TITLE=""
SOURCE=""
TIMESTAMP1=""
TIMESTAMP2=""
CURATOR_NOTE=""
NFT_ADDRESS="none"
NFT_ID=0
TEXT_FILE=""
PERMAWEB_LINK=""
LICENSE=""

# Parse named arguments using getopt
OPTIONS=$(getopt -o n:t:s:a:b:c:f:d:l:x:p: --long network:,title:,source:,timestamp1:,timestamp2:,curator-note:,nft-address:,nft-id:,text-file:,permaweb-link:,license: -n 'archive-entry.sh' -- "$@")

if [ $? -ne 0 ]; then
    show_usage
fi

eval set -- "$OPTIONS"

while true; do
    case "$1" in
        -n|--network) NETWORK=$2; shift 2 ;;
        -t|--title) TITLE=$2; shift 2 ;;
        -s|--source) SOURCE=$2; shift 2 ;;
        -a|--timestamp1) TIMESTAMP1=$2; shift 2 ;;
        -b|--timestamp2) TIMESTAMP2=$2; shift 2 ;;
        -c|--curator-note) CURATOR_NOTE=$2; shift 2 ;;
        -f|--nft-address) NFT_ADDRESS=$2; shift 2 ;;
        -d|--nft-id) NFT_ID=$2; shift 2 ;;
        -l|--text-file) TEXT_FILE=$2; shift 2 ;;
        -x|--permaweb-link) PERMAWEB_LINK=$2; shift 2 ;;
        -p|--license) LICENSE=$2; shift 2 ;;
        --) shift; break ;;
        *) echo -e "${RED}Internal error: Unknown option $1${NC}"; show_usage ;;
    esac
done

# Check required argument
if [ -z "$NETWORK" ]; then
    echo -e "${RED}Error: The --network (-n) argument is required.${NC}"
    show_usage
fi

# --- Validation and Pre-processing (Retained from original script) ---

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
    HASH_OUTPUT=$(node scripts/hnp1.js "$TEXT_FILE" 2>&1)

    if [ $? -ne 0 ]; then
        echo -e "${RED}Error during normalization and hashing:${NC}"
        echo "$HASH_OUTPUT"
        exit 1
    fi

    CONTENT_HASH=$HASH_OUTPUT
    echo -e "${GREEN}✅ Content hash: ${CONTENT_HASH}${NC}"
fi

# --- Output Confirmation (Styled for Flags) ---

echo -e "${BLUE}=== ARCHIVING ENTRY TO LIT3 LEDGER ===${NC}"
echo -e "${YELLOW}Network:${NC} $NETWORK"
echo ""
echo -e "${BLUE}Ledger Framework:${NC}"
echo -e "${YELLOW}  Title:${NC} ${TITLE:-"(empty)"}"
echo -e "${YELLOW}  Source:${NC} ${SOURCE:-"(empty)"}"
echo -e "${YELLOW}  Timestamp 1:${NC} ${TIMESTAMP1:-"(empty)"}"
echo -e "${YELLOW}  Timestamp 2:${NC} ${TIMESTAMP2:-"(empty)"}"
echo -e "${YELLOW}  Curator Note:${NC} ${CURATOR_NOTE:-"(empty)"}"
echo ""
if [[ "$NFT_ADDRESS" != "0x0000000000000000000000000000000000000000" || "$NFT_ID" != "0" ]]; then
    echo -e "${BLUE}Token Framework:${NC}"
    echo -e "${YELLOW}  NFT Address:${NC} $NFT_ADDRESS"
    echo -e "${YELLOW}  NFT ID:${NC} $NFT_ID"
    echo ""
fi
if [[ "$CONTENT_HASH" != "0x0000000000000000000000000000000000000000000000000000000000000000" || -n "$PERMAWEB_LINK" || -n "$LICENSE" ]]; then
    echo -e "${BLUE}Permanence Framework:${NC}"
    echo -e "${YELLOW}  Content Hash:${NC} $CONTENT_HASH"
    if [ -n "$PERMAWEB_LINK" ]; then
        echo -e "${YELLOW}  Permaweb Link:${NC} $PERMAWEB_LINK"
    fi
    if [ -n "$LICENSE" ]; then
        echo -e "${YELLOW}  License:${NC} $LICENSE"
    fi
    echo ""
fi

# Confirmation prompt
read -p "Continue with archiving? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Archiving cancelled${NC}"
    exit 0
fi

# --- Execution ---

# Set environment variables for forge script
export ACTION="archive"
export TITLE="$TITLE"
export SOURCE="$SOURCE"
export TIMESTAMP1="$TIMESTAMP1"
export TIMESTAMP2="$TIMESTAMP2"
export CURATOR_NOTE="$CURATOR_NOTE"
export NFT_ADDRESS="$NFT_ADDRESS"
export NFT_ID="$NFT_ID"
export CONTENT_HASH="$CONTENT_HASH"
export PERMAWEB_LINK="$PERMAWEB_LINK"
export LICENSE="$LICENSE"

# Execute the forge script
echo -e "${BLUE}Executing archive transaction...${NC}"

forge script script/InteractWithLit3.s.sol:InteractWithLit3 \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --broadcast

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Entry archived successfully!${NC}"
    echo ""
    echo -e "${BLUE}You can verify the transaction on: ${EXPLORER_URL}${NC}"
else
    echo -e "${RED}❌ Archive operation failed${NC}"
    exit 1
fi