# JS vs Go Web Framework Benchmark

A comprehensive performance comparison between JavaScript (Bun runtime) and Go web frameworks using industry-standard benchmarking tools.

## 🚀 Overview

This project benchmarks the following web frameworks across different runtime environments:

### Go Frameworks
- **Go Vanilla (net/http)**: Standard Go HTTP server using the built-in `net/http` package
- **Go Fiber**: Fast Express-inspired web framework built on top of Fasthttp

### JavaScript/TypeScript Frameworks (Bun Runtime)
- **Bun Vanilla**: Pure Bun HTTP server using Bun's native HTTP APIs
- **Hono.js**: Ultrafast web framework for Cloudflare Workers, Deno, Bun, and Node.js

## 📊 Benchmark Results

> **📊 Benchmark results will appear here automatically after running your first benchmark.**
> 
> To get started quickly, run: `./quick-start.sh` or `make install && make bench`

| Framework | Status | Ready to Benchmark |
|-----------|--------|-------------------|
| **Go Vanilla** | ✅ Implemented | `make start-go-vanilla` |
| **Go Fiber** | ✅ Implemented | `make start-go-fiber` |
| **Bun Vanilla** | ✅ Implemented | `make start-bun-vanilla` |
| **Hono.js on Bun** | ✅ Implemented | `make start-hono-bun` |

*Results will be automatically updated when benchmarks are run via CI/CD or manually.*

## 🤝 Contributing New Frameworks

**Want to add your favorite web framework to the benchmark?** We've made it super easy!

### ⚡ Quick Add (Automated)

```bash
# Interactive framework generator
make add-server

# Follow the prompts to add your framework:
# - Framework name (e.g., 'express-node', 'gin-go')
# - Runtime (Go, Bun, Node.js, or other)
# - Dependencies and setup commands
# - Author information
```

### 🔧 Available Templates

- **Go Template**: For any Go web framework (Gin, Echo, Chi, etc.)
- **Bun Template**: For TypeScript frameworks on Bun runtime
- **Node.js Template**: For JavaScript/TypeScript frameworks on Node.js

### ✅ Validation & Testing

```bash
# Validate your implementation
make validate-server SERVER=your-framework-name

# Quick benchmark test
make bench-your-framework-name
```

### 📚 Comprehensive Guide

See [ADD-NEW-SERVER.md](ADD-NEW-SERVER.md) for detailed instructions, examples, and best practices.

## 🚀 Getting Started

### Option 1: Automated Setup (Recommended)

The fastest way to get started is with our automated setup script:

```bash
# Clone the repository
git clone https://github.com/MePriyanshuHoo/WebServerBenchmarking.git
cd WebServerBenchmarking

# Run the automated setup script
./quick-start.sh
```

This script will:
- ✅ Detect your operating system
- ✅ Install all required dependencies (Go, Bun, wrk, etc.)
- ✅ Set up the project dependencies
- ✅ Run health checks to verify everything works
- ✅ Optionally run a quick benchmark

### Option 2: Manual Setup

If you prefer manual control or the automated script doesn't work for your system:

```bash
# Install dependencies (choose your platform)
## macOS
brew install go wrk jq curl
curl -fsSL https://bun.sh/install | bash

## Ubuntu/Debian
sudo apt-get install golang-go wrk jq curl lsof
curl -fsSL https://bun.sh/install | bash

## Using project Makefile
make install-deps

# Setup the project
make setup

# Verify everything works
make health-check

# Run your first benchmark
make bench
```

### Option 3: Docker (Isolated Environment)

For a completely isolated environment:

```bash
# Using Docker Compose (recommended)
docker-compose up benchmark

# Or build and run manually
docker build -t jsvsgo-benchmark .
docker run --rm -v $(pwd)/results:/app/results jsvsgo-benchmark
```

### Quick Validation

After setup, verify everything is working:

```bash
# Test all servers can start
make health-check

# Run a quick 10-second benchmark
./scripts/benchmark.sh --duration 10 --connections 25 --threads 2

# Check results were generated
ls results/
```

## 🛠️ Prerequisites & Installation

### Prerequisites

```bash
# macOS (using Homebrew)
brew install go wrk jq curl
curl -fsSL https://bun.sh/install | bash

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y golang-go wrk jq curl lsof
curl -fsSL https://bun.sh/install | bash

# Or use the automated installer
make install-deps
```

### Setup and Run

```bash
# Clone the repository
git clone https://github.com/MePriyanshuHoo/WebServerBenchmarking.git
cd WebServerBenchmarking

# Install all dependencies and setup
make install

# Run health check to verify everything works
make health-check

# Run the full benchmark suite
make bench

# Or run with custom parameters
./scripts/benchmark.sh --duration 60 --connections 200 --threads 8
```

## 📋 Test Endpoints

Each server implements identical endpoints for fair comparison:

1. **GET /**: Simple "Hello, World!" JSON response
2. **GET /health**: Health check endpoint
3. **GET /user/:id**: Parameterized route returning user data
4. **POST /users**: Create user endpoint (accepts JSON payload)

## ⚙️ Benchmark Configuration

Default settings:
- **Duration**: 30 seconds per test
- **Connections**: 100 concurrent connections
- **Threads**: 4 worker threads
- **Warmup**: 5 seconds before each test
- **Tool**: [wrk](https://github.com/wg/wrk) HTTP benchmarking tool

## 🎯 Running Benchmarks

### Basic Usage

```bash
# Full benchmark suite (recommended first run)
make bench

# Quick benchmark (CI-friendly, faster)
make bench-ci

# Custom parameters
./scripts/benchmark.sh --duration 60 --connections 200 --threads 8

# Load testing with different profiles
make bench-load-test
```

### Benchmark Options

| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `--duration` | Test duration in seconds | 30 | 5-300 |
| `--connections` | Concurrent connections | 100 | 1-1000+ |
| `--threads` | Worker threads | 4 | 1-16 |

### Individual Framework Testing

```bash
# Test specific frameworks
make bench-go-vanilla     # Quick test of Go vanilla
make bench-go-fiber       # Quick test of Go Fiber
make bench-bun-vanilla    # Quick test of Bun vanilla
make bench-hono-bun       # Quick test of Hono.js

# Start servers individually for manual testing
make start-go-vanilla     # http://localhost:8080
make start-go-fiber       # http://localhost:8080
make start-bun-vanilla    # http://localhost:8080
make start-hono-bun       # http://localhost:8080

# Stop all servers
make stop-servers
```

### Results and Reporting

```bash
# Generate/update README with latest results
make readme

# View raw results
cat results/benchmark_YYYYMMDD_HHMMSS.json | jq .

# List all benchmark runs
ls results/benchmark_*.json
```

## 📁 Project Structure

```
jsvsgo-benchmark/
├── servers/                 # Framework implementations
│   ├── go-vanilla/          # Go net/http server
│   ├── go-fiber/            # Go Fiber server
│   ├── bun-vanilla/         # Bun native HTTP server
│   └── hono-bun/            # Hono.js on Bun runtime
├── templates/               # Templates for new frameworks
│   ├── go-template/         # Go framework template
│   ├── bun-template/        # Bun/TypeScript template
│   └── node-template/       # Node.js template
├── tools/                   # Extensibility tools
│   ├── add-server.sh        # Interactive server generator
│   └── validate-server.sh   # Server validation tool
├── scripts/
│   ├── benchmark.sh         # Main benchmark script (auto-discovery)
│   ├── generate_readme.go   # README generator
│   └── go.mod
├── results/                 # Benchmark results (JSON)
├── .github/workflows/       # CI/CD workflows
├── Makefile                 # Project automation (extensible)
├── benchmark.json           # Project configuration
├── ADD-NEW-SERVER.md        # Comprehensive contribution guide
└── README.md               # This file (auto-generated results)
```

## 🔄 Continuous Integration

This project includes a complete CI/CD setup with GitHub Actions that automatically:

- **✅ Runs on every commit** to main branch
- **✅ Runs on every pull request** with result comments
- **✅ Monthly scheduled runs** with comprehensive load testing
- **✅ Manual trigger support** with custom parameters
- **📊 Auto-updates README** with latest benchmark results
- **🔄 Multi-environment testing** (standard, high-load, endurance)

### CI Configuration

The GitHub Actions workflow (`.github/workflows/benchmark.yml`) provides:
- Automated dependency installation
- Health checks before benchmarking
- Result storage as artifacts
- README auto-generation and commit
- PR comment integration with performance summaries

### Triggering Benchmarks

```bash
# Local CI simulation
CI=true make bench-ci

# Docker CI testing
docker-compose --profile ci up benchmark-ci

# View CI results locally
cat results/benchmark_*.json | jq '.configuration'
```

## 🎯 Available Commands

```bash
# Setup and installation
make install          # Install all dependencies
make setup           # Setup project dependencies only
make clean           # Clean build artifacts

# Benchmarking
make bench           # Run full benchmark suite
make bench-ci        # Run with CI-friendly settings
make bench-load-test # Test with multiple load patterns

# Development
make health-check    # Verify all servers work
make start-go-vanilla    # Start individual servers
make start-go-fiber
make start-bun-vanilla
make start-hono-bun
make stop-servers    # Stop all running servers

# Extensibility & Contributing
make add-server      # Add new server implementation (interactive)
make validate-server SERVER=my-framework  # Validate implementation
make list-servers    # List all available servers
make templates       # Show available templates
make validate-all    # Validate all server implementations

# Utilities
make readme          # Generate README from latest results
make versions        # Check installed tool versions
```

## 📈 Methodology

### Testing Approach
- Each server runs on identical hardware configuration
- Servers are warmed up before benchmarking begins
- Multiple endpoint types tested to simulate real-world usage
- Latency percentiles (P50, P75, P90, P99) captured for detailed analysis
- Multiple runs to ensure consistency

### Metrics Collected
- **Requests per second**: Primary throughput metric
- **Average latency**: Mean response time
- **Latency percentiles**: Distribution of response times
- **Transfer rate**: Data throughput (MB/s)

### Environment
- **OS**: macOS/Linux
- **Network**: Local loopback (eliminates network latency)
- **Isolation**: Each server tested independently
- **Consistency**: Same test data and patterns across all frameworks

## 🔧 Development

### Adding New Frameworks

1. Create a new directory under `servers/`
2. Implement the required endpoints (see existing servers for reference)
3. Add the server to `scripts/benchmark.sh`
4. Update this README

### Modifying Tests

- Edit `scripts/benchmark.sh` for benchmark parameters
- Modify `scripts/generate_readme.go` for report formatting
- Update GitHub Actions workflow in `.github/workflows/benchmark.yml`

## 🤝 Contributing

We welcome contributions! The project is designed to be **easily extensible** by anyone.

### 🚀 Adding New Web Frameworks

The **easiest way** to contribute is by adding new framework implementations:

```bash
# Use our interactive generator
make add-server

# Or see the comprehensive guide
open ADD-NEW-SERVER.md
```

**Supported runtimes**: Go, Node.js, Bun, Deno, Python, Rust, Java, and more!

### 🔧 Contribution Process

1. **Fork** the repository
2. **Add your framework** using `make add-server` or manually
3. **Validate** your implementation: `make validate-server SERVER=your-framework`
4. **Test** thoroughly: `make health-check` and `make bench-your-framework`
5. **Submit** a pull request with your implementation

### 🎯 What We're Looking For

- **Any web framework** in any language/runtime
- **Production-ready** implementations showcasing the framework's capabilities
- **Well-documented** code with clear setup instructions
- **Consistent APIs** that match our endpoint requirements

### 💡 Ideas for Contributions

**New Frameworks:**
- **Go**: Gin, Echo, Chi, Gorilla Mux, Buffalo, Revel
- **Node.js**: Express, Fastify, Koa, Hapi, Restify, Polka
- **Bun**: Hono, Elysia, pure Bun implementations
- **Python**: FastAPI, Flask, Django, Starlette, Tornado
- **Rust**: Actix-web, Warp, Rocket, Axum, Tide
- **Java**: Spring Boot, Micronaut, Quarkus, Vert.x
- **C#**: ASP.NET Core, Nancy, Carter
- **Other**: Phoenix (Elixir), Vapor (Swift), etc.

**Infrastructure Improvements:**
- Additional test scenarios (file uploads, database queries)
- Memory usage and CPU utilization tracking
- Enhanced visualization tools
- Multi-language benchmark comparisons
- Performance regression detection

## 📜 License

MIT License - feel free to use this benchmark suite for your own comparisons and research.

## 🔗 Resources

- [Go Documentation](https://golang.org/doc/)
- [Bun Documentation](https://bun.sh/docs)
- [Fiber Framework](https://docs.gofiber.io/)
- [Hono.js Framework](https://hono.dev/)
- [wrk Benchmarking Tool](https://github.com/wg/wrk)

---

*This README is automatically updated with benchmark results. Last manual update: 2024-01-01*
