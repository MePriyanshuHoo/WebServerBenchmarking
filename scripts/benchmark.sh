#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PORT=8080
WARMUP_TIME=5
BENCHMARK_DURATION=30
CONNECTIONS=100
THREADS=4

# Results directory
RESULTS_DIR="./results"
mkdir -p "$RESULTS_DIR"

# Timestamp for this benchmark run
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE="$RESULTS_DIR/benchmark_$TIMESTAMP.json"

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

# Function to check if a port is in use
check_port() {
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to wait for server to be ready
wait_for_server() {
    local max_attempts=30
    local attempt=1

    print_status "Waiting for server to be ready on port $PORT..."

    while [ $attempt -le $max_attempts ]; do
        if curl -s "http://localhost:$PORT/health" >/dev/null 2>&1; then
            print_success "Server is ready!"
            return 0
        fi

        echo -n "."
        sleep 1
        attempt=$((attempt + 1))
    done

    print_error "Server failed to start within $max_attempts seconds"
    return 1
}

# Function to stop any process using the port
cleanup_port() {
    if check_port; then
        print_warning "Port $PORT is in use, killing existing processes..."
        local pids=$(lsof -Pi :$PORT -sTCP:LISTEN -t)
        if [ -n "$pids" ]; then
            kill -9 $pids 2>/dev/null || true
            sleep 2
        fi
    fi
}

# Function to run wrk benchmark
run_wrk() {
    local url=$1
    local description=$2

    print_status "Running benchmark: $description"
    print_status "URL: $url"
    print_status "Duration: ${BENCHMARK_DURATION}s, Connections: $CONNECTIONS, Threads: $THREADS"

    # Run wrk and capture output
    local wrk_output
    wrk_output=$(wrk -t$THREADS -c$CONNECTIONS -d${BENCHMARK_DURATION}s --latency "$url" 2>&1)

    # Parse wrk output
    local requests_per_sec=$(echo "$wrk_output" | grep "Requests/sec:" | awk '{print $2}')
    local avg_latency=$(echo "$wrk_output" | grep "Latency" | head -1 | awk '{print $2}')
    local transfer_per_sec=$(echo "$wrk_output" | grep "Transfer/sec:" | awk '{print $2}')

    # Get additional latency percentiles
    local latency_50=$(echo "$wrk_output" | grep "50%" | awk '{print $2}')
    local latency_75=$(echo "$wrk_output" | grep "75%" | awk '{print $2}')
    local latency_90=$(echo "$wrk_output" | grep "90%" | awk '{print $2}')
    local latency_99=$(echo "$wrk_output" | grep "99%" | awk '{print $2}')

    # Store results in temporary file
    # Escape the raw output properly for JSON
    local escaped_output=$(echo "$wrk_output" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

    cat << EOF >> "$TEMP_RESULTS"
{
  "endpoint": "$description",
  "url": "$url",
  "requests_per_sec": "$requests_per_sec",
  "avg_latency": "$avg_latency",
  "transfer_per_sec": "$transfer_per_sec",
  "latency_percentiles": {
    "50%": "$latency_50",
    "75%": "$latency_75",
    "90%": "$latency_90",
    "99%": "$latency_99"
  },
  "raw_output": "$escaped_output"
},
EOF

    print_success "Benchmark completed: $requests_per_sec req/sec"
}

# Function to benchmark a server
benchmark_server() {
    local server_name=$1
    local start_command=$2
    local server_dir=$3

    print_status "Starting benchmark for: $server_name"

    # Cleanup any existing processes
    cleanup_port

    # Create temporary results file for this server
    TEMP_RESULTS=$(mktemp)

    # Start server
    print_status "Starting $server_name server..."
    cd "$server_dir"

    # Start server in background
    if [[ "$start_command" == *"go"* ]]; then
        # For Go servers, build first
        if [ -f "go.mod" ]; then
            go mod tidy
            go build -o server .
            ./server &
        else
            go run . &
        fi
    else
        # For Node.js/Bun servers
        eval "$start_command" &
    fi

    local server_pid=$!
    cd - > /dev/null

    # Wait for server to be ready
    if wait_for_server; then
        # Warmup
        print_status "Warming up server for $WARMUP_TIME seconds..."
        for i in $(seq 1 $WARMUP_TIME); do
            curl -s "http://localhost:$PORT/" >/dev/null 2>&1 || true
            sleep 1
        done

        # Run benchmarks for different endpoints
        run_wrk "http://localhost:$PORT/" "Root endpoint"
        run_wrk "http://localhost:$PORT/health" "Health check"
        run_wrk "http://localhost:$PORT/user/123" "User endpoint"

        # POST benchmark with payload
        print_status "Running POST benchmark..."
        local post_output
        post_output=$(wrk -t$THREADS -c$CONNECTIONS -d${BENCHMARK_DURATION}s \
            -s <(echo 'wrk.method = "POST"; wrk.body = "{\"name\":\"Test User\"}"; wrk.headers["Content-Type"] = "application/json"') \
            "http://localhost:$PORT/users" 2>&1)

        local post_rps=$(echo "$post_output" | grep "Requests/sec:" | awk '{print $2}')
        local post_latency=$(echo "$post_output" | grep "Latency" | head -1 | awk '{print $2}')

        # Escape the POST output properly for JSON
        local escaped_post_output=$(echo "$post_output" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

        cat << EOF >> "$TEMP_RESULTS"
    {
      "endpoint": "POST users",
      "url": "http://localhost:$PORT/users",
      "requests_per_sec": "$post_rps",
      "avg_latency": "$post_latency",
      "transfer_per_sec": "",
      "latency_percentiles": {
        "50%": "",
        "75%": "",
        "90%": "",
        "99%": ""
      },
      "raw_output": "$escaped_post_output"
    },
EOF

        print_success "All benchmarks completed for $server_name"
    else
        print_error "Failed to start $server_name"
    fi

    # Stop server
    print_status "Stopping $server_name server..."
    kill $server_pid 2>/dev/null || true
    cleanup_port
    sleep 2

    # Process results - remove trailing comma and wrap in proper array format
    if [ -s "$TEMP_RESULTS" ]; then
        local results_content=$(cat "$TEMP_RESULTS" | sed '$ s/,$//')
        echo "$server_name|$results_content" >> "$RESULTS_FILE.tmp"
    else
        print_warning "No results collected for $server_name"
    fi

    rm -f "$TEMP_RESULTS"
}

# Main execution
main() {
    print_status "Starting comprehensive benchmark suite"
    print_status "Results will be saved to: $RESULTS_FILE"

    # Initialize results file
    echo "{" > "$RESULTS_FILE"
    echo "  \"timestamp\": \"$(date -Iseconds)\"," >> "$RESULTS_FILE"
    echo "  \"configuration\": {" >> "$RESULTS_FILE"
    echo "    \"duration\": $BENCHMARK_DURATION," >> "$RESULTS_FILE"
    echo "    \"connections\": $CONNECTIONS," >> "$RESULTS_FILE"
    echo "    \"threads\": $THREADS," >> "$RESULTS_FILE"
    echo "    \"warmup_time\": $WARMUP_TIME" >> "$RESULTS_FILE"
    echo "  }," >> "$RESULTS_FILE"
    echo "  \"results\": {" >> "$RESULTS_FILE"

    # Initialize temporary results file
    touch "$RESULTS_FILE.tmp"

    # Auto-discover servers from configuration
    discover_and_benchmark_servers

    # Process final results with proper JSON formatting
    if [ -s "$RESULTS_FILE.tmp" ]; then
        local first=true
        while IFS='|' read -r server_name server_results; do
            if [ -n "$server_name" ] && [ -n "$server_results" ]; then
                if [ "$first" = true ]; then
                    first=false
                else
                    echo "," >> "$RESULTS_FILE"
                fi

                echo "    \"$server_name\": [" >> "$RESULTS_FILE"
                echo "$server_results" | sed 's/^/      /' >> "$RESULTS_FILE"
                echo -n "    ]" >> "$RESULTS_FILE"
            fi
        done < "$RESULTS_FILE.tmp"

        echo "" >> "$RESULTS_FILE"
        echo "  }" >> "$RESULTS_FILE"
        echo "}" >> "$RESULTS_FILE"
    else
        # No results found, create empty results structure
        echo "  }" >> "$RESULTS_FILE"
        echo "}" >> "$RESULTS_FILE"
        print_warning "No benchmark results were collected"
    fi

    # Cleanup
    rm -f "$RESULTS_FILE.tmp"

    print_success "Benchmark suite completed!"
    print_status "Results saved to: $RESULTS_FILE"

    # Show summary and validate JSON
    print_status "Benchmark Summary:"
    if command -v jq >/dev/null 2>&1; then
        if jq empty "$RESULTS_FILE" 2>/dev/null; then
            print_success "JSON file is valid"
            jq -r '.results | to_entries[] | "\(.key): \(.value[0].requests_per_sec) req/sec"' "$RESULTS_FILE" 2>/dev/null || {
                print_warning "Could not parse benchmark results for summary"
                echo "Results saved to: $RESULTS_FILE"
            }
        else
            print_error "Generated JSON file is invalid!"
            print_status "Attempting to show JSON validation error:"
            jq empty "$RESULTS_FILE" 2>&1 || true
            echo "Results saved to: $RESULTS_FILE"
        fi
    else
        print_warning "Install jq for formatted summary and JSON validation. Results saved to: $RESULTS_FILE"
    fi
}

# Auto-discover and benchmark servers from configuration
discover_and_benchmark_servers() {
    local config_file="./benchmark.json"

    if [ ! -f "$config_file" ]; then
        print_error "Configuration file not found: $config_file"
        print_status "Falling back to default servers..."
        # Fallback to hardcoded servers
        benchmark_server "go-vanilla" "go run ." "./servers/go-vanilla"
        benchmark_server "go-fiber" "go run ." "./servers/go-fiber"
        benchmark_server "bun-vanilla" "bun run server.ts" "./servers/bun-vanilla"
        benchmark_server "hono-bun" "bun run server.ts" "./servers/hono-bun"
        return
    fi

    print_status "Auto-discovering servers from configuration..."

    if command -v jq >/dev/null 2>&1; then
        # Use jq for JSON parsing
        local frameworks=$(jq -r '.frameworks | keys[]' "$config_file" 2>/dev/null)

        if [ -z "$frameworks" ]; then
            print_warning "No frameworks found in configuration. Using defaults."
            benchmark_server "go-vanilla" "go run ." "./servers/go-vanilla"
            benchmark_server "go-fiber" "go run ." "./servers/go-fiber"
            benchmark_server "bun-vanilla" "bun run server.ts" "./servers/bun-vanilla"
            benchmark_server "hono-bun" "bun run server.ts" "./servers/hono-bun"
            return
        fi

        while IFS= read -r framework; do
            if [ -n "$framework" ]; then
                local start_cmd=$(jq -r ".frameworks[\"$framework\"].start_command" "$config_file" 2>/dev/null)
                local directory=$(jq -r ".frameworks[\"$framework\"].directory" "$config_file" 2>/dev/null)

                # Validate the framework configuration
                if [ "$start_cmd" != "null" ] && [ "$directory" != "null" ] && [ -d "$directory" ]; then
                    print_status "Found framework: $framework"
                    benchmark_server "$framework" "$start_cmd" "$directory"
                else
                    print_warning "Skipping $framework: invalid configuration or missing directory"
                fi
            fi
        done <<< "$frameworks"
    else
        # Fallback: scan servers directory
        print_warning "jq not available. Scanning servers directory..."
        for server_dir in ./servers/*/; do
            if [ -d "$server_dir" ]; then
                local server_name=$(basename "$server_dir")

                # Try to determine start command based on files present
                local start_cmd=""
                if [ -f "$server_dir/go.mod" ]; then
                    start_cmd="go run ."
                elif [ -f "$server_dir/package.json" ]; then
                    if command -v bun >/dev/null 2>&1 && [ -f "$server_dir/server.ts" ]; then
                        start_cmd="bun run server.ts"
                    else
                        start_cmd="npm start"
                    fi
                fi

                if [ -n "$start_cmd" ]; then
                    print_status "Auto-detected framework: $server_name"
                    benchmark_server "$server_name" "$start_cmd" "$server_dir"
                else
                    print_warning "Could not determine start command for: $server_name"
                fi
            fi
        done
    fi
}

# Check dependencies
check_dependencies() {
    local missing_deps=()

    # Note: jq is optional for enhanced output formatting

    if ! command -v wrk >/dev/null 2>&1; then
        missing_deps+=("wrk")
    fi

    if ! command -v go >/dev/null 2>&1; then
        missing_deps+=("go")
    fi

    if ! command -v bun >/dev/null 2>&1; then
        missing_deps+=("bun")
    fi

    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi

    if ! command -v lsof >/dev/null 2>&1; then
        missing_deps+=("lsof")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_status "Please install the missing dependencies and try again."
        exit 1
    fi
}

# Check if running in CI environment
if [ "${CI:-}" = "true" ] || [ "${GITHUB_ACTIONS:-}" = "true" ] || [ "${CONTINUOUS_INTEGRATION:-}" = "true" ]; then
    print_status "Running in CI environment"
    # Use CI-optimized settings for faster runs
    if [ -z "${BENCHMARK_DURATION_SET:-}" ]; then
        BENCHMARK_DURATION=15
    fi
    if [ -z "${CONNECTIONS_SET:-}" ]; then
        CONNECTIONS=50
    fi
    if [ -z "${THREADS_SET:-}" ]; then
        THREADS=2
    fi
    WARMUP_TIME=2
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--duration)
            BENCHMARK_DURATION="$2"
            BENCHMARK_DURATION_SET=true
            shift 2
            ;;
        -c|--connections)
            CONNECTIONS="$2"
            CONNECTIONS_SET=true
            shift 2
            ;;
        -t|--threads)
            THREADS="$2"
            THREADS_SET=true
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -d, --duration SECONDS    Benchmark duration (default: $BENCHMARK_DURATION)"
            echo "  -c, --connections NUM     Number of connections (default: $CONNECTIONS)"
            echo "  -t, --threads NUM         Number of threads (default: $THREADS)"
            echo "  -h, --help               Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run dependency check
check_dependencies

# Run main function
main
