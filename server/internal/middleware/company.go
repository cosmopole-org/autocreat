package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// CompanyContext extracts :cid from the URL path and validates it as a UUID.
func CompanyContext() gin.HandlerFunc {
	return func(c *gin.Context) {
		cidStr := c.Param("cid")
		if cidStr == "" {
			c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"error": "missing company id"})
			return
		}
		cid, err := uuid.Parse(cidStr)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"error": "invalid company id"})
			return
		}
		c.Set("routeCompanyID", cid)
		c.Next()
	}
}
