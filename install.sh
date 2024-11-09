#!/bin/bash

# Set strict error handling
set -euo pipefail

# Configuration
LOG_FILE="install.log"
REPO_DIR="$(pwd)/usdc-notification-bot"

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

# Verify repository structure
verify_structure() {
    log "Verifying repository structure..."
    
    # Required directories
    local required_dirs=(
        "backend"
        "frontend"
        "frontend/src"
        "frontend/public"
        "subgraph"
    )
    
    # Required files
    local required_files=(
        "backend/app.js"
        "backend/Dockerfile"
        "backend/package.json"
        "frontend/Dockerfile"
        "frontend/package.json"
        "frontend/src/App.js"
        "subgraph/Dockerfile"
        "subgraph/mapping.ts"
        "subgraph/schema.graphql"
        "subgraph/subgraph.yaml"
        "docker-compose.yml"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            log "Error: Required directory '$dir' not found"
            exit 1
        fi
    done
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log "Error: Required file '$file' not found"
            exit 1
        fi
    done
    
    log "Repository structure verified"
}

# Function to install system dependencies
install_system_deps() {
    log "Installing system dependencies..."
    
    # Update package lists
    sudo apt-get update
    
    # Install basic requirements
    sudo apt-get install -y \
        curl \
        build-essential \
        git \
        apt-transport-https \
        ca-certificates \
        software-properties-common

    log "System dependencies installed"
}

# Function to install Node.js and npm
install_nodejs() {
    log "Installing Node.js and npm..."
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
        log "Node.js $(node --version) and npm $(npm --version) installed"
    else
        log "Node.js is already installed: $(node --version)"
    fi
}

# Function to install Docker and Docker Compose
install_docker() {
    log "Installing Docker and Docker Compose..."
    if ! command -v docker &> /dev/null; then
        # Install Docker
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        
        # Install Docker Compose
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        
        # Start and enable Docker service
        sudo systemctl start docker
        sudo systemctl enable docker
        
        log "Docker $(docker --version) and Docker Compose $(docker-compose --version) installed"
    else
        log "Docker is already installed: $(docker --version)"
    fi
}

# Function to install frontend dependencies
install_frontend_deps() {
    log "Installing frontend dependencies..."
    cd "$REPO_DIR/frontend"
    if [ -f "package.json" ]; then
        npm install
        log "Frontend dependencies installed"
    else
        log "Error: frontend/package.json not found"
        exit 1
    fi
}

# Function to install backend dependencies
install_backend_deps() {
    log "Installing backend dependencies..."
    cd "$REPO_DIR/backend"
    if [ -f "package.json" ]; then
        npm install
        log "Backend dependencies installed"
    else
        log "Error: backend/package.json not found"
        exit 1
    fi
}

# Function to install subgraph dependencies
install_subgraph_deps() {
    log "Installing subgraph dependencies..."
    cd "$REPO_DIR/subgraph"
    
    # Initialize package.json if it doesn't exist
    if [ ! -f "package.json" ]; then
        npm init -y
    fi
    
    # Install Graph CLI and dependencies
    npm install --save-dev @graphprotocol/graph-cli
    npm install --save-dev @graphprotocol/graph-ts
    
    # Install Graph CLI globally if not present
    if ! command -v graph &> /dev/null; then
        sudo npm install -g @graphprotocol/graph-cli
        log "Graph CLI installed: $(graph --version)"
    fi
    
    log "Subgraph dependencies installed"
}

# Function to verify Docker configurations
verify_docker_configs() {
    log "Verifying Docker configurations..."
    
    # Test Docker Compose configuration
    if docker-compose config --quiet; then
        log "Docker Compose configuration is valid"
    else
        log "Error: Invalid Docker Compose configuration"
        exit 1
    fi
}

# Main installation function
main() {
    log "Starting installation process for USDC Notification Bot..."
    
    # Change to repository directory
    cd "$REPO_DIR"
    
    verify_structure
    install_system_deps
    install_nodejs
    install_docker
    
    # Install project dependencies
    install_frontend_deps
    install_backend_deps
    install_subgraph_deps
    
    verify_docker_configs
    
    log "Installation completed successfully!"
    log "Next steps:"
    log "1. Log out and log back in for Docker permissions to take effect"
    log "2. Run 'docker-compose up' to start the services"
    log "3. Check README.md for additional configuration steps"
}

# Run main installation
main 2>&1 | tee -a "$LOG_FILE"