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
