package main

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

var startTime = time.Now()

func registerHealthRoutes(r *gin.Engine) {
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "${{ values.serviceName }}",
		})
	})

	r.GET("/ready", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":         "ready",
			"uptime_seconds": int(time.Since(startTime).Seconds()),
		})
	})

	r.GET("/metrics", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"service":        "${{ values.serviceName }}",
			"uptime_seconds": int(time.Since(startTime).Seconds()),
			"items_count":    len(items),
		})
	})
}
