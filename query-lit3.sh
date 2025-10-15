# ============================================================================
# query-lit3.sh
# Query Lit3Ledger Script for retrieving entry data
# Usage: ./query-lit3.sh <network> <action> [parameters...]
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to show usage
show_usage() {
    echo -e "${BLUE}Query Lit3Ledger Script for Retrieving Entry Data${NC}"
    echo ""
    echo "Usage: $0 <network> <action> [parameters...]"
    echo ""
    echo "Networks: base-sepolia, base"
    echo ""
    echo "Actions:"
    echo "  status                           - Show contract status and info"
    echo "  get-total                        - Get total number of entries"
    echo "  get-entry <index>                - Get specific entry by index"
    echo "  get-latest [count]               - Get latest entries (default: 5)"
    echo "  get-batch <start_index> <count>  - Get batch of entries"
    echo ""
    echo "Examples:"
    echo "  $0 base-sepolia status"
    echo "  $0 base-sepolia get-entry 0"
    echo "  $0 base-sepolia get-latest 10"
    echo "  $0 base-sepolia get-batch 0 5"
    echo ""
    exit 1
}

# Check minimum arguments
if [ $# -lt 2 ]; then
    echo -e "${RED}Error: Insufficient arguments${NC}"
    show_usage
fi

NETWORK=$1
ACTION=$2

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
        ;;
    "base")
        RPC_URL="base"
        ;;
esac

# Validate action and set environment variables
case $ACTION in
    "status")
        export ACTION="status"
        ;;
    "get-total")
        export ACTION="get-total"
        ;;
    "get-entry")
        if [ $# -ne 3 ]; then
            echo -e "${RED}Error: get-entry requires index parameter${NC}"
            echo "Usage: $0 $NETWORK get-entry <index>"
            exit 1
        fi
        export ACTION="get-entry"
        export ENTRY_INDEX="$3"
        ;;
    "get-latest")
        export ACTION="get-latest"
        if [ $# -ge 3 ]; then
            export COUNT="$3"
        fi
        ;;
    "get-batch")
        if [ $# -ne 4 ]; then
            echo -e "${RED}Error: get-batch requires start_index and count parameters${NC}"
            echo "Usage: $0 $NETWORK get-batch <start_index> <count>"
            exit 1
        fi
        export ACTION="get-batch"
        export START_INDEX="$3"
        export COUNT="$4"
        ;;
    *)
        echo -e "${RED}Error: Invalid action '$ACTION'${NC}"
        show_usage
        ;;
esac

echo -e "${BLUE}=== QUERYING LIT3 LEDGER ===${NC}"
echo -e "${YELLOW}Network:${NC} $NETWORK"
echo -e "${YELLOW}Action:${NC} $ACTION"

# Show additional parameters if applicable
case $ACTION in
    "get-entry")
        echo -e "${YELLOW}Index:${NC} $ENTRY_INDEX"
        ;;
    "get-latest")
        if [ -n "$COUNT" ]; then
            echo -e "${YELLOW}Count:${NC} $COUNT"
        else
            echo -e "${YELLOW}Count:${NC} 5 (default)"
        fi
        ;;
    "get-batch")
        echo -e "${YELLOW}Start Index:${NC} $START_INDEX"
        echo -e "${YELLOW}Count:${NC} $COUNT"
        ;;
esac

echo ""

# Execute the forge script (read-only, no broadcasting needed)
echo -e "${BLUE}Querying data...${NC}"

forge script script/InteractWithLit3.s.sol:InteractWithLit3 \
    --rpc-url "$RPC_URL"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Query completed successfully!${NC}"
else
    echo -e "${RED}❌ Query failed${NC}"
    exit 1
fi