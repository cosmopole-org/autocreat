package middleware

import (
	"net/http"
	"strings"

	"github.com/autocreat/server/internal/service"
	"github.com/gin-gonic/gin"
)

const (
	ContextUserID    = "userID"
	ContextEmail     = "email"
	ContextCompanyID = "companyID"
	ContextRoleID    = "roleID"
	ContextClaims    = "claims"
)

// Auth validates the Bearer JWT in the Authorization header.
func Auth(authSvc *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if header == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "missing authorization header"})
			return
		}

		parts := strings.SplitN(header, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "bearer") {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid authorization format"})
			return
		}

		claims, err := authSvc.ValidateAccessToken(parts[1])
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
			return
		}

		c.Set(ContextClaims, claims)
		c.Set(ContextUserID, claims.UserID)
		c.Set(ContextEmail, claims.Email)
		if claims.CompanyID != nil {
			c.Set(ContextCompanyID, *claims.CompanyID)
		}
		if claims.RoleID != nil {
			c.Set(ContextRoleID, *claims.RoleID)
		}

		c.Next()
	}
}
