package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"
)

// TEMPLATE: Replace this comment with your framework import
// Example for Gin: "github.com/gin-gonic/gin"
// Example for Echo: "github.com/labstack/echo/v4"
// Example for Chi: "github.com/go-chi/chi/v5"

// Standard response structure - KEEP THIS FORMAT for consistency
type Response struct {
	Message   string    `json:"message"`
	Timestamp time.Time `json:"timestamp"`
	Data      any       `json:"data,omitempty"`
}

// User model - KEEP THIS FORMAT for consistency
type User struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

func main() {
	// TEMPLATE: Initialize your framework here
	// Example for Gin: router := gin.New()
	// Example for Echo: e := echo.New()
	// Example for Chi: r := chi.NewRouter()

	// TEMPLATE: Add middleware if needed
	// Example: router.Use(gin.Recovery(), gin.Logger())

	// REQUIRED ENDPOINT 1: Root endpoint
	// TEMPLATE: Replace with your framework's route definition
	http.HandleFunc("/", handleRoot)

	// REQUIRED ENDPOINT 2: Health check
	// TEMPLATE: Replace with your framework's route definition
	http.HandleFunc("/health", handleHealth)

	// REQUIRED ENDPOINT 3: User GET with parameter
	// TEMPLATE: Replace with your framework's route definition
	http.HandleFunc("/user/", handleUserGet)

	// REQUIRED ENDPOINT 4: User POST
	// TEMPLATE: Replace with your framework's route definition
	http.HandleFunc("/users", handleUserPost)

	// TEMPLATE: Configure and start server
	// Most frameworks have their own server configuration
	server := &http.Server{
		Addr:         ":8080", // REQUIRED: Must listen on port 8080
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
	}

	log.Println("TEMPLATE: [Your Framework Name] server starting on :8080")
	log.Fatal(server.ListenAndServe())
}

// REQUIRED ENDPOINT 1: Root endpoint
// Must return JSON with message and timestamp
func handleRoot(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	response := Response{
		Message:   "Hello, World!",
		Timestamp: time.Now(),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// REQUIRED ENDPOINT 2: Health check
// Must return JSON with "OK" message
func handleHealth(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	response := Response{
		Message:   "OK",
		Timestamp: time.Now(),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// REQUIRED ENDPOINT 3: User GET with parameter
// Must extract ID from URL path and return user data
func handleUserGet(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	// TEMPLATE: Extract ID from path using your framework's method
	// Example for Gin: id := c.Param("id")
	// Example for Echo: id := c.Param("id")
	// Example for Chi: id := chi.URLParam(r, "id")

	// For vanilla net/http (replace with your framework's approach):
	idStr := r.URL.Path[len("/user/"):]
	if idStr == "" {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	id, err := strconv.Atoi(idStr)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
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

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// REQUIRED ENDPOINT 4: User POST
// Must accept JSON payload and return created user
func handleUserPost(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	// TEMPLATE: Parse JSON body using your framework's method
	// Example for Gin: c.ShouldBindJSON(&user)
	// Example for Echo: c.Bind(&user)

	var user User
	if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	// Simulate processing
	user.ID = int(time.Now().Unix() % 10000)

	response := Response{
		Message:   "User created successfully",
		Timestamp: time.Now(),
		Data:      user,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}

// TEMPLATE NOTES:
// 1. Replace all "TEMPLATE:" comments with your framework-specific code
// 2. Keep the Response and User structs exactly as they are
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
