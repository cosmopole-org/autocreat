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
	ContextIsDemo    = "isDemo"
)

// Auth validates the Bearer JWT from the Authorization header or, as a
// fallback, from the ?token= query parameter (required for WebSocket upgrades
// because browsers cannot set headers on WebSocket connections).
func Auth(authSvc *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var tokenStr string

		header := c.GetHeader("Authorization")
		if header != "" {
			parts := strings.SplitN(header, " ", 2)
			if len(parts) != 2 || !strings.EqualFold(parts[0], "bearer") {
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid authorization format"})
				return
			}
			tokenStr = parts[1]
		} else if q := c.Query("token"); q != "" {
			tokenStr = q
		} else {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "missing authorization header"})
			return
		}

		claims, err := authSvc.ValidateAccessToken(tokenStr)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
			return
		}

		c.Set(ContextClaims, claims)
		c.Set(ContextUserID, claims.UserID)
		c.Set(ContextEmail, claims.Email)
		c.Set(ContextIsDemo, claims.IsDemo)
		if claims.CompanyID != nil {
			c.Set(ContextCompanyID, *claims.CompanyID)
		}
		if claims.RoleID != nil {
			c.Set(ContextRoleID, *claims.RoleID)
		}

		c.Next()
	}
}
