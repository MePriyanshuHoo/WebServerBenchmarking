# JS vs Go Web Framework Benchmark - Setup Guide

A comprehensive setup guide for running performance benchmarks between JavaScript (Bun runtime) and Go web frameworks.

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Manual Installation](#-manual-installation)
- [Docker Setup](#-docker-setup)
- [Configuration](#-configuration)
- [Running Benchmarks](#-running-benchmarks)
- [Development Setup](#-development-setup)
- [CI/CD Setup](#-cicd-setup)
- [Troubleshooting](#-troubleshooting)
- [Advanced Usage](#-advanced-usage)

## 🎯 Project Overview

This benchmark suite compares the performance of web frameworks across two runtime environments:

### Frameworks Tested
- **Go Vanilla**: Standard `net/http` package
- **Go Fiber**: Express-inspired framework on Fasthttp
- **Bun Vanilla**: Native Bun HTTP server
- **Hono.js**: Ultrafast framework running on Bun

### Test Scenarios
- Simple GET endpoints
- Parameterized routes
- JSON POST requests
- Health checks
- Latency distribution analysis

## 🔧 Prerequisites

### System Requirements
- **OS**: macOS, Linux (Ubuntu/Debian/CentOS/Arch)
- **RAM**: Minimum 4GB (8GB+ recommended for heavy load testing)
- **CPU**: Multi-core processor (affects thread-based testing)
- **Disk**: ~500MB free space

### Required Tools
- **Go**: 1.21 or later
- **Bun**: Latest version
- **wrk**: HTTP benchmarking tool
- **curl**: HTTP client
- **jq**: JSON processor (optional, for enhanced output)

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)

```bash
# Clone the repository
git clone <your-repo-url>
cd jsvsgo-benchmark

# Run the automated setup script
./quick-start.sh
```

This script will:
1. Detect your operating system
2. Install all required dependencies
3. Set up the project
4. Run health checks
5. Offer to run a quick benchmark

### Option 2: Using Make

```bash
# Install everything
make install

# Run health check
make health-check

# Run benchmark
make bench
```

### Option 3: Docker (Isolation)

```bash
# Build and run
docker-compose up benchmark

# Or build manually
docker build -t jsvsgo-benchmark .
docker run --rm -v $(pwd)/results:/app/results jsvsgo-benchmark
```

## 🛠️ Manual Installation

### Step 1: Install Go

#### macOS (Homebrew)
```bash
brew install go
```

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install golang-go
```

#### CentOS/RHEL
```bash
sudo yum install golang
```

#### Manual Installation
```bash
# Download and install Go 1.21+
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
```

### Step 2: Install Bun

```bash
# All platforms
curl -fsSL https://bun.sh/install | bash

# Reload your shell or run:
export PATH="$HOME/.bun/bin:$PATH"
```

### Step 3: Install wrk

#### macOS
```bash
brew install wrk
```

#### Ubuntu/Debian
```bash
sudo apt-get install wrk
```

#### From Source (All Platforms)
```bash
git clone https://github.com/wg/wrk.git
cd wrk
make
sudo mv wrk /usr/local/bin/
```

### Step 4: Install Additional Tools

```bash
# macOS
brew install jq curl

# Ubuntu/Debian
sudo apt-get install jq curl lsof

# CentOS/RHEL
sudo yum install jq curl
```

### Step 5: Setup Project

```bash
# Navigate to project directory
cd jsvsgo-benchmark

# Setup Go dependencies
cd servers/go-vanilla && go mod tidy
cd ../go-fiber && go mod tidy
cd ../../scripts && go mod tidy

# Setup Bun dependencies
cd ../servers/hono-bun && bun install

# Make scripts executable
chmod +x ../scripts/benchmark.sh ../quick-start.sh

# Verify setup
make health-check
```

## 🐳 Docker Setup

### Basic Docker Usage

```bash
# Build the image
docker build -t jsvsgo-benchmark .

# Run default benchmark
docker run --rm -v $(pwd)/results:/app/results jsvsgo-benchmark

# Run with custom parameters
docker run --rm -v $(pwd)/results:/app/results jsvsgo-benchmark \
  ./scripts/benchmark.sh --duration 60 --connections 200 --threads 8

# Interactive mode
docker run --rm -it jsvsgo-benchmark bash
```

### Docker Compose Profiles

```bash
# Default benchmark
docker-compose up benchmark

# CI-friendly benchmark (faster)
docker-compose --profile ci up benchmark-ci

# Load testing
docker-compose --profile load-test up benchmark-light benchmark-heavy

# Endurance testing
docker-compose --profile endurance up benchmark-endurance

# Development environment
docker-compose --profile dev up -d dev
docker-compose exec dev bash

# Individual servers
docker-compose --profile servers up go-vanilla go-fiber
```

### Environment Variables for Docker

```bash
# Custom benchmark settings
DURATION=120 CONNECTIONS=300 THREADS=8 docker-compose up benchmark

# Enable CI mode
CI=true docker-compose up benchmark
```

## ⚙️ Configuration

### Benchmark Parameters

Edit `benchmark.json` or use command-line flags:

```bash
# Command-line options
./scripts/benchmark.sh \
  --duration 60 \        # Test duration in seconds
  --connections 200 \    # Concurrent connections
  --threads 8           # Worker threads
```

### Configuration File

The `benchmark.json` file contains:
- Framework definitions
- Test endpoint specifications
- Load testing profiles
- CI/CD settings
- Tool requirements

### Environment Variables

```bash
export DURATION=30        # Default: 30 seconds
export CONNECTIONS=100    # Default: 100 connections
export THREADS=4          # Default: 4 threads
export CI=true           # Enable CI mode (reduced settings)
```

## 🏃 Running Benchmarks

### Basic Usage

```bash
# Full benchmark suite (default settings)
make bench

# CI-friendly (faster)
make bench-ci

# Custom parameters
./scripts/benchmark.sh --duration 60 --connections 200 --threads 8

# Load testing profiles
make bench-load-test
```

### Individual Framework Testing

```bash
# Quick individual tests
make bench-go-vanilla
make bench-go-fiber
make bench-bun-vanilla
make bench-hono-bun
```

### Server Management

```bash
# Start individual servers for testing
make start-go-vanilla    # http://localhost:8080
make start-go-fiber      # http://localhost:8080
make start-bun-vanilla   # http://localhost:8080
make start-hono-bun      # http://localhost:8080

# Stop all servers
make stop-servers
```

### Results

```bash
# Generate README with latest results
make readme

# View results directly
cat results/benchmark_YYYYMMDD_HHMMSS.json | jq .

# Compare multiple runs
ls results/benchmark_*.json
```

## 👨‍💻 Development Setup

### Hot Reload Development

```bash
# Go servers with air (install: go install github.com/cosmtrek/air@latest)
make dev-go-vanilla
make dev-go-fiber

# Bun servers with watch mode
make dev-bun-vanilla
make dev-hono-bun
```

### Adding New Frameworks

1. Create new server directory under `servers/`
2. Implement required endpoints:
   - `GET /` - Hello World
   - `GET /health` - Health check
   - `GET /user/:id` - Parameterized route
   - `POST /users` - JSON endpoint

3. Add to `scripts/benchmark.sh`:
   ```bash
   benchmark_server "my-framework" "start-command" "./servers/my-framework"
   ```

4. Update `benchmark.json` configuration

### Testing Changes

```bash
# Health check after changes
make health-check

# Quick validation
./scripts/benchmark.sh --duration 5 --connections 10 --threads 1
```

## 🔄 CI/CD Setup

### GitHub Actions

The included workflow (`.github/workflows/benchmark.yml`) runs:
- On every commit to main
- On pull requests
- Monthly scheduled runs
- Manual triggers

### Customizing CI

Edit `.github/workflows/benchmark.yml`:

```yaml
# Adjust benchmark parameters for CI
env:
  DURATION: 15
  CONNECTIONS: 50
  THREADS: 2
```

### Local CI Testing

```bash
# Test with CI settings
CI=true make bench-ci

# Simulate GitHub Actions environment
docker-compose --profile ci up benchmark-ci
```

## 🐛 Troubleshooting

### Common Issues

#### Port Already in Use
```bash
# Check what's using port 8080
lsof -i :8080

# Kill processes
make stop-servers

# Or manually
pkill -f "go run\|bun run"
```

#### Go Build Issues
```bash
# Clean and rebuild
cd servers/go-vanilla
go clean -cache
go mod tidy
go build .
```

#### Bun Installation Issues
```bash
# Reinstall Bun
curl -fsSL https://bun.sh/install | bash

# Check installation
bun --version

# Add to PATH
export PATH="$HOME/.bun/bin:$PATH"
```

#### wrk Not Found
```bash
# Install wrk manually
git clone https://github.com/wg/wrk.git
cd wrk && make && sudo mv wrk /usr/local/bin/
```

#### Permission Issues
```bash
# Make scripts executable
chmod +x scripts/*.sh *.sh

# Fix ownership (if needed)
sudo chown -R $USER:$USER .
```

### Performance Issues

#### Low Benchmark Scores
- Ensure no other processes are consuming CPU
- Check system load: `top` or `htop`
- Verify server startup: `make health-check`
- Try lower concurrency: `--connections 25`

#### Memory Issues
- Monitor with: `free -h` or `htop`
- Reduce connection count
- Enable CI mode: `CI=true`

#### Network Issues
- Use loopback only (127.0.0.1)
- Check firewall settings
- Verify localhost resolution

### Debugging

```bash
# Enable verbose logging
DEBUG=true ./scripts/benchmark.sh

# Check server logs
cd servers/go-vanilla && go run . 2>&1 | tee server.log

# Validate endpoints manually
curl -v http://localhost:8080/health
curl -X POST -H "Content-Type: application/json" \
  -d '{"name":"test"}' http://localhost:8080/users
```

## 🚀 Advanced Usage

### Custom Load Profiles

```bash
# Create custom profiles in benchmark.json
{
  "stress_test": {
    "duration": 300,
    "connections": 1000,
    "threads": 16
  }
}
```

### Batch Testing

```bash
# Multiple configurations
for connections in 25 50 100 200; do
  ./scripts/benchmark.sh --connections $connections --duration 30
done
```

### Result Analysis

```bash
# Extract specific metrics
jq '.results["go-vanilla"][0].requests_per_sec' results/benchmark_*.json

# Compare frameworks
jq -r '.results | to_entries[] | "\(.key): \(.value[0].requests_per_sec)"' \
  results/benchmark_*.json
```

### Monitoring

```bash
# System monitoring during benchmarks
htop &
iotop &
nethogs &

# Server resource usage
pidstat -u -r 1

# Network monitoring
iftop -i lo
```

### Extending Results

Modify `scripts/generate_readme.go` to add:
- Memory usage tracking
- CPU utilization
- Custom metrics
- Historical comparisons

## 📚 Additional Resources

- [Go Documentation](https://golang.org/doc/)
- [Bun Documentation](https://bun.sh/docs)
- [Fiber Framework](https://docs.gofiber.io/)
- [Hono.js Documentation](https://hono.dev/)
- [wrk Documentation](https://github.com/wg/wrk)

## 🆘 Getting Help

1. Check this setup guide
2. Review troubleshooting section
3. Examine existing issues in the repository
4. Run health checks: `make health-check`
5. Try CI mode: `make bench-ci`

For persistent issues, please provide:
- Operating system and version
- Tool versions (`make versions`)
- Error messages
- Steps to reproduce

---

*This setup guide covers comprehensive installation and usage. For quick start, use `./quick-start.sh`*