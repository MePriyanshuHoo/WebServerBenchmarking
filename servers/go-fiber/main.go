package main

import (
	"fmt"
	"log"
	"strconv"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/recover"
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
	app := fiber.New(fiber.Config{
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
	})

	// Middleware
	app.Use(recover.New())
	app.Use(cors.New())

	// Simple GET endpoint
	app.Get("/", func(c *fiber.Ctx) error {
		response := Response{
			Message:   "Hello, World!",
			Timestamp: time.Now(),
		}
		return c.JSON(response)
	})

	// GET endpoint with path parameter
	app.Get("/user/:id", func(c *fiber.Ctx) error {
		idStr := c.Params("id")
		id, err := strconv.Atoi(idStr)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "Invalid user ID",
			})
		}

		user := User{
			ID:   id,
			Name: fmt.Sprintf("User %d", id),
		}

		response := Response{
			Message:   "User retrieved successfully",
			Timestamp: time.Now(),
			Data:      user,
		}

		return c.JSON(response)
	})

	// POST endpoint
	app.Post("/users", func(c *fiber.Ctx) error {
		var user User
		if err := c.BodyParser(&user); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "Invalid request body",
			})
		}

		// Simulate processing
		user.ID = int(time.Now().Unix() % 10000)

		response := Response{
			Message:   "User created successfully",
			Timestamp: time.Now(),
			Data:      user,
		}

		return c.Status(fiber.StatusCreated).JSON(response)
	})

	// Health check endpoint
	app.Get("/health", func(c *fiber.Ctx) error {
		response := Response{
			Message:   "OK",
			Timestamp: time.Now(),
		}
		return c.JSON(response)
	})

	log.Println("Go Fiber server starting on :8080")
	log.Fatal(app.Listen(":8080"))
}
