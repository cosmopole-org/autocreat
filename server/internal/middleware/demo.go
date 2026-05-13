package middleware

import (
	"github.com/autocreat/server/internal/demo"
	"github.com/gin-gonic/gin"
)

// DemoMode intercepts requests whose JWT has is_demo=true and returns
// pre-canned demo data instead of hitting the database.
func DemoMode() gin.HandlerFunc {
	return func(c *gin.Context) {
		if isDemo, _ := c.Get(ContextIsDemo); isDemo == true { //nolint:gosimple
			if demo.Handle(c) {
				c.Abort()
				return
			}
		}
		c.Next()
	}
}
