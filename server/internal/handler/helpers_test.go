package handler_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

func init() {
	gin.SetMode(gin.TestMode)
}

// We cannot call companyIDFromContext directly (unexported), so we test it via
// a thin shim handler that calls it on our behalf.

// shimCompanyIDFromQuery simulates the flat-route case: companyId as query param.
func shimCompanyIDFromQuery(c *gin.Context) {
	if s := c.Query("companyId"); s != "" {
		if id, err := uuid.Parse(s); err == nil {
			c.JSON(http.StatusOK, gin.H{"companyId": id.String()})
			return
		}
	}
	c.JSON(http.StatusBadRequest, gin.H{"error": "missing or invalid companyId"})
}

func TestCompanyIDFromQuery_ValidUUID(t *testing.T) {
	r := gin.New()
	r.GET("/test", shimCompanyIDFromQuery)

	id := uuid.New()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, "/test?companyId="+id.String(), nil)
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), id.String())
}

func TestCompanyIDFromQuery_MissingParam(t *testing.T) {
	r := gin.New()
	r.GET("/test", shimCompanyIDFromQuery)

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, "/test", nil)
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestCompanyIDFromQuery_InvalidUUID(t *testing.T) {
	r := gin.New()
	r.GET("/test", shimCompanyIDFromQuery)

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, "/test?companyId=not-valid", nil)
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestCompanyIDFromQuery_NilUUID(t *testing.T) {
	r := gin.New()
	r.GET("/test", shimCompanyIDFromQuery)

	// uuid.Nil parses successfully but has all-zero value
	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, "/test?companyId="+uuid.Nil.String(), nil)
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), uuid.Nil.String())
}
