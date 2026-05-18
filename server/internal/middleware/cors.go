package middleware

import (
	"strings"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

// CORS returns a configured CORS middleware.
//
// If any entry in allowedOrigins is "http://localhost:*" or
// "http://127.0.0.1:*", all localhost/127.0.0.1 origins are permitted
// regardless of port (useful for Flutter web dev servers that pick a
// random ephemeral port). All other entries are matched exactly.
func CORS(allowedOrigins []string) gin.HandlerFunc {
	exactSet := make(map[string]struct{}, len(allowedOrigins))
	localhostWildcard := false

	for _, o := range allowedOrigins {
		switch o {
		case "http://localhost:*", "http://127.0.0.1:*":
			localhostWildcard = true
		default:
			exactSet[o] = struct{}{}
		}
	}

	cfg := cors.Config{
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization", "Accept", "X-Requested-With"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}

	if localhostWildcard {
		cfg.AllowOriginFunc = func(origin string) bool {
			if _, ok := exactSet[origin]; ok {
				return true
			}
			return strings.HasPrefix(origin, "http://localhost:") ||
				strings.HasPrefix(origin, "http://127.0.0.1:")
		}
	} else {
		cfg.AllowOrigins = allowedOrigins
	}

	return cors.New(cfg)
}
