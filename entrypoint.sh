#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting Echidna Local Test Environment${NC}"
echo "================================================"

# Configure git identity for forge install operations
git config --global user.email "echidna@local.test"
git config --global user.name "Echidna Local Test"

# Configure git to use token for all GitHub operations (including submodules)
if [ -n "$GITHUB_TOKEN" ]; then
    git config --global url."https://${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/"
fi

# Check required environment variables
if [ -z "$GITHUB_URL" ]; then
    echo -e "${RED}❌ Error: GITHUB_URL is required${NC}"
    exit 1
fi

if [ -z "$ENTRY_POINT" ]; then
    echo -e "${RED}❌ Error: ENTRY_POINT is required (e.g., 'test/fuzzing/Fuzz.sol --contract Fuzz')${NC}"
    exit 1
fi

# Parse repository name from URL
REPO_NAME=$(basename -s .git "$GITHUB_URL")
echo -e "${YELLOW}📦 Repository: $REPO_NAME${NC}"

# Clone repository
echo -e "${YELLOW}📥 Cloning repository...${NC}"
if [ -n "$GITHUB_TOKEN" ]; then
    # Use token for private repos
    GIT_URL=$(echo "$GITHUB_URL" | sed "s|https://|https://${GITHUB_TOKEN}@|")
    if [ -n "$BRANCH" ]; then
        git clone -b "$BRANCH" "$GIT_URL" /workspace/repo
    else
        git clone "$GIT_URL" /workspace/repo
    fi
else
    # Public repo
    if [ -n "$BRANCH" ]; then
        git clone -b "$BRANCH" "$GITHUB_URL" /workspace/repo
    else
        git clone "$GITHUB_URL" /workspace/repo
    fi
fi

cd /workspace/repo

# Checkout specific commit if provided
if [ -n "$COMMIT_HASH" ]; then
    echo -e "${YELLOW}🔀 Checking out commit: $COMMIT_HASH${NC}"
    git checkout "$COMMIT_HASH"
fi

# Run dependency installation if provided
if [ -n "$DEPENDENCY_SETUP" ]; then
    echo -e "${YELLOW}📦 Running dependency setup...${NC}"
    echo "Command: $DEPENDENCY_SETUP"
    eval "$DEPENDENCY_SETUP"
fi

# Save configuration for later reference
echo -e "${GREEN}💾 Saving configuration...${NC}"
cat > /workspace/fuzzing_config.json <<EOF
{
  "github_url": "$GITHUB_URL",
  "commit_hash": "$(git rev-parse HEAD)",
  "entry_point": "$ENTRY_POINT",
  "dependency_setup": "$DEPENDENCY_SETUP",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

echo -e "${GREEN}Configuration saved to: /workspace/fuzzing_config.json${NC}"
cat /workspace/fuzzing_config.json

# Run Echidna
echo ""
echo "================================================"
echo -e "${GREEN}🎯 Starting Echidna fuzzing...${NC}"
echo -e "${YELLOW}Entry point: echidna $ENTRY_POINT --config echidna.yaml${NC}"
echo "================================================"
echo ""

# Execute echidna with the entry point and always append --config echidna.yaml
echidna $ENTRY_POINT --config echidna.yaml
