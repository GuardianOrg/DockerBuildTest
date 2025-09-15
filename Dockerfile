# Use Ubuntu 22.04 to match Digital Ocean droplets
# Force platform to linux/amd64 for consistency across architectures
FROM --platform=linux/amd64 ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH=$PATH:/root/.foundry

# Install base dependencies and architecture compatibility
RUN apt-get update && \
    apt-get install -y \
    git \
    unzip \
    curl \
    python3-pip \
    npm \
    # Add libraries needed for x86_64 binaries on ARM
    libc6 \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

# Setup script from your requirements
RUN echo "🔧 Installing Echidna + Foundry..." && \
    # Download custom echidna binary from DigitalOcean Spaces
    curl -fsSL https://guardianexec-echidna.nyc3.digitaloceanspaces.com/echidna -o /usr/local/bin/echidna && \
    chmod +x /usr/local/bin/echidna && \
    # Manual Foundry install (avoids foundryup path issues)
    curl -L https://github.com/foundry-rs/foundry/releases/download/nightly-de33b6af53005037b463318d2628b5cfcaf39916/foundry_nightly_linux_amd64.tar.gz -o foundry.tar.gz && \
    mkdir -p /root/.foundry && \
    tar -xzf foundry.tar.gz -C /root/.foundry && \
    # Link binaries globally so forge works
    ln -s /root/.foundry/forge /usr/local/bin/forge && \
    ln -s /root/.foundry/cast /usr/local/bin/cast && \
    ln -s /root/.foundry/anvil /usr/local/bin/anvil && \
    # Clean up
    rm foundry.tar.gz && \
    # Verify it works
    forge --version && \
    echo "✅ Setup complete"

# Create working directory
WORKDIR /workspace

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
