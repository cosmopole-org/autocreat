package database

import (
	_ "embed"
	"fmt"
	"os"
	"strconv"
	"time"

	"go.uber.org/zap"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	gormlogger "gorm.io/gorm/logger"

	"github.com/autocreat/server/internal/models"
)

//go:embed migrations/001_init.sql
var bootstrapSQL string

// maxDBRetries returns how many connection attempts to make.
// Defaults to 1 (fail-fast) so Vercel serverless cold starts don't time out.
// Set DB_CONNECT_RETRIES=10 in long-running server environments to restore the
// original back-off behaviour for containers that start before the DB is ready.
func maxDBRetries() int {
	if v := os.Getenv("DB_CONNECT_RETRIES"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 {
			return n
		}
	}
	return 1
}

// Connect opens a PostgreSQL connection using GORM and configures the connection pool.
func Connect(dsn string, log *zap.Logger) (*gorm.DB, error) {
	var (
		db  *gorm.DB
		err error
	)

	gormCfg := &gorm.Config{
		Logger:                                   gormlogger.Default.LogMode(gormlogger.Silent),
		DisableForeignKeyConstraintWhenMigrating: true,
	}

	maxAttempts := maxDBRetries()
	for attempt := 1; attempt <= maxAttempts; attempt++ {
		db, err = gorm.Open(postgres.Open(dsn), gormCfg)
		if err == nil {
			break
		}
		if attempt == maxAttempts {
			break
		}
		wait := time.Duration(attempt) * 2 * time.Second
		log.Warn("database connection failed, retrying",
			zap.Int("attempt", attempt),
			zap.Duration("wait", wait),
			zap.Error(err),
		)
		time.Sleep(wait)
	}
	if err != nil {
		return nil, fmt.Errorf("could not connect to database after retries: %w", err)
	}

	if _, err := db.DB(); err != nil {
		return nil, fmt.Errorf("could not get underlying sql.DB: %w", err)
	}

	log.Info("database connected")
	return db, nil
}

// Migrate creates all tables via GORM AutoMigrate (no FK constraints, avoiding
// circular-dependency errors), then applies the embedded SQL file which adds
// extensions, indexes, CHECK constraints, and FK constraints idempotently.
func Migrate(db *gorm.DB) error {
	if err := db.AutoMigrate(
		&models.User{},
		&models.Session{},
		&models.Company{},
		&models.CompanyMember{},
		&models.Role{},
		&models.Flow{},
		&models.FlowNode{},
		&models.FlowEdge{},
		&models.FlowAssignment{},
		&models.FlowInstance{},
		&models.FlowInstanceStep{},
		&models.FormDefinition{},
		&models.FormSubmission{},
		&models.ModelDefinition{},
		&models.ModelEntity{},
		&models.LetterTemplate{},
		&models.GeneratedLetter{},
		&models.Ticket{},
		&models.TicketMessage{},
	); err != nil {
		return err
	}

	return db.Exec(bootstrapSQL).Error
}
