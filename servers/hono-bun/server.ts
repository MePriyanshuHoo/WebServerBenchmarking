import { Hono } from 'hono';
import { cors } from 'hono/cors';

interface Response {
  message: string;
  timestamp: Date;
  data?: any;
}

interface User {
  id: number;
  name: string;
}

const app = new Hono();

// Middleware
app.use('/*', cors());

// Simple GET endpoint
app.get('/', (c) => {
  const response: Response = {
    message: "Hello, World!",
    timestamp: new Date(),
  };
  return c.json(response);
});

// GET endpoint with path parameter
app.get('/user/:id', (c) => {
  const idStr = c.req.param('id');
  const id = parseInt(idStr);

  if (isNaN(id)) {
    return c.json({ error: "Invalid user ID" }, 400);
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

  return c.json(response);
});

// POST endpoint
app.post('/users', async (c) => {
  try {
    const body = await c.req.json();
    const user: User = {
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

// Health check endpoint
app.get('/health', (c) => {
  const response: Response = {
    message: "OK",
    timestamp: new Date(),
  };
  return c.json(response);
});

// Error handling
app.onError((err, c) => {
  console.error("Server error:", err);
  return c.json({ error: "Internal Server Error" }, 500);
});

// 404 handler
app.notFound((c) => {
  return c.json({ error: "Not Found" }, 404);
});

const server = Bun.serve({
  port: 8080,
  fetch: app.fetch,
});

console.log(`Hono on Bun server starting on http://localhost:${server.port}`);
