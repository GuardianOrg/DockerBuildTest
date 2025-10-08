#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ASCII Art Banner
echo -e "${CYAN}"
cat << "EOF"
 _____ _     _     _             _____         _   
|   __| |_ _|_|___|_|___ ___    |_   _|___ ___| |_ 
|   __| '_| | | . |   | .'|       | | | -_|_ -|  _|
|_____|_,_|_|_|___|_|_|__,|       |_| |___|___|_|  
                                                    
EOF
echo -e "${NC}"
echo -e "${GREEN}Local Echidna Testing Environment${NC}"
echo "===================================="
echo ""

# Function to display help
show_help() {
    echo "Usage: ./run.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  -i, --interactive    Run in interactive mode (prompt for values)"
    echo "  -c, --config FILE    Use a specific .env file (default: .env)"
    echo "  -s, --save           Save configuration to .env file"
    echo "  -l, --logs           Show container logs after starting"
    echo "  -d, --detach         Run container in background"
    echo ""
    echo "Examples:"
    echo "  ./run.sh                    # Run with .env file"
    echo "  ./run.sh -i                 # Interactive mode"
    echo "  ./run.sh -c custom.env      # Use custom env file"
    echo "  ./run.sh -i -s              # Interactive mode and save config"
    exit 0
}

# Default values
INTERACTIVE=false
CONFIG_FILE=".env"
SAVE_CONFIG=false
SHOW_LOGS=false
DETACH=false
CONTAINER_NAME=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -i|--interactive)
            INTERACTIVE=true
            shift
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -s|--save)
            SAVE_CONFIG=true
            shift
            ;;
        -l|--logs)
            SHOW_LOGS=true
            shift
            ;;
        -d|--detach)
            DETACH=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Generate unique container name from config file
CONFIG_BASENAME=$(basename "$CONFIG_FILE" .env)
if [ "$CONFIG_BASENAME" = "." ] || [ "$CONFIG_BASENAME" = ".env" ] || [ -z "$CONFIG_BASENAME" ]; then
    CONTAINER_NAME="echidna-default"
else
    CONTAINER_NAME="echidna-${CONFIG_BASENAME}"
fi
export CONTAINER_NAME
export COMPOSE_PROJECT_NAME="${CONTAINER_NAME}-project"

# Function to prompt for input with default value
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    if [ -n "$default" ]; then
        echo -ne "${YELLOW}$prompt [$default]: ${NC}"
    else
        echo -ne "${YELLOW}$prompt: ${NC}"
    fi
    
    read -r input
    if [ -z "$input" ]; then
        eval "$var_name='$default'"
    else
        eval "$var_name='$input'"
    fi
}

# Interactive mode
if [ "$INTERACTIVE" = true ]; then
    echo -e "${CYAN}🔧 Interactive Configuration${NC}"
    echo "----------------------------"
    
    prompt_with_default "GitHub URL (e.g., https://github.com/user/repo.git)" "" "GITHUB_URL"
    prompt_with_default "GitHub Token (optional, for private repos)" "" "GITHUB_TOKEN"
    prompt_with_default "Branch (optional, leave empty for default branch)" "" "BRANCH"
    prompt_with_default "Commit Hash (optional, leave empty for latest)" "" "COMMIT_HASH"
    prompt_with_default "Dependency Setup Command (e.g., 'npm install && forge build')" "" "DEPENDENCY_SETUP"
    prompt_with_default "Entry Point (e.g., 'test/fuzzing/Fuzz.sol --contract Fuzz')" "" "ENTRY_POINT"
    
    # Save configuration if requested
    if [ "$SAVE_CONFIG" = true ]; then
        echo -e "\n${GREEN}💾 Saving configuration to .env...${NC}"
        cat > .env <<EOF
GITHUB_URL=$GITHUB_URL
GITHUB_TOKEN=$GITHUB_TOKEN
BRANCH=$BRANCH
COMMIT_HASH=$COMMIT_HASH
DEPENDENCY_SETUP=$DEPENDENCY_SETUP
ENTRY_POINT=$ENTRY_POINT
EOF
        echo -e "${GREEN}✅ Configuration saved!${NC}"
    fi
    
    # Export variables for docker-compose
    export GITHUB_URL
    export GITHUB_TOKEN
    export BRANCH
    export COMMIT_HASH
    export DEPENDENCY_SETUP
    export ENTRY_POINT
else
    # Load from config file
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${CYAN}📄 Loading configuration from $CONFIG_FILE${NC}"
        set -a
        source "$CONFIG_FILE"
        set +a
    else
        echo -e "${RED}❌ Error: Configuration file '$CONFIG_FILE' not found${NC}"
        echo -e "${YELLOW}💡 Tip: Copy env.example to .env and fill in your values${NC}"
        echo -e "${YELLOW}   Or use -i flag for interactive mode${NC}"
        exit 1
    fi
fi

# Validate required variables
if [ -z "$GITHUB_URL" ]; then
    echo -e "${RED}❌ Error: GITHUB_URL is required${NC}"
    exit 1
fi

if [ -z "$ENTRY_POINT" ]; then
    echo -e "${RED}❌ Error: ENTRY_POINT is required${NC}"
    exit 1
fi

# Display configuration
echo ""
echo -e "${MAGENTA}📋 Configuration Summary${NC}"
echo "------------------------"
echo -e "${BLUE}Container Name:${NC} $CONTAINER_NAME"
echo -e "${BLUE}Config File:${NC} $CONFIG_FILE"
echo -e "${BLUE}Repository:${NC} $GITHUB_URL"
echo -e "${BLUE}Branch:${NC} ${BRANCH:-default}"
echo -e "${BLUE}Commit:${NC} ${COMMIT_HASH:-latest}"
echo -e "${BLUE}Entry Point:${NC} $ENTRY_POINT"
echo -e "${BLUE}Dependencies:${NC} ${DEPENDENCY_SETUP:-none}"
echo -e "${BLUE}Private Repo:${NC} $([ -n "$GITHUB_TOKEN" ] && echo "Yes" || echo "No")"
echo ""

# Create output directories
mkdir -p output configs

# Build Docker image
echo -e "${YELLOW}🔨 Building Docker image...${NC}"
docker-compose build

# Run the container
echo -e "${GREEN}🚀 Starting Echidna test container...${NC}"
if [ "$DETACH" = true ]; then
    docker-compose up -d
    echo -e "${GREEN}✅ Container started in background${NC}"
    echo -e "${YELLOW}💡 Use 'docker logs -f $CONTAINER_NAME' to view logs${NC}"
else
    docker-compose up
fi

# Show logs if requested and running in detached mode
if [ "$SHOW_LOGS" = true ] && [ "$DETACH" = true ]; then
    echo -e "${CYAN}📜 Container logs:${NC}"
    docker logs -f "$CONTAINER_NAME"
fi

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}🧹 Cleaning up...${NC}"

    # Stop and remove container
    if docker ps -a --filter "name=^${CONTAINER_NAME}$" --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
        docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
        echo -e "${GREEN}✅ Container ${CONTAINER_NAME} removed${NC}"
    fi

    # Remove network if it exists and has no other containers
    NETWORK_NAME="${COMPOSE_PROJECT_NAME}_echidna-net"
    if docker network ls --filter "name=^${NETWORK_NAME}$" --format "{{.Name}}" | grep -q "^${NETWORK_NAME}$"; then
        docker network rm "$NETWORK_NAME" >/dev/null 2>&1 || true
        echo -e "${GREEN}✅ Network ${NETWORK_NAME} removed${NC}"
    fi
}

# Set up trap for cleanup on exit (only if not detached)
if [ "$DETACH" = false ]; then
    trap cleanup EXIT
fi
