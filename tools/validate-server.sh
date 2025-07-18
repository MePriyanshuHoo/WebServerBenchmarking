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

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VALIDATION_PORT=8080
TIMEOUT=30
MAX_STARTUP_WAIT=15

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to print colored output
print_header() {
    echo -e "${BOLD}${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                      Server Validation Tool                      ║"
    echo "║                    Testing Framework Implementation              ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED_TESTS++))
}

print_failure() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED_TESTS++))
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_step() {
    echo -e "${BOLD}${CYAN}[STEP]${NC} $1"
}

# Increment test counter
test_start() {
    ((TOTAL_TESTS++))
}

# Usage information
usage() {
    echo "Usage: $0 <server-name> [options]"
    echo
    echo "Options:"
    echo "  -p, --port PORT      Port to test on (default: 8080)"
    echo "  -t, --timeout SECS   Request timeout in seconds (default: 30)"
    echo "  -q, --quiet          Reduce output verbosity"
    echo "  -h, --help          Show this help message"
    echo
    echo "Examples:"
    echo "  $0 express-node              # Validate express-node server"
    echo "  $0 gin-go --port 3000        # Test on port 3000"
    echo "  $0 my-framework --quiet      # Minimal output"
}

# Cleanup function
cleanup() {
    if [ -n "$SERVER_PID" ]; then
        print_status "Cleaning up server process..."
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi

    # Kill any remaining processes on the port
    local pids=$(lsof -ti :$VALIDATION_PORT 2>/dev/null || true)
    if [ -n "$pids" ]; then
        print_status "Killing remaining processes on port $VALIDATION_PORT..."
        kill -9 $pids 2>/dev/null || true
    fi
}

# Set up cleanup trap
trap cleanup EXIT

# Check if server directory exists
validate_directory_structure() {
    print_step "Validating directory structure"

    test_start
    if [ ! -d "$SERVER_DIR" ]; then
        print_failure "Server directory does not exist: $SERVER_DIR"
        return 1
    fi
    print_success "Server directory exists"

    # Check for common configuration files
    local has_config=false

    test_start
    if [ -f "$SERVER_DIR/go.mod" ]; then
        print_success "Found Go module configuration (go.mod)"
        has_config=true
    elif [ -f "$SERVER_DIR/package.json" ]; then
        print_success "Found Node.js/Bun configuration (package.json)"
        has_config=true
    elif [ -f "$SERVER_DIR/Cargo.toml" ]; then
        print_success "Found Rust configuration (Cargo.toml)"
        has_config=true
    elif [ -f "$SERVER_DIR/requirements.txt" ] || [ -f "$SERVER_DIR/pyproject.toml" ]; then
        print_success "Found Python configuration"
        has_config=true
    else
        print_warning "No standard configuration file found (go.mod, package.json, etc.)"
    fi

    test_start
    if [ -f "$SERVER_DIR/README.md" ] || [ -f "$SERVER_DIR/DEVELOPMENT.md" ]; then
        print_success "Documentation found"
    else
        print_warning "No README.md or DEVELOPMENT.md found"
    fi

    return 0
}

# Load server configuration from benchmark.json
load_server_config() {
    print_step "Loading server configuration"

    local config_file="$PROJECT_ROOT/benchmark.json"

    test_start
    if [ ! -f "$config_file" ]; then
        print_failure "Benchmark configuration not found: $config_file"
        return 1
    fi
    print_success "Configuration file found"

    if command -v jq >/dev/null 2>&1; then
        test_start
        START_COMMAND=$(jq -r ".frameworks[\"$SERVER_NAME\"].start_command" "$config_file" 2>/dev/null)
        if [ "$START_COMMAND" = "null" ] || [ -z "$START_COMMAND" ]; then
            print_failure "No start command found in configuration for: $SERVER_NAME"
            return 1
        fi
        print_success "Start command found: $START_COMMAND"

        test_start
        SETUP_COMMANDS=$(jq -r ".frameworks[\"$SERVER_NAME\"].setup_commands[]" "$config_file" 2>/dev/null | tr '\n' ';')
        if [ -n "$SETUP_COMMANDS" ]; then
            print_success "Setup commands found"
        else
            print_warning "No setup commands specified"
        fi
    else
        print_warning "jq not available. Skipping configuration validation."
        # Try to guess start command
        if [ -f "$SERVER_DIR/go.mod" ]; then
            START_COMMAND="go run ."
        elif [ -f "$SERVER_DIR/package.json" ]; then
            if [ -f "$SERVER_DIR/server.ts" ]; then
                START_COMMAND="bun run server.ts"
            else
                START_COMMAND="npm start"
            fi
        else
            print_failure "Cannot determine start command automatically"
            return 1
        fi
        print_warning "Guessed start command: $START_COMMAND"
    fi

    return 0
}

# Run setup commands
run_setup() {
    print_step "Running setup commands"

    cd "$SERVER_DIR"

    if [ -n "$SETUP_COMMANDS" ]; then
        IFS=';' read -ra SETUP_ARRAY <<< "$SETUP_COMMANDS"
        for cmd in "${SETUP_ARRAY[@]}"; do
            if [ -n "$cmd" ]; then
                test_start
                print_status "Running: $cmd"
                if eval "$cmd" >/dev/null 2>&1; then
                    print_success "Setup command completed: $cmd"
                else
                    print_failure "Setup command failed: $cmd"
                    cd "$PROJECT_ROOT"
                    return 1
                fi
            fi
        done
    else
        # Try common setup commands based on project type
        if [ -f "go.mod" ]; then
            test_start
            print_status "Running: go mod tidy"
            if go mod tidy >/dev/null 2>&1; then
                print_success "Go dependencies updated"
            else
                print_failure "go mod tidy failed"
                cd "$PROJECT_ROOT"
                return 1
            fi
        elif [ -f "package.json" ]; then
            test_start
            if command -v bun >/dev/null 2>&1; then
                print_status "Running: bun install"
                if bun install >/dev/null 2>&1; then
                    print_success "Bun dependencies installed"
                else
                    print_failure "bun install failed"
                    cd "$PROJECT_ROOT"
                    return 1
                fi
            else
                print_status "Running: npm install"
                if npm install --silent >/dev/null 2>&1; then
                    print_success "npm dependencies installed"
                else
                    print_failure "npm install failed"
                    cd "$PROJECT_ROOT"
                    return 1
                fi
            fi
        fi
    fi

    cd "$PROJECT_ROOT"
    return 0
}

# Start the server
start_server() {
    print_step "Starting server"

    # Check if port is already in use
    test_start
    if lsof -Pi :$VALIDATION_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_failure "Port $VALIDATION_PORT is already in use"
        return 1
    fi
    print_success "Port $VALIDATION_PORT is available"

    cd "$SERVER_DIR"

    test_start
    print_status "Starting server with: $START_COMMAND"

    # Start server in background
    eval "$START_COMMAND" >/dev/null 2>&1 &
    SERVER_PID=$!

    # Wait for server to start
    local wait_time=0
    while [ $wait_time -lt $MAX_STARTUP_WAIT ]; do
        if lsof -Pi :$VALIDATION_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
            print_success "Server started successfully (PID: $SERVER_PID)"
            cd "$PROJECT_ROOT"

            # Additional wait for server to be fully ready
            sleep 2
            return 0
        fi
        sleep 1
        ((wait_time++))
        echo -n "."
    done

    echo ""
    print_failure "Server failed to start within $MAX_STARTUP_WAIT seconds"
    cd "$PROJECT_ROOT"
    return 1
}

# Test HTTP endpoint
test_endpoint() {
    local method="$1"
    local path="$2"
    local expected_status="$3"
    local expected_fields="$4"
    local post_data="$5"
    local description="$6"

    test_start
    print_status "Testing $method $path - $description"

    local curl_args=("-s" "-w" "%{http_code}" "--max-time" "$TIMEOUT")

    if [ "$method" = "POST" ]; then
        curl_args+=("-X" "POST" "-H" "Content-Type: application/json")
        if [ -n "$post_data" ]; then
            curl_args+=("-d" "$post_data")
        fi
    fi

    local response
    response=$(curl "${curl_args[@]}" "http://localhost:$VALIDATION_PORT$path" 2>/dev/null)

    if [ $? -ne 0 ]; then
        print_failure "Request failed - server not responding"
        return 1
    fi

    # Extract status code (last 3 characters)
    local status_code="${response: -3}"
    local body="${response%???}"

    # Check status code
    if [ "$status_code" != "$expected_status" ]; then
        print_failure "Wrong status code - expected $expected_status, got $status_code"
        return 1
    fi

    # Check if response is valid JSON
    if ! echo "$body" | jq empty 2>/dev/null; then
        print_failure "Response is not valid JSON"
        echo "Response body: $body"
        return 1
    fi

    # Check required fields
    for field in $expected_fields; do
        if ! echo "$body" | jq -e ".$field" >/dev/null 2>&1; then
            print_failure "Missing required field: $field"
            echo "Response body: $body"
            return 1
        fi
    done

    print_success "$description - Status: $status_code, Fields: $expected_fields"
    return 0
}

# Test all required endpoints
test_endpoints() {
    print_step "Testing required endpoints"

    # Test GET /
    test_endpoint "GET" "/" "200" "message timestamp" "" "Hello World endpoint"

    # Test GET /health
    test_endpoint "GET" "/health" "200" "message timestamp" "" "Health check endpoint"

    # Test GET /user/:id
    test_endpoint "GET" "/user/123" "200" "message timestamp data" "" "User retrieval endpoint"

    # Test POST /users
    test_endpoint "POST" "/users" "201" "message timestamp data" '{"name":"Test User"}' "User creation endpoint"

    # Test error handling
    test_start
    print_status "Testing error handling - invalid user ID"
    local response
    response=$(curl -s -w "%{http_code}" --max-time "$TIMEOUT" "http://localhost:$VALIDATION_PORT/user/invalid" 2>/dev/null)
    local status_code="${response: -3}"

    if [ "$status_code" = "400" ] || [ "$status_code" = "404" ]; then
        print_success "Error handling works - returns $status_code for invalid input"
    else
        print_warning "Error handling may need improvement - got $status_code for invalid input"
    fi

    # Test 404 handling
    test_start
    print_status "Testing 404 handling"
    response=$(curl -s -w "%{http_code}" --max-time "$TIMEOUT" "http://localhost:$VALIDATION_PORT/nonexistent" 2>/dev/null)
    status_code="${response: -3}"

    if [ "$status_code" = "404" ]; then
        print_success "404 handling works correctly"
    else
        print_warning "404 handling may need improvement - got $status_code for nonexistent endpoint"
    fi
}

# Test response format consistency
test_response_format() {
    print_step "Testing response format consistency"

    local endpoints=("/" "/health" "/user/123")

    for endpoint in "${endpoints[@]}"; do
        test_start
        print_status "Checking response format for $endpoint"

        local response
        response=$(curl -s --max-time "$TIMEOUT" "http://localhost:$VALIDATION_PORT$endpoint" 2>/dev/null)

        if [ $? -ne 0 ]; then
            print_failure "Failed to get response from $endpoint"
            continue
        fi

        # Check required fields exist and have correct types
        local message_check
        message_check=$(echo "$response" | jq -r '.message // empty' 2>/dev/null)
        if [ -n "$message_check" ]; then
            print_success "$endpoint has valid message field"
        else
            print_failure "$endpoint missing or invalid message field"
            continue
        fi

        local timestamp_check
        timestamp_check=$(echo "$response" | jq -r '.timestamp // empty' 2>/dev/null)
        if [ -n "$timestamp_check" ]; then
            print_success "$endpoint has valid timestamp field"
        else
            print_failure "$endpoint missing or invalid timestamp field"
        fi
    done
}

# Performance quick test
test_basic_performance() {
    print_step "Basic performance test"

    if ! command -v wrk >/dev/null 2>&1; then
        print_warning "wrk not available - skipping performance test"
        return 0
    fi

    test_start
    print_status "Running 5-second performance test"

    local wrk_output
    wrk_output=$(wrk -t1 -c10 -d5s --timeout 10s "http://localhost:$VALIDATION_PORT/" 2>&1)

    if [ $? -eq 0 ]; then
        local rps
        rps=$(echo "$wrk_output" | grep "Requests/sec:" | awk '{print $2}')
        if [ -n "$rps" ]; then
            print_success "Performance test completed - $rps requests/sec"
        else
            print_success "Performance test completed"
        fi
    else
        print_failure "Performance test failed"
        echo "$wrk_output"
    fi
}

# Generate validation report
generate_report() {
    echo
    print_step "Validation Report"
    echo -e "${BOLD}Server: $SERVER_NAME${NC}"
    echo -e "${BOLD}Total Tests: $TOTAL_TESTS${NC}"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"

    local success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "${BOLD}Success Rate: $success_rate%${NC}"

    echo
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}${BOLD}✅ VALIDATION PASSED${NC}"
        echo -e "${GREEN}Your server implementation is ready for benchmarking!${NC}"
        echo
        echo "Next steps:"
        echo "1. Run 'make bench-$SERVER_NAME' for a quick benchmark"
        echo "2. Run 'make health-check' to test with all other servers"
        echo "3. Submit a pull request when ready"
    elif [ $success_rate -ge 80 ]; then
        echo -e "${YELLOW}${BOLD}⚠️  VALIDATION MOSTLY PASSED${NC}"
        echo -e "${YELLOW}Your server works but has some issues that should be fixed.${NC}"
        echo
        echo "Issues to address:"
        echo "- Review failed tests above"
        echo "- Fix any missing endpoints or incorrect responses"
        echo "- Test manually with curl to verify fixes"
    else
        echo -e "${RED}${BOLD}❌ VALIDATION FAILED${NC}"
        echo -e "${RED}Your server implementation needs significant fixes.${NC}"
        echo
        echo "Required fixes:"
        echo "- Implement all required endpoints (/, /health, /user/:id, /users)"
        echo "- Ensure correct response format with message and timestamp fields"
        echo "- Fix server startup issues"
        echo "- Test with the validation script again"
    fi

    echo
    echo "For help, see:"
    echo "- ADD-NEW-SERVER.md - Complete implementation guide"
    echo "- servers/*/DEVELOPMENT.md - Framework-specific examples"
    echo "- templates/ - Starting templates"
}

# Main execution
main() {
    print_header

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--port)
                VALIDATION_PORT="$2"
                shift 2
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                echo "Unknown option $1"
                usage
                exit 1
                ;;
            *)
                if [ -z "$SERVER_NAME" ]; then
                    SERVER_NAME="$1"
                else
                    echo "Multiple server names specified"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    if [ -z "$SERVER_NAME" ]; then
        echo "Error: Server name is required"
        echo
        usage
        exit 1
    fi

    SERVER_DIR="$PROJECT_ROOT/servers/$SERVER_NAME"

    print_status "Validating server: $SERVER_NAME"
    print_status "Server directory: $SERVER_DIR"
    print_status "Test port: $VALIDATION_PORT"
    echo

    # Run validation steps
    if ! validate_directory_structure; then
        generate_report
        exit 1
    fi

    if ! load_server_config; then
        generate_report
        exit 1
    fi

    if ! run_setup; then
        generate_report
        exit 1
    fi

    if ! start_server; then
        generate_report
        exit 1
    fi

    # Give server a moment to fully initialize
    sleep 2

    test_endpoints
    test_response_format
    test_basic_performance

    generate_report

    # Exit with appropriate code
    if [ $FAILED_TESTS -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
