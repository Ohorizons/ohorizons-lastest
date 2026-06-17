package main

import (
	"fmt"
	"os"

	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()

	registerHealthRoutes(r)
	registerItemRoutes(r)

	port := os.Getenv("PORT")
	if port == "" {
		port = "${{ values.httpPort }}"
	}

	fmt.Printf("${{ values.serviceName }} listening on port %s\n", port)
	if err := r.Run(":" + port); err != nil {
		fmt.Fprintf(os.Stderr, "failed to start server: %v\n", err)
		os.Exit(1)
	}
}
