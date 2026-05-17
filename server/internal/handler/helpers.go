package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// companyIDFromContext extracts the company UUID from either:
//  1. The "routeCompanyID" context key (set by company middleware for /companies/:cid/... routes)
//  2. The "companyId" query parameter (used by flat /flows, /forms, etc. routes)
func companyIDFromContext(c *gin.Context) uuid.UUID {
	if v, ok := c.Get("routeCompanyID"); ok {
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
