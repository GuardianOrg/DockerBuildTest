# Echidna Local Testing Environment 🎯

A Docker-based solution for locally testing Echidna fuzzing configurations before deploying to Digital Ocean droplets via CloudExec. This tool helps you quickly validate that your fuzzing jobs will run successfully in the cloud by simulating the exact same environment locally.

## Table of Contents
- [Overview](#overview)
- [Why Use This Tool?](#why-use-this-tool)
- [System Requirements](#system-requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Detailed Usage](#detailed-usage)
- [Configuration Options](#configuration-options)
- [Understanding the Output](#understanding-the-output)
- [Troubleshooting](#troubleshooting)
- [Architecture Details](#architecture-details)
- [Team Distribution](#team-distribution)

## Overview

This tool creates a Docker container that perfectly mirrors your Digital Ocean Ubuntu 22.04 droplets, complete with:
- Custom Echidna binary from DigitalOcean Spaces
- Foundry toolchain (forge, cast, anvil)
- Automatic repository cloning from GitHub
- Support for private repositories via GitHub tokens
- Dependency installation automation
- Configuration persistence for cloud deployment

## Why Use This Tool?

### The Problem
When running Echidna fuzzing jobs on Digital Ocean droplets through CloudExec, it can take significant time to discover whether there's an error with the build or run configuration. Failed jobs waste both time and cloud resources.

### The Solution
This Docker environment allows you to:
1. **Test locally first** - Validate your fuzzing configuration in seconds, not minutes
2. **Catch errors early** - Identify build issues, missing dependencies, or incorrect entry points before cloud deployment
3. **Save cloud resources** - Only deploy jobs that you know will run successfully
4. **Maintain consistency** - Use the exact same environment as your cloud droplets
5. **Store configurations** - Automatically save working configurations for cloud deployment

## System Requirements

- **Docker** (version 20.10 or higher)
- **Docker Compose** (version 2.0 or higher)
- **Operating System**: macOS, Linux, or Windows with WSL2
- **Memory**: At least 4GB RAM available for Docker
- **Disk Space**: 2GB for Docker images + space for your repositories

### Architecture Compatibility

This tool works on both Intel/AMD (x86_64) and Apple Silicon (ARM64) systems:
- **Intel/AMD Macs & PCs**: Native performance
- **Apple Silicon Macs (M1/M2/M3)**: Uses x86_64 emulation via Rosetta 2
  - ⚠️ **Note**: First build may take longer (~5-10 minutes) on Apple Silicon
  - ⚠️ **Performance**: Fuzzing may run slower due to emulation overhead
  - The container uses `--platform=linux/amd64` to ensure consistency

## Installation

### 1. Clone or Download This Repository

```bash
# Option 1: If distributing via git
git clone https://github.com/GuardianOrg/DockerBuildTest echidna-local-test
cd echidna-local-test

# Option 2: If distributing as a zip file
unzip echidna-local-test.zip
cd echidna-local-test
```

### 2. Verify Docker Installation

```bash
docker --version
docker-compose --version
```

If Docker is not installed, visit [Docker's official website](https://docs.docker.com/get-docker/) for installation instructions.

### 3. Make Scripts Executable

```bash
chmod +x run.sh quick-test.sh
```

## Quick Start

### Method 1: Interactive Mode (Recommended for First Time)

```bash
./run.sh -i
```

This will prompt you for:
- GitHub repository URL
- GitHub token (if private repo)
- Commit hash (optional)
- Dependency setup command
- Echidna entry point

### Method 2: Using Configuration File

1. Copy the example configuration:
```bash
cp env.example .env
```

2. Edit `.env` with your values:
```bash
nano .env  # or use your preferred editor
```

3. Run the test:
```bash
./run.sh
```

### Method 3: Quick Test (One-liner)

```bash
./quick-test.sh https://github.com/user/repo.git "test/fuzzing/Fuzz.sol --contract Fuzz"
```

## Detailed Usage

### The `run.sh` Script

The main script for running tests with various options:

```bash
./run.sh [OPTIONS]
```

**Options:**
- `-h, --help` : Show help message
- `-i, --interactive` : Run in interactive mode (prompts for all values)
- `-c, --config FILE` : Use a specific .env file (default: .env)
- `-s, --save` : Save configuration to .env file (useful with -i)
- `-l, --logs` : Show container logs after starting
- `-d, --detach` : Run container in background

**Examples:**

```bash
# Interactive mode with config saving
./run.sh -i -s

# Use custom configuration file
./run.sh -c production.env

# Run in background and show logs
./run.sh -d -l

# Interactive mode for one-time test (no save)
./run.sh -i
```

### The `quick-test.sh` Script

For rapid testing when you know your parameters:

```bash
./quick-test.sh <github-url> <entry-point> [commit-hash] [dependency-setup]
```

**Examples:**

```bash
# Basic usage
./quick-test.sh https://github.com/OpenZeppelin/openzeppelin-contracts.git \
  "test/fuzzing/TestContract.sol --contract TestContract"

# With specific commit
./quick-test.sh https://github.com/user/repo.git \
  "contracts/test/Fuzz.sol --contract FuzzTest" \
  "abc123def456"

# With dependencies
./quick-test.sh https://github.com/user/repo.git \
  "test/Fuzz.sol --contract Fuzz" \
  "main" \
  "npm install && forge build"
```

## Configuration Options

### Environment Variables

Create a `.env` file with the following variables:

```bash
# Required
GITHUB_URL=https://github.com/username/repository.git
ENTRY_POINT=test/fuzzing/Fuzz.sol --contract Fuzz

# Optional
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx  # For private repositories
COMMIT_HASH=abc123def456789             # Specific commit to test
DEPENDENCY_SETUP=npm install && forge build  # Commands to run before fuzzing
```

### Configuration Details

#### `GITHUB_URL` (Required)
- The full GitHub repository URL
- Supports both HTTPS and SSH formats
- Examples:
  - `https://github.com/OpenZeppelin/openzeppelin-contracts.git`
  - `git@github.com:user/private-repo.git` (requires GITHUB_TOKEN)

#### `ENTRY_POINT` (Required)
- The Echidna command arguments (everything after `echidna`)
- Format: `path/to/contract.sol --contract ContractName [additional-flags]`
- **Note**: `--config echidna.yaml` is automatically appended to all commands
- Examples:
  - `test/fuzzing/Fuzz.sol --contract Fuzz`
  - `contracts/test/InvariantTest.sol --contract InvariantTest`
  - `src/TestContract.sol --contract TestContract --test-limit 10000`

#### `GITHUB_TOKEN` (Optional)
- Personal Access Token for private repositories
- Create one at: https://github.com/settings/tokens
- Required permissions: `repo` (full control of private repositories)
- The token is securely injected into the git URL for cloning

#### `COMMIT_HASH` (Optional)
- Specific commit, branch, or tag to test
- If not provided, uses the default branch (usually `main` or `master`)
- Examples:
  - Commit hash: `abc123def456789`
  - Branch: `develop`
  - Tag: `v2.0.0`

#### `DEPENDENCY_SETUP` (Optional)
- Shell commands to run after cloning but before fuzzing
- Common examples:
  - `npm install` - Install Node.js dependencies
  - `forge install` - Install Foundry dependencies
  - `forge build` - Build Foundry project
  - `npm install && forge build` - Combined setup
  - `pip install -r requirements.txt` - Python dependencies
  - `make setup` - Custom Makefile target

## Understanding the Output

### Successful Run

When everything works correctly, you'll see:

```
🚀 Starting Echidna Local Test Environment
================================================
📦 Repository: your-repo
📥 Cloning repository...
📦 Running dependency setup...
💾 Saving configuration...
Configuration saved to: /workspace/fuzzing_config.json
{
  "github_url": "https://github.com/user/repo.git",
  "commit_hash": "abc123...",
  "entry_point": "test/Fuzz.sol --contract Fuzz",
  "dependency_setup": "forge build",
  "timestamp": "2024-01-15T10:30:00Z"
}

================================================
🎯 Starting Echidna fuzzing...
Entry point: echidna test/Fuzz.sol --contract Fuzz
================================================

Analyzing contract: /workspace/repo/test/Fuzz.sol:Fuzz
Running tests...
[... Echidna output ...]
```

### Configuration Storage

The tool saves your configuration in two places:

1. **Inside the container**: `/workspace/fuzzing_config.json`
2. **On your host**: `./output/fuzzing_config.json` (if you mount the volume)

This JSON file contains all the parameters needed to replicate the test in the cloud:

```json
{
  "github_url": "https://github.com/user/repo.git",
  "commit_hash": "abc123def456789...",
  "entry_point": "test/Fuzz.sol --contract Fuzz",
  "dependency_setup": "npm install && forge build",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

Use these exact values when setting up your CloudExec jobs.

### Debugging Commands

```bash
# View container logs
docker logs echidna-local-test

# Enter the container for debugging
docker exec -it echidna-local-test /bin/bash

# Check if Echidna is installed correctly
docker exec echidna-local-test echidna --version

# Check if Foundry is installed correctly
docker exec echidna-local-test forge --version

# Clean up all containers and images
docker-compose down
docker system prune -a

# Rebuild from scratch
docker-compose build --no-cache
```

## Architecture Details

### Docker Image Structure

The Docker image is built on Ubuntu 22.04 (matching Digital Ocean droplets) and includes:

1. **Base System**:
   - Ubuntu 22.04 LTS
   - Git for repository cloning
   - Python3 and pip
   - Node.js and npm
   - curl, unzip for downloading tools

2. **Echidna Installation**:
   - Custom binary from: `https://guardianexec-echidna.nyc3.digitaloceanspaces.com/echidna`
   - Installed to: `/usr/local/bin/echidna`
   - Pre-compiled, no solc-select needed

3. **Foundry Toolchain**:
   - Specific nightly version for consistency
   - Installed to: `/root/.foundry`
   - Binaries linked globally: forge, cast, anvil

### Workflow Sequence

1. **Container Start**: Docker container launches with Ubuntu 22.04
2. **Environment Check**: Validates required environment variables
3. **Repository Clone**: Clones the specified GitHub repository
4. **Commit Checkout**: Switches to specified commit/branch/tag
5. **Dependency Installation**: Runs user-specified setup commands
6. **Configuration Save**: Stores configuration for cloud deployment
7. **Echidna Execution**: Runs fuzzing with specified entry point

### File Structure

```
echidna-local-test/
├── Dockerfile           # Ubuntu 22.04 + Echidna + Foundry setup
├── docker-compose.yml   # Container orchestration
├── entrypoint.sh       # Container startup script
├── run.sh              # Main user interface script
├── quick-test.sh       # Quick testing script
├── env.example         # Configuration template
├── .env                # Your configuration (git-ignored)
├── output/             # Output directory (created automatically)
│   └── fuzzing_config.json
└── configs/            # Additional configs (created automatically)
```