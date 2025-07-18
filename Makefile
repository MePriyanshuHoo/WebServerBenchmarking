.PHONY: help install install-deps setup clean bench bench-ci readme start-go-vanilla start-go-fiber start-bun-vanilla start-hono-bun stop-servers health-check

# Default target
help:
	@echo "🚀 JS vs Go Benchmark Suite"
	@echo ""
	@echo "Available commands:"
	@echo "  help          Show this help message"
	@echo "  install       Install all dependencies"
	@echo "  install-deps  Install system dependencies (wrk, etc.)"
	@echo "  setup         Setup all server dependencies"
	@echo "  clean         Clean build artifacts and results"
	@echo "  bench         Run full benchmark suite"
	@echo "  bench-ci      Run benchmark with CI-friendly settings"
	@echo "  readme        Generate README with latest results"
	@echo "  health-check  Check if all servers can start properly"
	@echo ""
	@echo "Extensibility:"
	@echo "  add-server         Add new server implementation (interactive)"
	@echo "  validate-server    Validate server implementation"
	@echo "  list-servers       List all available servers"
	@echo "  templates          Show available templates"
	@echo ""
	@echo "Server management:"
	@echo "  start-go-vanilla   Start Go vanilla server"
	@echo "  start-go-fiber     Start Go Fiber server"
	@echo "  start-bun-vanilla  Start Bun vanilla server"
	@echo "  start-hono-bun     Start Hono.js on Bun server"
	@echo "  stop-servers       Stop all running servers"
	@echo ""
	@echo "Examples:"
	@echo "  make install       # Setup everything"
	@echo "  make bench         # Run benchmarks"
	@echo "  make readme        # Update README"
	@echo "  make add-server    # Add new framework (interactive)"
	@echo "  make validate-server SERVER=my-framework  # Validate implementation"

# Install system dependencies
install-deps:
	@echo "📦 Installing system dependencies..."
	@if command -v brew >/dev/null 2>&1; then \
		echo "Using Homebrew..."; \
		brew install wrk go jq curl; \
		curl -fsSL https://bun.sh/install | bash; \
	elif command -v apt-get >/dev/null 2>&1; then \
		echo "Using apt-get..."; \
		sudo apt-get update; \
		sudo apt-get install -y wrk golang-go jq curl lsof; \
		curl -fsSL https://bun.sh/install | bash; \
	elif command -v yum >/dev/null 2>&1; then \
		echo "Using yum..."; \
		sudo yum install -y golang jq curl; \
		echo "⚠️  Please install wrk manually from: https://github.com/wg/wrk"; \
		curl -fsSL https://bun.sh/install | bash; \
	else \
		echo "❌ Unsupported package manager. Please install manually:"; \
		echo "  - Go: https://golang.org/dl/"; \
		echo "  - Bun: https://bun.sh/"; \
		echo "  - wrk: https://github.com/wg/wrk"; \
		echo "  - jq, curl, lsof"; \
		exit 1; \
	fi

# Setup project dependencies
setup:
	@echo "🔧 Setting up project dependencies..."
	@echo "Setting up Go vanilla server..."
	@cd servers/go-vanilla && go mod tidy
	@echo "Setting up Go Fiber server..."
	@cd servers/go-fiber && go mod tidy
	@echo "Setting up Hono.js server..."
	@cd servers/hono-bun && bun install
	@echo "Setting up scripts..."
	@cd scripts && go mod tidy
	@chmod +x scripts/benchmark.sh
	@echo "✅ Setup complete!"

# Full installation
install: install-deps setup

# Clean build artifacts and results
clean:
	@echo "🧹 Cleaning up..."
	@rm -f servers/go-vanilla/server
	@rm -f servers/go-fiber/server
	@rm -rf servers/*/node_modules
	@rm -rf results/benchmark_*.json
	@rm -f *.log
	@echo "✅ Cleanup complete!"

# Health check - verify all servers can start
health-check:
	@echo "🏥 Running health checks..."
	@echo "Checking Go vanilla server..."
	@cd servers/go-vanilla && timeout 10s go run . > /dev/null 2>&1 & \
		sleep 3 && \
		curl -s http://localhost:8080/health > /dev/null && \
		echo "✅ Go vanilla server OK" || echo "❌ Go vanilla server failed"; \
		pkill -f "go run"
	@sleep 2
	@echo "Checking Go Fiber server..."
	@cd servers/go-fiber && timeout 10s go run . > /dev/null 2>&1 & \
		sleep 3 && \
		curl -s http://localhost:8080/health > /dev/null && \
		echo "✅ Go Fiber server OK" || echo "❌ Go Fiber server failed"; \
		pkill -f "go run"
	@sleep 2
	@echo "Checking Bun vanilla server..."
	@cd servers/bun-vanilla && timeout 10s bun run server.ts > /dev/null 2>&1 & \
		sleep 3 && \
		curl -s http://localhost:8080/health > /dev/null && \
		echo "✅ Bun vanilla server OK" || echo "❌ Bun vanilla server failed"; \
		pkill -f "bun"
	@sleep 2
	@echo "Checking Hono.js server..."
	@cd servers/hono-bun && timeout 10s bun run server.ts > /dev/null 2>&1 & \
		sleep 3 && \
		curl -s http://localhost:8080/health > /dev/null && \
		echo "✅ Hono.js server OK" || echo "❌ Hono.js server failed"; \
		pkill -f "bun"
	@echo "🏥 Health check complete!"

# Run full benchmark
bench:
	@echo "🚀 Running benchmark suite..."
	@mkdir -p results
	@./scripts/benchmark.sh
	@echo "📊 Generating README..."
	@cd scripts && go run generate_readme.go
	@echo "✅ Benchmark complete! Check README.md for results."

# Run benchmark with CI-friendly settings
bench-ci:
	@echo "🚀 Running CI benchmark suite..."
	@mkdir -p results
	@CI=true ./scripts/benchmark.sh --duration 10 --connections 50 --threads 2
	@echo "📊 Generating README..."
	@cd scripts && go run generate_readme.go
	@echo "✅ CI Benchmark complete!"

# Generate README from latest results
readme:
	@echo "📊 Generating README..."
	@if [ ! -d "results" ] || [ -z "$$(ls -A results/benchmark_*.json 2>/dev/null)" ]; then \
		echo "❌ No benchmark results found. Run 'make bench' first."; \
		exit 1; \
	fi
	@cd scripts && go run generate_readme.go
	@echo "✅ README generated!"

# Start individual servers (for development/testing)
start-go-vanilla:
	@echo "🚀 Starting Go vanilla server..."
	@cd servers/go-vanilla && go run .

start-go-fiber:
	@echo "🚀 Starting Go Fiber server..."
	@cd servers/go-fiber && go run .

start-bun-vanilla:
	@echo "🚀 Starting Bun vanilla server..."
	@cd servers/bun-vanilla && bun run server.ts

start-hono-bun:
	@echo "🚀 Starting Hono.js on Bun server..."
	@cd servers/hono-bun && bun run server.ts

# Stop all servers
stop-servers:
	@echo "🛑 Stopping all servers..."
	@pkill -f "go run" 2>/dev/null || true
	@pkill -f "bun run" 2>/dev/null || true
	@pkill -f ":8080" 2>/dev/null || true
	@echo "✅ All servers stopped!"

# Development helpers
dev-go-vanilla:
	@echo "🔄 Starting Go vanilla server in development mode..."
	@cd servers/go-vanilla && air || go run .

dev-go-fiber:
	@echo "🔄 Starting Go Fiber server in development mode..."
	@cd servers/go-fiber && air || go run .

dev-bun-vanilla:
	@echo "🔄 Starting Bun vanilla server in development mode..."
	@cd servers/bun-vanilla && bun --watch server.ts

dev-hono-bun:
	@echo "🔄 Starting Hono.js server in development mode..."
	@cd servers/hono-bun && bun --watch server.ts

# Quick benchmark of specific server
bench-go-vanilla:
	@echo "🚀 Quick benchmark: Go vanilla"
	@cd servers/go-vanilla && go run . > /dev/null 2>&1 & \
		sleep 3 && \
		wrk -t2 -c50 -d10s http://localhost:8080/ && \
		pkill -f "go run"

bench-go-fiber:
	@echo "🚀 Quick benchmark: Go Fiber"
	@cd servers/go-fiber && go run . > /dev/null 2>&1 & \
		sleep 3 && \
		wrk -t2 -c50 -d10s http://localhost:8080/ && \
		pkill -f "go run"

bench-bun-vanilla:
	@echo "🚀 Quick benchmark: Bun vanilla"
	@cd servers/bun-vanilla && bun run server.ts > /dev/null 2>&1 & \
		sleep 3 && \
		wrk -t2 -c50 -d10s http://localhost:8080/ && \
		pkill -f "bun"

bench-hono-bun:
	@echo "🚀 Quick benchmark: Hono.js"
	@cd servers/hono-bun && bun run server.ts > /dev/null 2>&1 & \
		sleep 3 && \
		wrk -t2 -c50 -d10s http://localhost:8080/ && \
		pkill -f "bun"

# Check versions
versions:
	@echo "📋 Installed versions:"
	@echo -n "Go: " && go version 2>/dev/null || echo "Not installed"
	@echo -n "Bun: " && bun --version 2>/dev/null || echo "Not installed"
	@echo -n "wrk: " && wrk --version 2>/dev/null || echo "Not installed"
	@echo -n "jq: " && jq --version 2>/dev/null || echo "Not installed"
	@echo -n "curl: " && curl --version | head -1 2>/dev/null || echo "Not installed"

# Docker support (bonus)
docker-build:
	@echo "🐳 Building Docker images..."
	@docker build -t jsvsgo-benchmark .

docker-run:
	@echo "🐳 Running benchmark in Docker..."
	@docker run --rm -v $(PWD)/results:/app/results jsvsgo-benchmark

# Performance comparison with different loads
bench-load-test:
	@echo "🔥 Running load tests with different configurations..."
	@mkdir -p results/load-tests
	@echo "Light load (25 connections)..."
	@./scripts/benchmark.sh --duration 30 --connections 25 --threads 2
	@mv results/benchmark_*.json results/load-tests/light-load.json
	@echo "Medium load (100 connections)..."
	@./scripts/benchmark.sh --duration 30 --connections 100 --threads 4
	@mv results/benchmark_*.json results/load-tests/medium-load.json
	@echo "Heavy load (300 connections)..."
	@./scripts/benchmark.sh --duration 30 --connections 300 --threads 8
	@mv results/benchmark_*.json results/load-tests/heavy-load.json
	@echo "✅ Load tests complete! Check results/load-tests/"

# Extensibility tools
add-server:
	@echo "🚀 Adding new server to benchmark suite..."
	@chmod +x tools/add-server.sh
	@./tools/add-server.sh

validate-server:
	@if [ -z "$(SERVER)" ]; then \
		echo "❌ Please specify SERVER name. Usage: make validate-server SERVER=my-framework"; \
		exit 1; \
	fi
	@echo "🔍 Validating server: $(SERVER)"
	@chmod +x tools/validate-server.sh
	@./tools/validate-server.sh $(SERVER)

list-servers:
	@echo "📋 Available servers:"
	@if [ -d servers ]; then \
		for dir in servers/*/; do \
			if [ -d "$$dir" ]; then \
				server=$$(basename "$$dir"); \
				if [ -f "$$dir/go.mod" ]; then \
					runtime="Go"; \
				elif [ -f "$$dir/package.json" ]; then \
					if grep -q '"bun"' "$$dir/package.json" 2>/dev/null; then \
						runtime="Bun"; \
					else \
						runtime="Node.js"; \
					fi; \
				else \
					runtime="Unknown"; \
				fi; \
				printf "  %-20s %s\n" "$$server" "$$runtime"; \
			fi; \
		done; \
	else \
		echo "  No servers directory found"; \
	fi

templates:
	@echo "📁 Available templates:"
	@if [ -d templates ]; then \
		for dir in templates/*/; do \
			if [ -d "$$dir" ]; then \
				template=$$(basename "$$dir"); \
				if [ -f "$$dir/main.go" ]; then \
					desc="Go framework template"; \
				elif [ -f "$$dir/server.ts" ]; then \
					desc="TypeScript/Bun framework template"; \
				elif [ -f "$$dir/package.json" ]; then \
					desc="Node.js framework template"; \
				else \
					desc="Custom template"; \
				fi; \
				printf "  %-20s %s\n" "$$template" "$$desc"; \
			fi; \
		done; \
	else \
		echo "  No templates directory found"; \
	fi
	@echo ""
	@echo "Usage: ./tools/add-server.sh (interactive)"

# Auto-discover and create targets for all servers
discover-servers:
	@echo "🔍 Auto-discovering servers..."
	@if command -v jq >/dev/null 2>&1 && [ -f benchmark.json ]; then \
		jq -r '.frameworks | keys[]' benchmark.json 2>/dev/null | while read framework; do \
			if [ -n "$$framework" ] && [ -d "servers/$$framework" ]; then \
				echo "Found: $$framework"; \
			fi; \
		done; \
	else \
		echo "jq not available or benchmark.json not found. Listing directories:"; \
		ls -1 servers/ 2>/dev/null | grep -v "^\." || echo "No servers found"; \
	fi

# Validate all servers
validate-all:
	@echo "🔍 Validating all servers..."
	@chmod +x tools/validate-server.sh
	@failed=0; \
	for dir in servers/*/; do \
		if [ -d "$$dir" ]; then \
			server=$$(basename "$$dir"); \
			echo ""; \
			echo "Validating $$server..."; \
			if ./tools/validate-server.sh "$$server" --quiet; then \
				echo "✅ $$server: PASSED"; \
			else \
				echo "❌ $$server: FAILED"; \
				failed=$$((failed + 1)); \
			fi; \
		fi; \
	done; \
	echo ""; \
	if [ $$failed -eq 0 ]; then \
		echo "🎉 All servers passed validation!"; \
	else \
		echo "⚠️  $$failed server(s) failed validation"; \
		exit 1; \
	fi

# Create new server from template
create-server:
	@if [ -z "$(NAME)" ] || [ -z "$(TEMPLATE)" ]; then \
		echo "❌ Usage: make create-server NAME=my-framework TEMPLATE=go-template"; \
		echo "Available templates:"; \
		make templates; \
		exit 1; \
	fi
	@echo "🚀 Creating server $(NAME) from template $(TEMPLATE)..."
	@if [ ! -d "templates/$(TEMPLATE)" ]; then \
		echo "❌ Template $(TEMPLATE) not found"; \
		make templates; \
		exit 1; \
	fi
	@if [ -d "servers/$(NAME)" ]; then \
		echo "❌ Server $(NAME) already exists"; \
		exit 1; \
	fi
	@mkdir -p "servers/$(NAME)"
	@cp -r "templates/$(TEMPLATE)/"* "servers/$(NAME)/"
	@echo "✅ Server $(NAME) created successfully!"
	@echo "Next steps:"
	@echo "1. cd servers/$(NAME)"
	@echo "2. Edit the template files to implement your framework"
	@echo "3. Run: make validate-server SERVER=$(NAME)"
	@echo "4. Run: make start-$(NAME) (after updating Makefile)"
