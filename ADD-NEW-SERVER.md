# Adding New Servers to the Benchmark Suite

A comprehensive guide for contributing new web framework implementations to the benchmark suite.

## 📋 Table of Contents

- [Overview](#-overview)
- [Quick Start (Automated)](#-quick-start-automated)
- [Manual Setup](#-manual-setup)
- [Required Endpoints](#-required-endpoints)
- [Implementation Guidelines](#-implementation-guidelines)
- [Testing Your Implementation](#-testing-your-implementation)
- [Submission Process](#-submission-process)
- [Examples by Runtime](#-examples-by-runtime)
- [Troubleshooting](#-troubleshooting)
- [Best Practices](#-best-practices)

## 🎯 Overview

We welcome contributions of new web framework implementations! This guide will help you add your favorite framework to our benchmark suite. The process is designed to be simple, consistent, and automated.

### What We're Looking For

- **Web frameworks** across different languages and runtimes
- **Production-ready** implementations
- **Consistent APIs** that match our endpoint requirements
- **Well-documented** code with clear setup instructions
- **Performance-optimized** implementations that showcase the framework's capabilities

### Supported Runtimes

- **Go**: Any Go web framework (Gin, Echo, Chi, Gorilla Mux, etc.)
- **Node.js**: Express, Fastify, Koa, Hapi, Restify, Polka, etc.
- **Bun**: Hono, Elysia, or pure Bun implementations
- **Deno**: Oak, Aleph, Fresh, etc.
- **Other**: Python (FastAPI, Flask, Django), Rust (Actix, Warp), Java (Spring Boot), etc.

## 🚀 Quick Start (Automated)

The fastest way to add a new server is using our interactive generator:

### Step 1: Run the Generator

```bash
# From the project root
./tools/add-server.sh
```

### Step 2: Follow the Interactive Prompts

The script will ask you for:
- Framework name (e.g., `express-node`, `gin-go`)
- Display name (e.g., `Express.js on Node.js`)
- Description
- Runtime environment (Go, Bun, Node.js, or Other)
- Author information
- Main dependencies

### Step 3: Implement Your Framework

Navigate to the created directory and follow the template comments:

```bash
cd servers/your-framework-name
# Edit the template files to implement your framework
# See DEVELOPMENT.md in your server directory for detailed instructions
```

### Step 4: Test and Submit

```bash
# Test your implementation
make start-your-framework-name

# Run a quick benchmark
make bench-your-framework-name

# Submit a pull request when ready!
```

## 🛠️ Manual Setup

For advanced users or custom setups, you can manually create your server implementation:

### Directory Structure

Create your server directory:

```bash
mkdir servers/your-framework-name
cd servers/your-framework-name
```

### Required Files

#### For Go Frameworks

```bash
# go.mod
module your-framework-name

go 1.21

require (
    // your dependencies
)

# main.go
// Implement required endpoints (see template)
```

#### For Node.js/TypeScript Frameworks

```bash
# package.json
{
  "name": "your-framework-name",
  "main": "server.js", // or server.ts
  "scripts": {
    "start": "node server.js" // or npm run start:ts
  },
  "dependencies": {
    // your dependencies
  }
}

# server.js or server.ts
// Implement required endpoints (see template)
```

#### For Other Runtimes

Follow your runtime's conventions and ensure:
- Server listens on port 8080
- Implements all required endpoints
- Includes setup/build instructions

## 📍 Required Endpoints

Every server implementation must provide these exact endpoints:

### 1. GET /
**Hello World endpoint**

Request:
```http
GET / HTTP/1.1
```

Response:
```json
{
  "message": "Hello, World!",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

### 2. GET /health
**Health check endpoint**

Request:
```http
GET /health HTTP/1.1
```

Response:
```json
{
  "message": "OK",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

### 3. GET /user/:id
**Parameterized route**

Request:
```http
GET /user/123 HTTP/1.1
```

Response:
```json
{
  "message": "User retrieved successfully",
  "timestamp": "2024-01-01T12:00:00.000Z",
  "data": {
    "id": 123,
    "name": "User 123"
  }
}
```

### 4. POST /users
**JSON endpoint**

Request:
```http
POST /users HTTP/1.1
Content-Type: application/json

{
  "name": "John Doe"
}
```

Response:
```json
{
  "message": "User created successfully",
  "timestamp": "2024-01-01T12:00:00.000Z",
  "data": {
    "id": 1234,
    "name": "John Doe"
  }
}
```

### Response Format Requirements

All endpoints must return:
- `message`: string - Descriptive message
- `timestamp`: ISO 8601 timestamp
- `data`: object (optional) - Response payload for data endpoints

## 🔧 Implementation Guidelines

### Server Configuration

- **Port**: Must listen on port 8080
- **Timeouts**: Set reasonable read/write timeouts (10s recommended)
- **CORS**: Enable CORS headers for browser compatibility
- **JSON**: All responses must be valid JSON
- **Errors**: Return appropriate HTTP status codes

### Code Quality

- **Documentation**: Include clear comments and README
- **Error Handling**: Proper error responses and logging
- **Dependencies**: Minimal, production-ready dependencies
- **Security**: Basic security headers and input validation
- **Performance**: Optimize for the benchmark scenario

### Framework-Specific Guidelines

#### Go Frameworks
```go
// Use structured types
type Response struct {
    Message   string    `json:"message"`
    Timestamp time.Time `json:"timestamp"`
    Data      any       `json:"data,omitempty"`
}

// Configure timeouts
server := &http.Server{
    Addr:         ":8080",
    ReadTimeout:  10 * time.Second,
    WriteTimeout: 10 * time.Second,
}
```

#### JavaScript/TypeScript Frameworks
```typescript
// Use consistent interfaces
interface Response {
  message: string;
  timestamp: Date;
  data?: any;
}

// Enable CORS
app.use(cors());

// Parse JSON bodies
app.use(express.json()); // Express example
```

## 🧪 Testing Your Implementation

### Manual Testing

Test each endpoint manually:

```bash
# Start your server
make start-your-framework-name

# Test endpoints
curl http://localhost:8080/health
curl http://localhost:8080/
curl http://localhost:8080/user/123
curl -X POST -H "Content-Type: application/json" \
     -d '{"name":"Test User"}' \
     http://localhost:8080/users
```

### Automated Testing

Run the health check:

```bash
make health-check
```

Run a quick benchmark:

```bash
make bench-your-framework-name
```

### Validation Checklist

- [ ] Server starts on port 8080
- [ ] All 4 endpoints respond correctly
- [ ] JSON responses match required format
- [ ] Proper HTTP status codes (200, 201, 400, 404, 500)
- [ ] CORS headers enabled
- [ ] Error handling works
- [ ] No console errors during normal operation

## 📥 Submission Process

### 1. Fork and Clone

```bash
git clone https://github.com/YOUR_USERNAME/WebServerBenchmarking.git
cd WebServerBenchmarking
```

### 2. Create Your Implementation

Follow the automated or manual setup process above.

### 3. Update Configuration

If you didn't use the automated tool, manually update:

- `benchmark.json` - Add your framework configuration
- `scripts/benchmark.sh` - Add benchmark call
- `Makefile` - Add convenience targets

### 4. Test Thoroughly

```bash
# Full health check
make health-check

# Your specific implementation
make start-your-framework-name
make bench-your-framework-name

# Full benchmark (optional but recommended)
make bench-ci
```

### 5. Create Pull Request

```bash
git add servers/your-framework-name
git add benchmark.json Makefile scripts/benchmark.sh  # if modified
git commit -m "Add [Framework Name] implementation

- Implements all required endpoints
- Includes proper error handling
- Tested and benchmarked successfully"

git push origin main
```

### Pull Request Template

Include in your PR description:

```markdown
## New Framework: [Framework Name]

### Overview
- **Framework**: [Name and version]
- **Runtime**: [Go/Node.js/Bun/Other]
- **Language**: [Go/JavaScript/TypeScript/Other]

### Implementation Details
- [Brief description of your implementation]
- [Any special features or optimizations]
- [Dependencies used]

### Testing
- [ ] All endpoints tested manually
- [ ] Health check passes
- [ ] Quick benchmark runs successfully
- [ ] No errors in console

### Performance Notes
- [Any performance considerations]
- [Expected benchmark results if known]

### Additional Notes
- [Any special setup requirements]
- [Known limitations or considerations]
```

## 🔍 Examples by Runtime

### Go Example (Gin Framework)

```go
package main

import (
    "time"
    "github.com/gin-gonic/gin"
)

type Response struct {
    Message   string    `json:"message"`
    Timestamp time.Time `json:"timestamp"`
    Data      any       `json:"data,omitempty"`
}

type User struct {
    ID   int    `json:"id"`
    Name string `json:"name"`
}

func main() {
    router := gin.New()
    router.Use(gin.Recovery())

    router.GET("/", func(c *gin.Context) {
        c.JSON(200, Response{
            Message:   "Hello, World!",
            Timestamp: time.Now(),
        })
    })

    router.GET("/health", func(c *gin.Context) {
        c.JSON(200, Response{
            Message:   "OK",
            Timestamp: time.Now(),
        })
    })

    router.GET("/user/:id", func(c *gin.Context) {
        id := c.Param("id")
        // Parse and validate id...
        c.JSON(200, Response{
            Message:   "User retrieved successfully",
            Timestamp: time.Now(),
            Data: User{ID: parsedId, Name: fmt.Sprintf("User %d", parsedId)},
        })
    })

    router.POST("/users", func(c *gin.Context) {
        var user User
        if err := c.ShouldBindJSON(&user); err != nil {
            c.JSON(400, gin.H{"error": "Invalid request body"})
            return
        }
        user.ID = int(time.Now().Unix() % 10000)
        c.JSON(201, Response{
            Message:   "User created successfully",
            Timestamp: time.Now(),
            Data:      user,
        })
    })

    router.Run(":8080")
}
```

### Node.js Example (Express)

```javascript
import express from 'express';
import cors from 'cors';

const app = express();

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({
    message: "Hello, World!",
    timestamp: new Date()
  });
});

app.get('/health', (req, res) => {
  res.json({
    message: "OK",
    timestamp: new Date()
  });
});

app.get('/user/:id', (req, res) => {
  const id = parseInt(req.params.id);
  if (isNaN(id)) {
    return res.status(400).json({ error: "Invalid user ID" });
  }
  
  res.json({
    message: "User retrieved successfully",
    timestamp: new Date(),
    data: { id, name: `User ${id}` }
  });
});

app.post('/users', (req, res) => {
  const user = {
    id: Math.floor(Date.now() % 10000),
    name: req.body.name || "Unknown"
  };
  
  res.status(201).json({
    message: "User created successfully",
    timestamp: new Date(),
    data: user
  });
});

app.listen(8080, () => {
  console.log('Express server starting on :8080');
});
```

### Bun Example (Hono)

```typescript
import { Hono } from 'hono';
import { cors } from 'hono/cors';

interface Response {
  message: string;
  timestamp: Date;
  data?: any;
}

const app = new Hono();

app.use('/*', cors());

app.get('/', (c) => {
  const response: Response = {
    message: "Hello, World!",
    timestamp: new Date(),
  };
  return c.json(response);
});

app.get('/health', (c) => {
  const response: Response = {
    message: "OK",
    timestamp: new Date(),
  };
  return c.json(response);
});

app.get('/user/:id', (c) => {
  const id = parseInt(c.req.param('id'));
  if (isNaN(id)) {
    return c.json({ error: "Invalid user ID" }, 400);
  }

  const response: Response = {
    message: "User retrieved successfully",
    timestamp: new Date(),
    data: { id, name: `User ${id}` },
  };
  return c.json(response);
});

app.post('/users', async (c) => {
  try {
    const body = await c.req.json();
    const user = {
      id: Math.floor(Date.now() % 10000),
      name: body.name || "Unknown",
    };

    const response: Response = {
      message: "User created successfully",
      timestamp: new Date(),
      data: user,
    };
    return c.json(response, 201);
  } catch (error) {
    return c.json({ error: "Invalid request body" }, 400);
  }
});

export default {
  port: 8080,
  fetch: app.fetch,
};
```

## 🐛 Troubleshooting

### Common Issues

#### Port Already in Use
```bash
# Check what's using port 8080
lsof -i :8080

# Kill existing processes
make stop-servers
```

#### Dependencies Not Installing
```bash
# Go
cd servers/your-framework && go mod tidy

# Node.js
cd servers/your-framework && npm install

# Bun
cd servers/your-framework && bun install
```

#### Endpoints Not Responding
1. Check server logs for errors
2. Verify routes are registered correctly
3. Test with curl manually
4. Check firewall/security settings

#### JSON Parsing Errors
1. Ensure Content-Type headers are set
2. Validate JSON structure
3. Check middleware configuration
4. Test with simple JSON payloads

### Performance Issues

#### Low Benchmark Scores
- Profile your code for bottlenecks
- Minimize middleware overhead
- Use efficient JSON serialization
- Check for memory leaks
- Optimize database queries (if any)

#### High Latency
- Reduce request processing overhead
- Optimize routing logic
- Check for blocking operations
- Profile CPU usage

## 💡 Best Practices

### Performance Optimization

1. **Minimal Middleware**: Only include necessary middleware
2. **Efficient Routing**: Use framework's fastest routing methods
3. **JSON Optimization**: Use native or optimized JSON libraries
4. **Connection Handling**: Properly configure timeouts and limits
5. **Memory Management**: Avoid memory leaks and excessive allocations

### Code Quality

1. **Error Handling**: Comprehensive error handling without performance impact
2. **Logging**: Structured logging for debugging
3. **Documentation**: Clear code comments and README
4. **Testing**: Unit tests for critical paths
5. **Security**: Basic input validation and security headers

### Framework Selection

1. **Maturity**: Choose stable, well-maintained frameworks
2. **Performance**: Select frameworks optimized for high throughput
3. **Community**: Frameworks with active communities and documentation
4. **Features**: Frameworks that showcase unique capabilities
5. **Ecosystem**: Consider the broader ecosystem and tooling

### Contribution Guidelines

1. **Consistency**: Follow existing patterns and conventions
2. **Documentation**: Include comprehensive setup instructions
3. **Testing**: Thoroughly test before submitting
4. **Performance**: Optimize for the benchmark scenario
5. **Maintainability**: Write clean, maintainable code

## 📚 Resources

- [Project README](README.md) - General project information
- [Setup Guide](SETUP.md) - Detailed setup instructions
- [Templates](templates/) - Starting templates for different runtimes
- [Existing Implementations](servers/) - Reference implementations
- [Benchmark Configuration](benchmark.json) - Project configuration

### Framework Documentation

- **Go**: [Gin](https://gin-gonic.com/), [Echo](https://echo.labstack.com/), [Chi](https://go-chi.io/)
- **Node.js**: [Express](https://expressjs.com/), [Fastify](https://fastify.dev/), [Koa](https://koajs.com/)
- **Bun**: [Hono](https://hono.dev/), [Elysia](https://elysiajs.com/)
- **Performance**: [wrk documentation](https://github.com/wg/wrk)

## 🤝 Community

- **Issues**: Report bugs or request features via GitHub Issues
- **Discussions**: Use GitHub Discussions for questions and ideas
- **Pull Requests**: Submit improvements and new implementations
- **Documentation**: Help improve guides and examples

## 📜 License

All contributions will be licensed under the MIT License. By submitting a pull request, you agree to license your code under the same terms.

---

**Happy contributing! 🚀**

*Help us build the most comprehensive web framework benchmark suite!*