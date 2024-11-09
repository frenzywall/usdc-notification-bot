#!/bin/bash

# Set strict error handling
set -euo pipefail

# Log file setup
LOG_FILE="/var/log/dapp_install.log"
INSTALL_DIR="$HOME/dapp_project"

# Helper function for logging
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Error handler
handle_error() {
    local line_no=$1
    log "Error occurred in line ${line_no}"
    exit 1
}

trap 'handle_error ${LINENO}' ERR

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    log "This script must be run as root"
    exit 1
fi

# Create installation directory
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Function to install Node.js and npm
install_nodejs() {
    log "Installing Node.js and npm..."
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
        log "Node.js $(node --version) and npm $(npm --version) installed"
    else
        log "Node.js is already installed: $(node --version)"
    fi
}

# Function to install Rust
install_rust() {
    log "Installing Rust..."
    if ! command -v rustc &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        log "Rust $(rustc --version) installed"
    else
        log "Rust is already installed: $(rustc --version)"
    fi
}

# Function to install Docker and Docker Compose
install_docker() {
    log "Installing Docker and Docker Compose..."
    if ! command -v docker &> /dev/null; then
        apt-get update
        apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
        add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        apt-get update
        apt-get install -y docker-ce docker-compose
        systemctl enable docker
        systemctl start docker
        usermod -aG docker $SUDO_USER
        log "Docker $(docker --version) and Docker Compose $(docker-compose --version) installed"
    else
        log "Docker is already installed: $(docker --version)"
    fi
}

# Function to install Graph CLI
install_graph_cli() {
    log "Installing Graph CLI..."
    if ! command -v graph &> /dev/null; then
        npm install -g @graphprotocol/graph-cli
        log "Graph CLI installed: $(graph --version)"
    else
        log "Graph CLI is already installed: $(graph --version)"
    fi
}

# Function to create and setup project structure
setup_project_structure() {
    log "Setting up project structure..."
    
    # Create project directories
    mkdir -p "$INSTALL_DIR"/{subgraph,backend,frontend}
    
    # Setup subgraph
    cd "$INSTALL_DIR/subgraph"
    if [ ! -f package.json ]; then
        npm init -y
        npm install ethers graphql
    fi
    
    # Setup backend
    cd "$INSTALL_DIR/backend"
    if [ ! -f package.json ]; then
        npm init -y
        npm install ethers web3 axios express
    fi
    
    # Setup frontend
    cd "$INSTALL_DIR/frontend"
    if [ ! -d node_modules ]; then
        npx create-react-app .
        npm install ethers web3
        # Uncomment below lines if you want to install UI libraries
        # npm install @mui/material @emotion/react @emotion/styled
        # npm install react-bootstrap bootstrap
    fi
}

# Main installation flow
main() {
    log "Starting installation process..."
    
    # Update package lists
    apt-get update
    
    # Install essential packages
    apt-get install -y curl build-essential git
    
    # Run installations
    install_nodejs
    install_rust
    install_docker
    install_graph_cli
    setup_project_structure
    
    log "Installation completed successfully!"
    
    # Print important next steps
    log "Important: Please log out and log back in for Docker group changes to take effect"
    log "Project has been set up in: $INSTALL_DIR"
}

# Run main installation
main 2>&1 | tee -a "$LOG_FILE"