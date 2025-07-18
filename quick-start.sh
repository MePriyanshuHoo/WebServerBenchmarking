#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Banner
print_banner() {
    echo -e "${BOLD}${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                  JS vs Go Web Framework Benchmark                ║"
    echo "║                          Quick Start                             ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BOLD}${CYAN}[STEP]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root is not recommended. Consider running as a regular user."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        PACKAGE_MANAGER="brew"
    elif [[ -f /etc/debian_version ]]; then
        OS="ubuntu"
        PACKAGE_MANAGER="apt"
    elif [[ -f /etc/redhat-release ]]; then
        OS="centos"
        PACKAGE_MANAGER="yum"
    elif [[ -f /etc/arch-release ]]; then
        OS="arch"
        PACKAGE_MANAGER="pacman"
    else
        OS="unknown"
        PACKAGE_MANAGER="unknown"
    fi

    print_status "Detected OS: $OS with package manager: $PACKAGE_MANAGER"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install dependencies based on OS
install_dependencies() {
    print_step "Installing dependencies..."

    local missing_deps=()

    # Check for required tools
    if ! command_exists go; then
        missing_deps+=("go")
    fi

    if ! command_exists bun; then
        missing_deps+=("bun")
    fi

    if ! command_exists wrk; then
        missing_deps+=("wrk")
    fi

    if ! command_exists curl; then
        missing_deps+=("curl")
    fi

    if ! command_exists jq; then
        missing_deps+=("jq")
    fi

    if [ ${#missing_deps[@]} -eq 0 ]; then
        print_success "All dependencies are already installed!"
        return 0
    fi

    print_status "Missing dependencies: ${missing_deps[*]}"

    case $PACKAGE_MANAGER in
        brew)
            print_status "Installing with Homebrew..."
            if ! command_exists brew; then
                print_error "Homebrew not found. Please install from: https://brew.sh"
                exit 1
            fi

            for dep in "${missing_deps[@]}"; do
                if [ "$dep" = "bun" ]; then
                    print_status "Installing Bun..."
                    curl -fsSL https://bun.sh/install | bash
                else
                    print_status "Installing $dep..."
                    brew install "$dep"
                fi
            done
            ;;

        apt)
            print_status "Installing with apt..."
            sudo apt-get update

            for dep in "${missing_deps[@]}"; do
                case $dep in
                    go)
                        sudo apt-get install -y golang-go
                        ;;
                    bun)
                        print_status "Installing Bun..."
                        curl -fsSL https://bun.sh/install | bash
                        ;;
                    wrk)
                        sudo apt-get install -y wrk
                        ;;
                    *)
                        sudo apt-get install -y "$dep"
                        ;;
                esac
            done
            ;;

        yum)
            print_status "Installing with yum..."
            for dep in "${missing_deps[@]}"; do
                case $dep in
                    go)
                        sudo yum install -y golang
                        ;;
                    bun)
                        print_status "Installing Bun..."
                        curl -fsSL https://bun.sh/install | bash
                        ;;
                    wrk)
                        print_warning "wrk not available in yum. Please install manually from: https://github.com/wg/wrk"
                        ;;
                    *)
                        sudo yum install -y "$dep"
                        ;;
                esac
            done
            ;;

        pacman)
            print_status "Installing with pacman..."
            for dep in "${missing_deps[@]}"; do
                case $dep in
                    bun)
                        print_status "Installing Bun..."
                        curl -fsSL https://bun.sh/install | bash
                        ;;
                    *)
                        sudo pacman -S --noconfirm "$dep"
                        ;;
                esac
            done
            ;;

        *)
            print_error "Unsupported package manager. Please install manually:"
            echo "  - Go: https://golang.org/dl/"
            echo "  - Bun: https://bun.sh/"
            echo "  - wrk: https://github.com/wg/wrk"
            echo "  - jq, curl"
            exit 1
            ;;
    esac

    # Reload shell for Bun if it was just installed
    if [[ " ${missing_deps[*]} " =~ " bun " ]]; then
        print_status "Reloading shell for Bun..."
        export PATH="$HOME/.bun/bin:$PATH"
    fi
}

# Setup project dependencies
setup_project() {
    print_step "Setting up project dependencies..."

    # Go dependencies
    print_status "Setting up Go servers..."
    (cd servers/go-vanilla && go mod tidy)
    (cd servers/go-fiber && go mod tidy)

    # Bun dependencies
    print_status "Setting up Bun servers..."
    (cd servers/hono-bun && bun install)

    # Scripts
    print_status "Setting up benchmark scripts..."
    (cd scripts && go mod tidy)

    # Make scripts executable
    chmod +x scripts/benchmark.sh

    print_success "Project setup complete!"
}

# Health check
health_check() {
    print_step "Running health check..."

    local servers=("go-vanilla" "go-fiber" "bun-vanilla" "hono-bun")
    local healthy=0
    local total=${#servers[@]}

    for server in "${servers[@]}"; do
        print_status "Testing $server server..."

        case $server in
            go-vanilla|go-fiber)
                (cd servers/$server && timeout 10s go run . >/dev/null 2>&1) &
                ;;
            bun-vanilla|hono-bun)
                (cd servers/$server && timeout 10s bun run server.ts >/dev/null 2>&1) &
                ;;
        esac

        local server_pid=$!
        sleep 3

        if curl -s http://localhost:8080/health >/dev/null 2>&1; then
            print_success "$server server: OK"
            ((healthy++))
        else
            print_warning "$server server: Failed to respond"
        fi

        # Clean up
        kill $server_pid 2>/dev/null || true
        pkill -f "go run\|bun run" 2>/dev/null || true
        sleep 1
    done

    print_status "Health check results: $healthy/$total servers responding"

    if [ $healthy -eq $total ]; then
        print_success "All servers are healthy!"
        return 0
    elif [ $healthy -gt 0 ]; then
        print_warning "Some servers have issues, but we can proceed"
        return 0
    else
        print_error "No servers are responding. Please check the installation"
        return 1
    fi
}

# Run quick benchmark
quick_benchmark() {
    print_step "Running quick benchmark (this will take ~2 minutes)..."

    if [ ! -d "results" ]; then
        mkdir -p results
    fi

    # Run with reduced settings for quick start
    print_status "Running benchmark with light settings..."
    ./scripts/benchmark.sh --duration 10 --connections 25 --threads 2

    print_step "Generating README with results..."
    (cd scripts && go run generate_readme.go)

    print_success "Quick benchmark complete!"
    print_status "Check README.md for detailed results"
}

# Show next steps
show_next_steps() {
    print_step "🎉 Setup Complete! Here's what you can do next:"
    echo
    echo -e "${BOLD}Quick Commands:${NC}"
    echo "  make bench           # Run full benchmark suite"
    echo "  make bench-ci        # Run with CI-friendly settings"
    echo "  make health-check    # Test all servers"
    echo "  make clean           # Clean up build artifacts"
    echo
    echo -e "${BOLD}Individual Server Testing:${NC}"
    echo "  make start-go-vanilla    # Start Go vanilla server"
    echo "  make start-go-fiber      # Start Go Fiber server"
    echo "  make start-bun-vanilla   # Start Bun vanilla server"
    echo "  make start-hono-bun      # Start Hono.js server"
    echo
    echo -e "${BOLD}Benchmarking:${NC}"
    echo "  ./scripts/benchmark.sh --help    # See all options"
    echo "  ./scripts/benchmark.sh --duration 60 --connections 200"
    echo
    echo -e "${BOLD}Results:${NC}"
    echo "  Results are saved in: ./results/"
    echo "  README.md is auto-generated with latest results"
    echo
    echo -e "${BOLD}Documentation:${NC}"
    echo "  README.md            # Full documentation"
    echo "  benchmark.json       # Project configuration"
    echo
    print_success "Happy benchmarking! 🚀"
}

# Interactive mode
interactive_setup() {
    echo
    read -p "Would you like to run a quick benchmark now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        quick_benchmark
    else
        print_status "Skipping benchmark. You can run it later with: make bench"
    fi
}

# Main execution
main() {
    print_banner

    # Check if we're in the right directory
    if [ ! -f "benchmark.json" ] || [ ! -d "servers" ]; then
        print_error "Please run this script from the project root directory"
        exit 1
    fi

    check_root
    detect_os

    print_step "Starting quick setup..."

    install_dependencies
    setup_project

    if health_check; then
        print_success "Setup successful!"

        # Check if this is an interactive terminal
        if [ -t 0 ]; then
            interactive_setup
        else
            print_status "Non-interactive mode. Skipping benchmark."
        fi

        show_next_steps
    else
        print_error "Setup failed during health check"
        exit 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --quick-bench)
            QUICK_BENCH=true
            shift
            ;;
        --no-deps)
            NO_DEPS=true
            shift
            ;;
        -h|--help)
            echo "Quick Start Script for JS vs Go Benchmark"
            echo
            echo "Usage: $0 [OPTIONS]"
            echo
            echo "Options:"
            echo "  --quick-bench    Run quick benchmark after setup"
            echo "  --no-deps        Skip dependency installation"
            echo "  -h, --help       Show this help message"
            echo
            echo "This script will:"
            echo "  1. Detect your operating system"
            echo "  2. Install required dependencies"
            echo "  3. Set up the project"
            echo "  4. Run health checks"
            echo "  5. Optionally run a quick benchmark"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Handle special flags
if [ "$NO_DEPS" = true ]; then
    print_status "Skipping dependency installation"
    setup_project
    health_check
    show_next_steps
elif [ "$QUICK_BENCH" = true ]; then
    main
    quick_benchmark
else
    main
fi
