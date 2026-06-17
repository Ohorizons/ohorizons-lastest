package main

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type Item struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description,omitempty"`
}

var items = map[string]Item{}

func registerItemRoutes(r *gin.Engine) {
	api := r.Group("/api/items")

	api.GET("", listItems)
	api.GET("/:id", getItem)
	api.POST("", createItem)
	api.PUT("/:id", updateItem)
	api.DELETE("/:id", deleteItem)
}

func listItems(c *gin.Context) {
	result := make([]Item, 0, len(items))
	for _, item := range items {
		result = append(result, item)
	}
	c.JSON(http.StatusOK, result)
}

func getItem(c *gin.Context) {
	item, ok := items[c.Param("id")]
	if !ok {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}
	c.JSON(http.StatusOK, item)
}

func createItem(c *gin.Context) {
	var input struct {
		Name        string `json:"name" binding:"required"`
		Description string `json:"description"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	item := Item{
		ID:          uuid.New().String(),
		Name:        input.Name,
		Description: input.Description,
	}
	items[item.ID] = item
	c.JSON(http.StatusCreated, item)
}

func updateItem(c *gin.Context) {
	id := c.Param("id")
	item, ok := items[id]
	if !ok {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}
	var input struct {
		Name        *string `json:"name"`
		Description *string `json:"description"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if input.Name != nil {
		item.Name = *input.Name
	}
	if input.Description != nil {
		item.Description = *input.Description
	}
	items[id] = item
	c.JSON(http.StatusOK, item)
}

func deleteItem(c *gin.Context) {
	id := c.Param("id")
	if _, ok := items[id]; !ok {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}
	delete(items, id)
	c.Status(http.StatusNoContent)
}
