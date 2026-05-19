package handler

import (
	"context"

	"github.com/autocreat/server/internal/middleware"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// roleProvider is the minimal interface the helpers need from FlowService.
type roleProvider interface {
	GetCurrentUserRoleID(ctx context.Context, userID uuid.UUID) *uuid.UUID
}

// roleIDFromContext returns the user's role UUID. It prefers the JWT claim; if
// that is absent (stale token or role assigned after login) it falls back to a
// live DB lookup so role-assigned tasks are always visible.
func roleIDFromContext(c *gin.Context, svc roleProvider, userID uuid.UUID) *uuid.UUID {
	if v, exists := c.Get(middleware.ContextRoleID); exists {
		rid := v.(uuid.UUID)
		return &rid
	}
	return svc.GetCurrentUserRoleID(c.Request.Context(), userID)
}

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
