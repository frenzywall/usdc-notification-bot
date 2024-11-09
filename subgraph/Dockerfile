# Docker config for Graph Node
# Base image for Graph Node
FROM ubuntu:20.04

# Set environment variables
ENV IPFS_API_HOST=http://ipfs:5001 \
    POSTGRES_HOST=postgres \
    POSTGRES_DB=graph \
    POSTGRES_USER=graph \
    POSTGRES_PASSWORD=letmein

# Install dependencies
RUN apt-get update && \
    apt-get install -y curl gnupg software-properties-common postgresql-client

# Install Rust and Node.js for Graph CLI
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y && \
    . $HOME/.cargo/env && \
    curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs

# Install Graph CLI
RUN npm install -g @graphprotocol/graph-cli

# Set working directory
WORKDIR /usr/src/app

# Copy subgraph files
COPY . .

# Install subgraph dependencies
RUN npm install

# Command to deploy and run the subgraph (adjust as needed for local or hosted)
CMD ["graph", "codegen"] && ["graph", "build"] && ["graph", "deploy", "--product", "hosted-service", "<YOUR_GITHUB_USERNAME>/usdc-transfer-tracker"]
