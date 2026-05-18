package handler

import (
	"github.com/autocreat/server/internal/middleware"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// companyIDFromContext extracts the company UUID in priority order:
//  1. "routeCompanyID" — set by CompanyContext middleware for /companies/:cid/... routes
//  2. JWT claims      — set by Auth middleware for all authenticated flat routes
//  3. ?companyId      — explicit query parameter override
func companyIDFromContext(c *gin.Context) uuid.UUID {
	if v, ok := c.Get("routeCompanyID"); ok {
		if id, ok := v.(uuid.UUID); ok {
			return id
		}
	}
	if v, ok := c.Get(middleware.ContextCompanyID); ok {
		if id, ok := v.(uuid.UUID); ok {
			return id
		}
	}
	if s := c.Query("companyId"); s != "" {
		if id, err := uuid.Parse(s); err == nil {
			return id
		}
	}
	return uuid.Nil
}
