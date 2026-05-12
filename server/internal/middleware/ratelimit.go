package middleware

import (
	"net/http"
	"sync"

	"github.com/gin-gonic/gin"
	"golang.org/x/time/rate"
)

// ipLimiter holds a per-IP token bucket.
type ipLimiter struct {
	limiter *rate.Limiter
}

// RateLimiter returns a per-IP token bucket rate limiter middleware.
func RateLimiter(rps int, burst int) gin.HandlerFunc {
	var mu sync.Mutex
	limiters := make(map[string]*ipLimiter)

	getLimiter := func(ip string) *rate.Limiter {
		mu.Lock()
		defer mu.Unlock()
		if l, ok := limiters[ip]; ok {
			return l.limiter
		}
		l := &ipLimiter{limiter: rate.NewLimiter(rate.Limit(rps), burst)}
		limiters[ip] = l
		return l.limiter
	}

	return func(c *gin.Context) {
		ip := c.ClientIP()
		l := getLimiter(ip)
		if !l.Allow() {
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"error": "rate limit exceeded",
			})
			return
		}
		c.Next()
	}
}
