package main

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/autocreat/server/internal/app"
	"github.com/autocreat/server/internal/config"
	"github.com/autocreat/server/internal/database"
	"github.com/autocreat/server/pkg/bootstrap"
	"go.uber.org/zap"
)

func main() {
	// Logger
	log, err := zap.NewProduction()
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to create logger: %v\n", err)
		os.Exit(1)
	}
	defer log.Sync() //nolint:errcheck

	// Config
	cfg, err := config.Load()
	if err != nil {
		log.Fatal("failed to load config", zap.Error(err))
	}

	// Database (with retry + migration)
	db, err := bootstrap.ConnectDB(cfg, log)
	if err != nil {
		log.Fatal("database setup failed", zap.Error(err))
	}

	// Redis (optional; gracefully skip if not available)
	rdb, err := database.NewRedisClient(cfg.RedisURL, log)
	if err != nil {
		log.Warn("redis not available, caching disabled", zap.Error(err))
		rdb = nil
	}

	// Wire application
	application := app.New(cfg, db, rdb, log)

	// HTTP server
	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      application.Engine,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start in goroutine so we can listen for shutdown signals.
	serverErr := make(chan error, 1)
	go func() {
		log.Info("server starting", zap.String("addr", srv.Addr))
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			serverErr <- err
		}
	}()

	// Wait for SIGINT or SIGTERM.
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	select {
	case err := <-serverErr:
		log.Fatal("server error", zap.Error(err))
	case sig := <-quit:
		log.Info("shutdown signal received", zap.String("signal", sig.String()))
	}

	// Graceful shutdown with 30s timeout.
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Error("server shutdown error", zap.Error(err))
	}

	// Close DB
	if sqlDB, err := db.DB(); err == nil {
		_ = sqlDB.Close()
	}

	// Close Redis
	if rdb != nil {
		_ = rdb.Close()
	}

	log.Info("server stopped")
}
