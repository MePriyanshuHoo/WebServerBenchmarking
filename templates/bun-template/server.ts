// TEMPLATE: Replace this comment with your framework imports
// Example for Hono: import { Hono } from 'hono'
// Example for Elysia: import { Elysia } from 'elysia'
// Example for Express: import express from 'express'
// Example for Fastify: import fastify from 'fastify'

// Standard response interface - KEEP THIS FORMAT for consistency
interface Response {
  message: string;
  timestamp: Date;
  data?: any;
}

// User model - KEEP THIS FORMAT for consistency
interface User {
  id: number;
  name: string;
}

// TEMPLATE: Initialize your framework here
// Example for Hono: const app = new Hono()
// Example for Elysia: const app = new Elysia()
// Example for Express: const app = express()
// Example for Fastify: const fastify = Fastify({ logger: true })

// TEMPLATE: Add middleware if needed
// Example for Hono: app.use('/*', cors())
// Example for Express: app.use(express.json())

// For vanilla Bun (replace with your framework):
const server = Bun.serve({
  port: 8080, // REQUIRED: Must listen on port 8080
  async fetch(req) {
    const url = new URL(req.url);
    const method = req.method;
    const pathname = url.pathname;

    // Set CORS headers for consistency
    const headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    };

    // Handle CORS preflight
    if (method === "OPTIONS") {
      return new Response(null, { status: 200, headers });
    }

    try {
      // REQUIRED ENDPOINT 1: Root endpoint
      if (pathname === "/" && method === "GET") {
        return handleRoot(headers);
      }

      // REQUIRED ENDPOINT 2: Health check
      if (pathname === "/health" && method === "GET") {
        return handleHealth(headers);
      }

      // REQUIRED ENDPOINT 3: User GET with parameter
      if (pathname.startsWith("/user/") && method === "GET") {
        return handleUserGet(pathname, headers);
      }

      // REQUIRED ENDPOINT 4: User POST
      if (pathname === "/users" && method === "POST") {
        return await handleUserPost(req, headers);
      }

      // 404 Not Found
      return new Response(
        JSON.stringify({ error: "Not Found" }),
        { status: 404, headers }
      );

    } catch (error) {
      console.error("Server error:", error);
      return new Response(
        JSON.stringify({ error: "Internal Server Error" }),
        { status: 500, headers }
      );
    }
  },
});

// REQUIRED ENDPOINT 1: Root endpoint
// Must return JSON with message and timestamp
function handleRoot(headers: Record<string, string>): Response {
  const response: Response = {
    message: "Hello, World!",
    timestamp: new Date(),
  };
  return new Response(JSON.stringify(response), { headers });
}

// REQUIRED ENDPOINT 2: Health check
// Must return JSON with "OK" message
function handleHealth(headers: Record<string, string>): Response {
  const response: Response = {
    message: "OK",
    timestamp: new Date(),
  };
  return new Response(JSON.stringify(response), { headers });
}

// REQUIRED ENDPOINT 3: User GET with parameter
// Must extract ID from URL path and return user data
function handleUserGet(pathname: string, headers: Record<string, string>): Response {
  // TEMPLATE: Extract ID from path using your framework's method
  // Example for Hono: const id = c.req.param('id')
  // Example for Express: const id = req.params.id
  // Example for Fastify: const id = request.params.id

  // For vanilla Bun (replace with your framework's approach):
  const idStr = pathname.substring(6); // Remove "/user/"
  const id = parseInt(idStr);

  if (isNaN(id)) {
    return new Response(
      JSON.stringify({ error: "Invalid user ID" }),
      { status: 400, headers }
    );
  }

  const user: User = {
    id: id,
    name: `User ${id}`,
  };

  const response: Response = {
    message: "User retrieved successfully",
    timestamp: new Date(),
    data: user,
  };

  return new Response(JSON.stringify(response), { headers });
}

// REQUIRED ENDPOINT 4: User POST
// Must accept JSON payload and return created user
async function handleUserPost(req: Request, headers: Record<string, string>): Promise<Response> {
  try {
    // TEMPLATE: Parse JSON body using your framework's method
    // Example for Hono: const body = await c.req.json()
    // Example for Express: const body = req.body
    // Example for Fastify: const body = request.body

    const body = await req.json();
    const user: User = {
      id: Math.floor(Date.now() % 10000),
      name: body.name || "Unknown",
    };

    const response: Response = {
      message: "User created successfully",
      timestamp: new Date(),
      data: user,
    };

    return new Response(JSON.stringify(response), {
      status: 201,
      headers
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: "Invalid request body" }),
      { status: 400, headers }
    );
  }
}

console.log(`TEMPLATE: [Your Framework Name] server starting on http://localhost:${server.port}`);

// TEMPLATE NOTES:
// 1. Replace all "TEMPLATE:" comments with your framework-specific code
// 2. Keep the Response and User interfaces exactly as they are
// 3. Ensure all endpoints return the same JSON structure
// 4. Server must listen on port 8080
// 5. Add error handling appropriate for your framework
// 6. Test all endpoints before submitting
//
// Required endpoints:
// - GET /                -> Hello World
// - GET /health          -> Health check
// - GET /user/:id        -> User by ID
// - POST /users          -> Create user
//
// All responses must include:
// - message: string
// - timestamp: ISO timestamp
// - data: object (optional, for user endpoints)
//
// Framework-specific adaptations:
// - Replace Bun.serve with your framework's server initialization
// - Replace manual routing with your framework's router
// - Use your framework's request/response handling
// - Add framework-specific middleware as needed
