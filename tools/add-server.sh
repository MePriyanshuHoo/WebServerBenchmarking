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

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Function to print colored output
print_header() {
    echo -e "${BOLD}${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                     Add New Server to Benchmark                  ║"
    echo "║                        Interactive Generator                      ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

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

# Validation functions
validate_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-z0-9-]+$ ]]; then
        return 1
    fi
    return 0
}

validate_port() {
    local port="$1"
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1024 ] || [ "$port" -gt 65535 ]; then
        return 1
    fi
    return 0
}

# Check if server already exists
check_server_exists() {
    local server_name="$1"
    if [ -d "$PROJECT_ROOT/servers/$server_name" ]; then
        return 0
    fi
    return 1
}

# Interactive prompts
prompt_framework_details() {
    echo -e "${BOLD}Framework Information${NC}"
    echo "Please provide details about your framework:"
    echo

    # Framework name
    while true; do
        read -p "Framework name (lowercase, hyphens allowed, e.g., 'express-node', 'gin-go'): " FRAMEWORK_NAME
        if validate_name "$FRAMEWORK_NAME"; then
            if check_server_exists "$FRAMEWORK_NAME"; then
                print_error "Server '$FRAMEWORK_NAME' already exists!"
                continue
            fi
            break
        else
            print_error "Invalid name. Use lowercase letters, numbers, and hyphens only."
        fi
    done

    # Display name
    read -p "Display name (e.g., 'Express.js on Node.js', 'Gin Framework'): " FRAMEWORK_DISPLAY_NAME

    # Description
    read -p "Description: " FRAMEWORK_DESCRIPTION

    # Runtime selection
    echo
    echo "Select runtime environment:"
    echo "1) Go"
    echo "2) Bun (TypeScript)"
    echo "3) Node.js (JavaScript/TypeScript)"
    echo "4) Other (manual setup)"

    while true; do
        read -p "Choose runtime [1-4]: " runtime_choice
        case $runtime_choice in
            1)
                RUNTIME="go"
                TEMPLATE_DIR="go-template"
                START_COMMAND="go run ."
                SETUP_COMMANDS=("go mod tidy")
                break
                ;;
            2)
                RUNTIME="bun"
                TEMPLATE_DIR="bun-template"
                START_COMMAND="bun run server.ts"
                SETUP_COMMANDS=("bun install")
                break
                ;;
            3)
                RUNTIME="node"
                TEMPLATE_DIR="node-template"
                echo "Choose Node.js variant:"
                echo "a) JavaScript (server.js)"
                echo "b) TypeScript (server.ts)"
                read -p "Choose [a/b]: " node_variant
                case $node_variant in
                    a)
                        START_COMMAND="npm start"
                        SETUP_COMMANDS=("npm install")
                        ;;
                    b)
                        START_COMMAND="npm run start:ts"
                        SETUP_COMMANDS=("npm install")
                        ;;
                    *)
                        START_COMMAND="npm start"
                        SETUP_COMMANDS=("npm install")
                        ;;
                esac
                break
                ;;
            4)
                RUNTIME="other"
                TEMPLATE_DIR=""
                read -p "Start command: " START_COMMAND
                read -p "Setup commands (comma-separated): " setup_input
                IFS=',' read -ra SETUP_COMMANDS <<< "$setup_input"
                break
                ;;
            *)
                print_error "Invalid choice. Please select 1-4."
                ;;
        esac
    done

    # Author info
    echo
    read -p "Your name: " AUTHOR_NAME
    read -p "Your email: " AUTHOR_EMAIL

    # Framework-specific details
    if [ "$RUNTIME" != "other" ]; then
        read -p "Main package/dependency (e.g., 'github.com/gin-gonic/gin', 'express'): " MAIN_DEPENDENCY
    fi
}

# Create server directory and files
create_server_files() {
    local server_dir="$PROJECT_ROOT/servers/$FRAMEWORK_NAME"

    print_step "Creating server directory: $server_dir"
    mkdir -p "$server_dir"

    if [ -n "$TEMPLATE_DIR" ] && [ -d "$PROJECT_ROOT/templates/$TEMPLATE_DIR" ]; then
        print_status "Copying template from $TEMPLATE_DIR"
        cp -r "$PROJECT_ROOT/templates/$TEMPLATE_DIR"/* "$server_dir/"

        # Customize template files
        if [ -f "$server_dir/go.mod" ]; then
            sed -i.bak "s/your-framework-name/$FRAMEWORK_NAME/g" "$server_dir/go.mod"
            rm -f "$server_dir/go.mod.bak"
        fi

        if [ -f "$server_dir/package.json" ]; then
            sed -i.bak "s/your-framework-name/$FRAMEWORK_NAME/g" "$server_dir/package.json"
            sed -i.bak "s/Your Name <your.email@example.com>/$AUTHOR_NAME <$AUTHOR_EMAIL>/g" "$server_dir/package.json"
            sed -i.bak "s/TEMPLATE: Your framework description for benchmarking/$FRAMEWORK_DESCRIPTION/g" "$server_dir/package.json"
            rm -f "$server_dir/package.json.bak"
        fi

        # Update source files with framework name
        find "$server_dir" -name "*.go" -o -name "*.ts" -o -name "*.js" | while read -r file; do
            sed -i.bak "s/TEMPLATE: \\[Your Framework Name\\]/$FRAMEWORK_DISPLAY_NAME/g" "$file"
            rm -f "$file.bak"
        done
    else
        print_status "Creating basic directory structure for manual setup"
        cat > "$server_dir/README.md" << EOF
# $FRAMEWORK_DISPLAY_NAME

$FRAMEWORK_DESCRIPTION

## Setup

$( printf '%s\n' "${SETUP_COMMANDS[@]}" )

## Run

$START_COMMAND

## Required Endpoints

Implement these endpoints for benchmarking:

- \`GET /\` - Hello World response
- \`GET /health\` - Health check
- \`GET /user/:id\` - User by ID
- \`POST /users\` - Create user

See the benchmark requirements in ADD-NEW-SERVER.md for details.
EOF
    fi
}

# Update benchmark configuration
update_benchmark_config() {
    local config_file="$PROJECT_ROOT/benchmark.json"
    local temp_file=$(mktemp)

    print_step "Updating benchmark configuration"

    # Create the new framework entry
    local framework_entry=$(cat << EOF
    "$FRAMEWORK_NAME": {
      "name": "$FRAMEWORK_DISPLAY_NAME",
      "description": "$FRAMEWORK_DESCRIPTION",
      "language": "${RUNTIME^}",
      "runtime": "$RUNTIME",
      "directory": "./servers/$FRAMEWORK_NAME",
      "start_command": "$START_COMMAND",
      "build_command": null,
      "setup_commands": [$(printf '"%s",' "${SETUP_COMMANDS[@]}" | sed 's/,$//')],
      "dependencies": ["$RUNTIME"],
      "category": "$RUNTIME"
    }
EOF
)

    # Use jq to properly insert the new framework
    if command -v jq >/dev/null 2>&1; then
        local new_framework=$(cat << EOF
{
  "name": "$FRAMEWORK_DISPLAY_NAME",
  "description": "$FRAMEWORK_DESCRIPTION",
  "language": "${RUNTIME^}",
  "runtime": "$RUNTIME",
  "directory": "./servers/$FRAMEWORK_NAME",
  "start_command": "$START_COMMAND",
  "build_command": null,
  "setup_commands": [$(printf '"%s",' "${SETUP_COMMANDS[@]}" | sed 's/,$//')],
  "dependencies": ["$RUNTIME"],
  "category": "$RUNTIME"
}
EOF
)
        jq --argjson framework "$new_framework" \
           '.frameworks[$ARGS.positional[0]] = $framework' \
           --args "$FRAMEWORK_NAME" \
           "$config_file" > "$temp_file" && mv "$temp_file" "$config_file"
    else
        print_warning "jq not found. Please manually add the framework to benchmark.json"
        echo "Add this entry to the 'frameworks' section:"
        echo "$framework_entry"
    fi
}

# Update benchmark script
update_benchmark_script() {
    local script_file="$PROJECT_ROOT/scripts/benchmark.sh"
    local temp_file=$(mktemp)

    print_step "Adding framework to benchmark script"

    # Find the line with benchmark_server calls and add the new one
    if grep -q "benchmark_server.*go-vanilla" "$script_file"; then
        # Add after the last benchmark_server call
        local insert_line=$(grep -n "benchmark_server" "$script_file" | tail -1 | cut -d: -f1)
        {
            head -n "$insert_line" "$script_file"
            echo "    benchmark_server \"$FRAMEWORK_NAME\" \"$START_COMMAND\" \"./servers/$FRAMEWORK_NAME\""
            tail -n +$((insert_line + 1)) "$script_file"
        } > "$temp_file" && mv "$temp_file" "$script_file"
    else
        print_warning "Could not automatically update benchmark script."
        echo "Please manually add this line to scripts/benchmark.sh:"
        echo "    benchmark_server \"$FRAMEWORK_NAME\" \"$START_COMMAND\" \"./servers/$FRAMEWORK_NAME\""
    fi
}

# Update Makefile
update_makefile() {
    local makefile="$PROJECT_ROOT/Makefile"

    print_step "Adding Make targets for new framework"

    # Add start target
    echo "" >> "$makefile"
    echo "start-$FRAMEWORK_NAME:" >> "$makefile"
    echo "	@echo \"🚀 Starting $FRAMEWORK_DISPLAY_NAME server...\"" >> "$makefile"
    echo "	@cd servers/$FRAMEWORK_NAME && $START_COMMAND" >> "$makefile"

    # Add quick bench target
    echo "" >> "$makefile"
    echo "bench-$FRAMEWORK_NAME:" >> "$makefile"
    echo "	@echo \"🚀 Quick benchmark: $FRAMEWORK_DISPLAY_NAME\"" >> "$makefile"
    echo "	@cd servers/$FRAMEWORK_NAME && $START_COMMAND > /dev/null 2>&1 & \\" >> "$makefile"
    echo "		sleep 3 && \\" >> "$makefile"
    echo "		wrk -t2 -c50 -d10s http://localhost:8080/ && \\" >> "$makefile"
    echo "		pkill -f \"$START_COMMAND\"" >> "$makefile"

    # Add dev target if applicable
    if [[ "$START_COMMAND" == *"bun"* ]]; then
        echo "" >> "$makefile"
        echo "dev-$FRAMEWORK_NAME:" >> "$makefile"
        echo "	@echo \"🔄 Starting $FRAMEWORK_DISPLAY_NAME server in development mode...\"" >> "$makefile"
        echo "	@cd servers/$FRAMEWORK_NAME && bun --watch server.ts" >> "$makefile"
    elif [[ "$START_COMMAND" == *"npm"* ]]; then
        echo "" >> "$makefile"
        echo "dev-$FRAMEWORK_NAME:" >> "$makefile"
        echo "	@echo \"🔄 Starting $FRAMEWORK_DISPLAY_NAME server in development mode...\"" >> "$makefile"
        echo "	@cd servers/$FRAMEWORK_NAME && npm run dev" >> "$makefile"
    fi
}

# Create development instructions
create_instructions() {
    local instructions_file="$PROJECT_ROOT/servers/$FRAMEWORK_NAME/DEVELOPMENT.md"

    cat > "$instructions_file" << EOF
# $FRAMEWORK_DISPLAY_NAME Development Guide

## Quick Start

\`\`\`bash
# From project root
cd servers/$FRAMEWORK_NAME

# Setup dependencies
$(printf '%s\n' "${SETUP_COMMANDS[@]}")

# Run the server
$START_COMMAND

# Test endpoints
curl http://localhost:8080/health
curl http://localhost:8080/
curl http://localhost:8080/user/123
curl -X POST -H "Content-Type: application/json" -d '{"name":"Test User"}' http://localhost:8080/users
\`\`\`

## Make Commands

\`\`\`bash
# Start server
make start-$FRAMEWORK_NAME

# Quick benchmark
make bench-$FRAMEWORK_NAME

$(if [[ "$START_COMMAND" == *"bun"* ]] || [[ "$START_COMMAND" == *"npm"* ]]; then
echo "# Development mode (hot reload)
make dev-$FRAMEWORK_NAME"
fi)
\`\`\`

## Required Endpoints

Your implementation must provide these endpoints:

### 1. GET /
Hello World endpoint
\`\`\`json
{
  "message": "Hello, World!",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
\`\`\`

### 2. GET /health
Health check endpoint
\`\`\`json
{
  "message": "OK",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
\`\`\`

### 3. GET /user/:id
User by ID endpoint
\`\`\`json
{
  "message": "User retrieved successfully",
  "timestamp": "2024-01-01T12:00:00.000Z",
  "data": {
    "id": 123,
    "name": "User 123"
  }
}
\`\`\`

### 4. POST /users
Create user endpoint

Request:
\`\`\`json
{
  "name": "John Doe"
}
\`\`\`

Response:
\`\`\`json
{
  "message": "User created successfully",
  "timestamp": "2024-01-01T12:00:00.000Z",
  "data": {
    "id": 1234,
    "name": "John Doe"
  }
}
\`\`\`

## Next Steps

1. Implement the required endpoints in your framework
2. Test all endpoints manually
3. Run \`make health-check\` to verify your implementation
4. Run \`make bench-$FRAMEWORK_NAME\` for a quick benchmark
5. Submit a pull request with your implementation

## Framework-Specific Notes

$(if [ "$RUNTIME" = "go" ]; then
echo "- Use Go modules for dependency management
- Follow Go best practices and idioms
- Add proper error handling
- Use structured logging where appropriate"
elif [ "$RUNTIME" = "bun" ]; then
echo "- Use TypeScript for type safety
- Follow Bun best practices
- Use async/await for asynchronous operations
- Leverage Bun's built-in optimizations"
elif [ "$RUNTIME" = "node" ]; then
echo "- Use ES modules (import/export) or CommonJS as appropriate
- Add proper error handling middleware
- Use TypeScript if possible for better type safety
- Follow Node.js best practices"
else
echo "- Follow your runtime's best practices
- Ensure proper error handling
- Optimize for performance
- Document any special requirements"
fi)

## Performance Tips

- Minimize middleware overhead
- Use efficient JSON serialization
- Implement proper error handling without performance penalty
- Consider connection pooling if applicable
- Profile your implementation for bottlenecks

## Troubleshooting

Common issues and solutions:

1. **Port already in use**: Make sure no other server is running on port 8080
2. **Dependencies not found**: Run the setup commands again
3. **Endpoints not responding**: Check server logs and verify route definitions
4. **CORS issues**: Ensure proper CORS headers are set

## Resources

- [Project README](../../README.md)
- [Adding New Servers Guide](../../ADD-NEW-SERVER.md)
- [Benchmark Configuration](../../benchmark.json)
- [$FRAMEWORK_DISPLAY_NAME Documentation](# Add your framework's documentation URL here)
EOF
}

# Run tests
run_tests() {
    print_step "Testing new server implementation"

    local server_dir="$PROJECT_ROOT/servers/$FRAMEWORK_NAME"
    cd "$server_dir"

    # Run setup commands
    for cmd in "${SETUP_COMMANDS[@]}"; do
        print_status "Running: $cmd"
        if ! eval "$cmd"; then
            print_warning "Setup command failed: $cmd"
        fi
    done

    # Quick compilation/syntax check
    if [ "$RUNTIME" = "go" ]; then
        if ! go build .; then
            print_warning "Go build check failed. Please fix syntax errors."
        else
            print_success "Go build check passed"
            rm -f "$FRAMEWORK_NAME" # Remove binary
        fi
    elif [ "$RUNTIME" = "bun" ]; then
        if [ -f "server.ts" ]; then
            if ! bun build server.ts --outdir ./temp_build; then
                print_warning "Bun build check failed. Please fix syntax errors."
            else
                print_success "Bun build check passed"
                rm -rf temp_build
            fi
        fi
    elif [ "$RUNTIME" = "node" ]; then
        if [ -f "package.json" ]; then
            if ! npm install --silent; then
                print_warning "npm install failed. Please check dependencies."
            else
                print_success "npm install completed"
            fi
        fi
    fi

    cd "$PROJECT_ROOT"
}

# Show completion message
show_completion() {
    print_success "Server '$FRAMEWORK_NAME' has been added successfully!"
    echo
    echo -e "${BOLD}What was created:${NC}"
    echo "📁 Server directory: servers/$FRAMEWORK_NAME"
    echo "⚙️  Configuration updated in: benchmark.json"
    echo "🔧 Makefile targets added"
    echo "📝 Development guide: servers/$FRAMEWORK_NAME/DEVELOPMENT.md"
    echo
    echo -e "${BOLD}Next steps:${NC}"
    echo "1. Navigate to servers/$FRAMEWORK_NAME"
    echo "2. Follow the template comments to implement your framework"
    echo "3. Test your implementation:"
    echo "   make start-$FRAMEWORK_NAME"
    echo "4. Verify endpoints work:"
    echo "   curl http://localhost:8080/health"
    echo "5. Run a quick benchmark:"
    echo "   make bench-$FRAMEWORK_NAME"
    echo "6. Submit a pull request when ready!"
    echo
    echo -e "${BOLD}Useful commands:${NC}"
    echo "make start-$FRAMEWORK_NAME     # Start your server"
    echo "make bench-$FRAMEWORK_NAME     # Quick benchmark"
    if [[ "$START_COMMAND" == *"bun"* ]] || [[ "$START_COMMAND" == *"npm"* ]]; then
        echo "make dev-$FRAMEWORK_NAME       # Development mode (hot reload)"
    fi
    echo "make health-check             # Test all servers"
    echo
    echo -e "${CYAN}📚 Documentation:${NC}"
    echo "- Development guide: servers/$FRAMEWORK_NAME/DEVELOPMENT.md"
    echo "- Adding servers guide: ADD-NEW-SERVER.md"
    echo "- Project README: README.md"
    echo
    print_success "Happy coding! 🚀"
}

# Main execution
main() {
    print_header

    # Check if we're in the project root
    if [ ! -f "$PROJECT_ROOT/benchmark.json" ] || [ ! -d "$PROJECT_ROOT/servers" ]; then
        print_error "Please run this script from the project root directory"
        exit 1
    fi

    # Check for required directories
    if [ ! -d "$PROJECT_ROOT/templates" ]; then
        print_error "Templates directory not found. Please ensure project is properly set up."
        exit 1
    fi

    prompt_framework_details

    echo
    print_step "Creating server: $FRAMEWORK_NAME"
    print_status "Display name: $FRAMEWORK_DISPLAY_NAME"
    print_status "Runtime: $RUNTIME"
    print_status "Start command: $START_COMMAND"
    echo

    read -p "Continue with server creation? [Y/n]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_status "Server creation cancelled."
        exit 0
    fi

    create_server_files
    update_benchmark_config
    update_benchmark_script
    update_makefile
    create_instructions
    run_tests

    echo
    show_completion
}

# Run main function
main "$@"
