package database

import (
	"fmt"
	"time"

	"go.uber.org/zap"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	gormlogger "gorm.io/gorm/logger"

	"github.com/autocreat/server/internal/models"
)

// Connect opens a PostgreSQL connection using GORM and configures the connection pool.
func Connect(dsn string, log *zap.Logger) (*gorm.DB, error) {
	var (
		db  *gorm.DB
		err error
	)

	gormCfg := &gorm.Config{
		Logger: gormlogger.Default.LogMode(gormlogger.Silent),
	}

	// Retry up to 10 times with exponential back-off to handle transient startup failures
	// (e.g. the database container is still initializing).
	for attempt := 1; attempt <= 10; attempt++ {
		db, err = gorm.Open(postgres.Open(dsn), gormCfg)
		if err == nil {
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

	sqlDB, err := db.DB()
	if err != nil {
		return nil, fmt.Errorf("could not get underlying sql.DB: %w", err)
	}

	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetMaxOpenConns(100)
	sqlDB.SetConnMaxLifetime(time.Hour)

	log.Info("database connected")
	return db, nil
}

// Migrate runs GORM's AutoMigrate for all application models.
func Migrate(db *gorm.DB) error {
	return db.AutoMigrate(
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
	)
}
