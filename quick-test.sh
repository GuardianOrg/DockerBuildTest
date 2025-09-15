#!/bin/bash

# Quick test script for immediate testing
# Usage: ./quick-test.sh <github-url> <entry-point> [commit-hash] [dependency-setup]

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ $# -lt 2 ]; then
    echo -e "${RED}Usage: ./quick-test.sh <github-url> <entry-point> [commit-hash] [dependency-setup]${NC}"
    echo ""
    echo "Examples:"
    echo "  ./quick-test.sh https://github.com/user/repo.git 'test/Fuzz.sol --contract Fuzz'"
    echo "  ./quick-test.sh https://github.com/user/repo.git 'test/Fuzz.sol --contract Fuzz' abc123def"
    echo "  ./quick-test.sh https://github.com/user/repo.git 'test/Fuzz.sol --contract Fuzz' main 'npm install && forge build'"
    exit 1
fi

export GITHUB_URL="$1"
export ENTRY_POINT="$2"
export COMMIT_HASH="${3:-}"
export DEPENDENCY_SETUP="${4:-}"
export GITHUB_TOKEN="${GITHUB_TOKEN:-}"

echo -e "${GREEN}🚀 Quick Echidna Test${NC}"
echo "====================="
echo -e "${YELLOW}Repo:${NC} $GITHUB_URL"
echo -e "${YELLOW}Entry:${NC} $ENTRY_POINT"
echo -e "${YELLOW}Commit:${NC} ${COMMIT_HASH:-latest}"
echo ""

# Build and run
docker-compose build && docker-compose up
