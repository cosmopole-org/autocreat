// Package api provides the Vercel serverless handler entry point.
package api

import (
	"fmt"
	"net/http"

	"github.com/autocreat/server/pkg/bootstrap"
	"go.uber.org/zap"
)

var ginHandler http.Handler

func init() {
	log, _ := zap.NewProduction()
	h, err := bootstrap.NewHandler(log)
	if err != nil {
		log.Error("bootstrap failed", zap.Error(err))
		errMsg := fmt.Sprintf(`{"error":"service unavailable","detail":%q}`, err.Error())
		ginHandler = http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if origin := r.Header.Get("Origin"); origin != "" {
				w.Header().Set("Access-Control-Allow-Origin", origin)
				w.Header().Set("Access-Control-Allow-Credentials", "true")
				w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
				w.Header().Set("Access-Control-Allow-Headers", "Origin, Content-Type, Authorization, Accept, X-Requested-With")
			}
			if r.Method == http.MethodOptions {
				w.WriteHeader(http.StatusNoContent)
				return
			}
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusServiceUnavailable)
			_, _ = w.Write([]byte(errMsg))
		})
		return
	}
	ginHandler = h
}

// Handler is the Vercel serverless entry point.
func Handler(w http.ResponseWriter, r *http.Request) {
	ginHandler.ServeHTTP(w, r)
}
