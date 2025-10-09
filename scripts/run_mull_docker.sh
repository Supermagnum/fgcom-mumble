#!/bin/bash

# Mull Mutation Testing using Docker
# This script runs Mull in a Docker container with compatible LLVM version

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "Setting up Mull with Docker for compatibility..."

# Check if Docker is installed
if ! command -v docker >/dev/null 2>&1; then
    print_error "Docker is not installed!"
    echo "Please install Docker first:"
    echo "  sudo apt-get install docker.io"
    echo "  sudo usermod -aG docker $USER"
    echo "  # Log out and back in"
    exit 1
fi

# Create Dockerfile for Mull with compatible LLVM
cat > Dockerfile.mull << 'EOF'
FROM ubuntu:20.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    build-essential \
    cmake \
    git \
    python3 \
    llvm-13 \
    llvm-13-dev \
    clang-13 \
    lcov \
    gcov

# Install Mull 0.17.0 (compatible with LLVM 13)
RUN wget https://github.com/mull-project/mull/releases/download/0.17.0/mull-0.17.0-ubuntu-20.04.deb && \
    dpkg -i mull-0.17.0-ubuntu-20.04.deb || apt-get install -f -y

# Set environment
ENV LLVM_CONFIG=/usr/lib/llvm-13/bin/llvm-config
ENV LD_LIBRARY_PATH=/usr/lib/llvm-13/lib:$LD_LIBRARY_PATH

WORKDIR /workspace
EOF

print_status "Building Mull Docker image..."
docker build -f Dockerfile.mull -t mull-testing .

print_status "Running Mull mutation testing in Docker..."

# Run Mull in Docker container
docker run --rm -v "$(pwd)":/workspace mull-testing \
    mull-cxx --test-program=/workspace/simple_test --reporters=IDE /workspace/simple_test.o

print_success "Mull mutation testing completed in Docker!"
