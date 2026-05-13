package bootstrap

import (
	"fmt"
	"net/http"

	"github.com/autocreat/server/internal/app"
	"github.com/autocreat/server/internal/config"
	"github.com/autocreat/server/internal/database"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

// ConnectDB opens and migrates the PostgreSQL database.
func ConnectDB(cfg *config.Config, log *zap.Logger) (*gorm.DB, error) {
	db, err := database.Connect(cfg.DatabaseURL, log)
	if err != nil {
		return nil, fmt.Errorf("db connect: %w", err)
	}

	// Configure pool from config.
	sqlDB, _ := db.DB()
	sqlDB.SetMaxIdleConns(cfg.DBMaxIdleConns)
	sqlDB.SetMaxOpenConns(cfg.DBMaxOpenConns)
	sqlDB.SetConnMaxLifetime(cfg.DBConnMaxLifetime)

	if err := database.Migrate(db); err != nil {
		return nil, fmt.Errorf("db migrate: %w", err)
	}

	return db, nil
}

// NewHandler initialises all dependencies and returns a ready http.Handler.
// Used by the Vercel serverless entry point to avoid direct internal imports.
func NewHandler(log *zap.Logger) (http.Handler, error) {
	cfg, err := config.Load()
	if err != nil {
		return nil, fmt.Errorf("config load: %w", err)
	}

	db, err := ConnectDB(cfg, log)
	if err != nil {
		return nil, err
	}

	rdb, err := database.NewRedisClient(cfg.RedisURL, log)
	if err != nil {
		log.Warn("redis not available, caching disabled", zap.Error(err))
	}

	a := app.New(cfg, db, rdb, log)
	return a.Engine, nil
}
