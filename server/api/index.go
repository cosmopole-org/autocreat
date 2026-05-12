// Package api provides the Vercel serverless handler entry point.
// It sets up the same Gin engine as the standalone server but exports it
// as a plain http.HandlerFunc for the @vercel/go runtime.
package api

import (
	"net/http"

	"github.com/autocreat/server/internal/app"
	"github.com/autocreat/server/internal/config"
	"github.com/autocreat/server/internal/database"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

var (
	ginApp *app.App
	initDB *gorm.DB
)

func init() {
	log, _ := zap.NewProduction()

	cfg, err := config.Load()
	if err != nil {
		log.Fatal("config load failed", zap.Error(err))
	}

	db, err := database.Connect(cfg.DatabaseURL, log)
	if err != nil {
		log.Fatal("db connect failed", zap.Error(err))
	}
	if err := database.Migrate(db); err != nil {
		log.Fatal("db migrate failed", zap.Error(err))
	}
	initDB = db

	// Redis is optional; Vercel environments may not have it.
	rdb, _ := database.NewRedisClient(cfg.RedisURL, log)

	ginApp = app.New(cfg, db, rdb, log)
}

// Handler is the Vercel serverless entry point.
func Handler(w http.ResponseWriter, r *http.Request) {
	ginApp.Engine.ServeHTTP(w, r)
}
