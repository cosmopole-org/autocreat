package bootstrap

import (
	"fmt"

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
