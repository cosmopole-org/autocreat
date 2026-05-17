package middleware_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/autocreat/server/internal/middleware"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

func newCompanyContextEngine() *gin.Engine {
	r := gin.New()
	r.GET("/companies/:cid/resources", middleware.CompanyContext(), func(c *gin.Context) {
		cid, _ := c.Get("routeCompanyID")
		c.JSON(http.StatusOK, gin.H{"companyId": cid.(uuid.UUID).String()})
	})
	return r
}

func TestCompanyContext_ValidUUID(t *testing.T) {
	r := newCompanyContextEngine()
	validID := uuid.New()

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, "/companies/"+validID.String()+"/resources", nil)
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), validID.String())
}

func TestCompanyContext_InvalidUUID(t *testing.T) {
	r := newCompanyContextEngine()

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, "/companies/not-a-uuid/resources", nil)
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
	assert.Contains(t, w.Body.String(), "invalid company id")
}

func TestCompanyContext_SetsRouteCompanyID(t *testing.T) {
	r := gin.New()
	validID := uuid.New()
	var captured uuid.UUID

	r.GET("/companies/:cid/things", middleware.CompanyContext(), func(c *gin.Context) {
		captured = c.MustGet("routeCompanyID").(uuid.UUID)
		c.JSON(http.StatusOK, gin.H{})
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, "/companies/"+validID.String()+"/things", nil)
	r.ServeHTTP(w, req)

	assert.Equal(t, validID, captured)
}
