package middleware_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/autocreat/server/internal/middleware"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func newCORSEngine(origins []string) *gin.Engine {
	r := gin.New()
	r.Use(middleware.CORS(origins))
	r.GET("/data", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"ok": true})
	})
	return r
}

func TestCORS_AllowedOrigin(t *testing.T) {
	r := newCORSEngine([]string{"http://localhost:3000"})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodOptions, "/data", nil)
	req.Header.Set("Origin", "http://localhost:3000")
	req.Header.Set("Access-Control-Request-Method", "GET")
	r.ServeHTTP(w, req)

	assert.Equal(t, "http://localhost:3000", w.Header().Get("Access-Control-Allow-Origin"))
}

func TestCORS_DisallowedOriginDoesNotSetHeader(t *testing.T) {
	r := newCORSEngine([]string{"http://localhost:3000"})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodOptions, "/data", nil)
	req.Header.Set("Origin", "http://evil.example.com")
	req.Header.Set("Access-Control-Request-Method", "GET")
	r.ServeHTTP(w, req)

	assert.NotEqual(t, "http://evil.example.com", w.Header().Get("Access-Control-Allow-Origin"))
}

func TestCORS_AllowsCredentials(t *testing.T) {
	r := newCORSEngine([]string{"http://localhost:3000"})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodOptions, "/data", nil)
	req.Header.Set("Origin", "http://localhost:3000")
	req.Header.Set("Access-Control-Request-Method", "POST")
	r.ServeHTTP(w, req)

	assert.Equal(t, "true", w.Header().Get("Access-Control-Allow-Credentials"))
}

func TestCORS_AllowsAuthorizationHeader(t *testing.T) {
	r := newCORSEngine([]string{"http://localhost:3000"})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodOptions, "/data", nil)
	req.Header.Set("Origin", "http://localhost:3000")
	req.Header.Set("Access-Control-Request-Method", "GET")
	req.Header.Set("Access-Control-Request-Headers", "Authorization")
	r.ServeHTTP(w, req)

	assert.Contains(t, w.Header().Get("Access-Control-Allow-Headers"), "Authorization")
}

func TestCORS_MultipleOrigins(t *testing.T) {
	origins := []string{"http://app.example.com", "http://admin.example.com"}
	r := newCORSEngine(origins)

	for _, origin := range origins {
		w := httptest.NewRecorder()
		req, _ := http.NewRequest(http.MethodOptions, "/data", nil)
		req.Header.Set("Origin", origin)
		req.Header.Set("Access-Control-Request-Method", "GET")
		r.ServeHTTP(w, req)
		assert.Equal(t, origin, w.Header().Get("Access-Control-Allow-Origin"), "origin: %s", origin)
	}
}

func TestCORS_AllowedMethods(t *testing.T) {
	r := newCORSEngine([]string{"http://localhost:3000"})

	for _, method := range []string{"GET", "POST", "PUT", "DELETE", "PATCH"} {
		w := httptest.NewRecorder()
		req, _ := http.NewRequest(http.MethodOptions, "/data", nil)
		req.Header.Set("Origin", "http://localhost:3000")
		req.Header.Set("Access-Control-Request-Method", method)
		r.ServeHTTP(w, req)
		assert.Contains(t, w.Header().Get("Access-Control-Allow-Methods"), method, "method: %s", method)
	}
}
