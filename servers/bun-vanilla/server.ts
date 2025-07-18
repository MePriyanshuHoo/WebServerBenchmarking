interface Response {
  message: string;
  timestamp: Date;
  data?: any;
}

interface User {
  id: number;
  name: string;
}

const server = Bun.serve({
  port: 8080,
  async fetch(req) {
    const url = new URL(req.url);
    const method = req.method;
    const pathname = url.pathname;

    // Set CORS headers
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
      // Simple GET endpoint
      if (pathname === "/" && method === "GET") {
        const response: Response = {
          message: "Hello, World!",
          timestamp: new Date(),
        };
        return new Response(JSON.stringify(response), { headers });
      }

      // GET endpoint with path parameter
      if (pathname.startsWith("/user/") && method === "GET") {
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

      // POST endpoint
      if (pathname === "/users" && method === "POST") {
        try {
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

      // Health check endpoint
      if (pathname === "/health" && method === "GET") {
        const response: Response = {
          message: "OK",
          timestamp: new Date(),
        };
        return new Response(JSON.stringify(response), { headers });
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

console.log(`Bun vanilla HTTP server starting on http://localhost:${server.port}`);
