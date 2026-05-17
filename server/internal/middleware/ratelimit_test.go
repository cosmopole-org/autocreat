package middleware_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/autocreat/server/internal/middleware"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func newRateLimitedEngine(rps, burst int) *gin.Engine {
	r := gin.New()
	r.Use(middleware.RateLimiter(rps, burst))
	r.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"pong": true})
	})
	return r
}

func TestRateLimiter_AllowsRequestsWithinLimit(t *testing.T) {
	r := newRateLimitedEngine(100, 10)

	for i := 0; i < 5; i++ {
		w := httptest.NewRecorder()
		req, _ := http.NewRequest(http.MethodGet, "/ping", nil)
		req.RemoteAddr = "127.0.0.1:1234"
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusOK, w.Code, "request %d should pass", i+1)
	}
}

func TestRateLimiter_BlocksExcessRequests(t *testing.T) {
	// burst=1, rps=0 means first request uses the one token, then the bucket is empty.
	r := newRateLimitedEngine(0, 1)

	statuses := make([]int, 5)
	for i := range statuses {
		w := httptest.NewRecorder()
		req, _ := http.NewRequest(http.MethodGet, "/ping", nil)
		req.RemoteAddr = "10.0.0.1:9999"
		r.ServeHTTP(w, req)
		statuses[i] = w.Code
	}

	// First request should succeed; subsequent should be rate-limited.
	assert.Equal(t, http.StatusOK, statuses[0])
	for i := 1; i < len(statuses); i++ {
		assert.Equal(t, http.StatusTooManyRequests, statuses[i], "request %d should be rate-limited", i+1)
	}
}

func TestRateLimiter_SeparateBucketsPerIP(t *testing.T) {
	r := newRateLimitedEngine(0, 1)

	for _, ip := range []string{"192.168.1.1:1234", "192.168.1.2:1234", "192.168.1.3:1234"} {
		w := httptest.NewRecorder()
		req, _ := http.NewRequest(http.MethodGet, "/ping", nil)
		req.RemoteAddr = ip
		r.ServeHTTP(w, req)
		// Each unique IP gets its own bucket with burst=1, so first request succeeds.
		assert.Equal(t, http.StatusOK, w.Code, "first request from %s should succeed", ip)
	}
}

func TestRateLimiter_ReturnsTooManyRequestsBody(t *testing.T) {
	r := newRateLimitedEngine(0, 1)

	// Exhaust the single token.
	w1 := httptest.NewRecorder()
	req1, _ := http.NewRequest(http.MethodGet, "/ping", nil)
	req1.RemoteAddr = "1.2.3.4:80"
	r.ServeHTTP(w1, req1)

	// Second request should be blocked with the expected error body.
	w2 := httptest.NewRecorder()
	req2, _ := http.NewRequest(http.MethodGet, "/ping", nil)
	req2.RemoteAddr = "1.2.3.4:80"
	r.ServeHTTP(w2, req2)

	assert.Equal(t, http.StatusTooManyRequests, w2.Code)
	assert.Contains(t, w2.Body.String(), "rate limit exceeded")
}
