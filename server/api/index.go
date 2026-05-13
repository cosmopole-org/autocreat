// Package api provides the Vercel serverless handler entry point.
package api

import (
	"net/http"

	"github.com/autocreat/server/pkg/bootstrap"
	"go.uber.org/zap"
)

var ginHandler http.Handler

func init() {
	log, _ := zap.NewProduction()
	h, err := bootstrap.NewHandler(log)
	if err != nil {
		log.Fatal("bootstrap failed", zap.Error(err))
	}
	ginHandler = h
}

// Handler is the Vercel serverless entry point.
func Handler(w http.ResponseWriter, r *http.Request) {
	ginHandler.ServeHTTP(w, r)
}
