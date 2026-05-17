package config_test

import (
	"os"
	"testing"
	"time"

	"github.com/autocreat/server/internal/config"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestLoad_Defaults(t *testing.T) {
	// Clear all env vars that config reads.
	vars := []string{
		"ENV", "PORT", "DATABASE_URL", "REDIS_URL", "JWT_SECRET",
		"JWT_REFRESH_SECRET", "ALLOWED_ORIGINS", "ACCESS_TOKEN_TTL",
		"REFRESH_TOKEN_TTL", "RATE_LIMIT", "RATE_LIMIT_BURST",
		"DB_MAX_IDLE_CONNS", "DB_MAX_OPEN_CONNS", "DB_CONN_MAX_LIFETIME",
	}
	for _, v := range vars {
		os.Unsetenv(v)
	}

	cfg, err := config.Load()
	require.NoError(t, err)

	assert.Equal(t, "development", cfg.Env)
	assert.Equal(t, "8080", cfg.Port)
	assert.Contains(t, cfg.DatabaseURL, "postgres://")
	assert.Equal(t, "", cfg.RedisURL)
	assert.Equal(t, "change-me-in-production", cfg.JWTSecret)
	assert.Equal(t, "change-me-refresh-in-production", cfg.JWTRefreshSecret)
	assert.Equal(t, 15*time.Minute, cfg.AccessTokenTTL)
	assert.Equal(t, 7*24*time.Hour, cfg.RefreshTokenTTL)
	assert.Equal(t, 60, cfg.RateLimit)
	assert.Equal(t, 20, cfg.RateLimitBurst)
	assert.Equal(t, 10, cfg.DBMaxIdleConns)
	assert.Equal(t, 100, cfg.DBMaxOpenConns)
	assert.Equal(t, time.Hour, cfg.DBConnMaxLifetime)
	assert.Contains(t, cfg.AllowedOrigins, "http://localhost:3000")
}

func TestLoad_EnvOverrides(t *testing.T) {
	t.Setenv("ENV", "production")
	t.Setenv("PORT", "9090")
	t.Setenv("JWT_SECRET", "my-secret")
	t.Setenv("JWT_REFRESH_SECRET", "my-refresh-secret")
	t.Setenv("RATE_LIMIT", "100")
	t.Setenv("RATE_LIMIT_BURST", "50")
	t.Setenv("DB_MAX_IDLE_CONNS", "5")
	t.Setenv("DB_MAX_OPEN_CONNS", "50")
	t.Setenv("ACCESS_TOKEN_TTL", "30m")
	t.Setenv("REFRESH_TOKEN_TTL", "30d") // invalid duration
	t.Setenv("ALLOWED_ORIGINS", "https://example.com,https://api.example.com")

	cfg, err := config.Load()
	require.NoError(t, err)

	assert.Equal(t, "production", cfg.Env)
	assert.Equal(t, "9090", cfg.Port)
	assert.Equal(t, "my-secret", cfg.JWTSecret)
	assert.Equal(t, "my-refresh-secret", cfg.JWTRefreshSecret)
	assert.Equal(t, 100, cfg.RateLimit)
	assert.Equal(t, 50, cfg.RateLimitBurst)
	assert.Equal(t, 5, cfg.DBMaxIdleConns)
	assert.Equal(t, 50, cfg.DBMaxOpenConns)
	assert.Equal(t, 30*time.Minute, cfg.AccessTokenTTL)
	// invalid "30d" duration falls back to default 7 days
	assert.Equal(t, 7*24*time.Hour, cfg.RefreshTokenTTL)
	assert.Equal(t, []string{"https://example.com", "https://api.example.com"}, cfg.AllowedOrigins)
}

func TestLoad_AllowedOriginsTrimsSpaces(t *testing.T) {
	t.Setenv("ALLOWED_ORIGINS", "  http://a.com  ,  http://b.com  ")
	cfg, err := config.Load()
	require.NoError(t, err)
	assert.Equal(t, []string{"http://a.com", "http://b.com"}, cfg.AllowedOrigins)
}

func TestLoad_InvalidIntFallsToDefault(t *testing.T) {
	t.Setenv("RATE_LIMIT", "not-a-number")
	cfg, err := config.Load()
	require.NoError(t, err)
	assert.Equal(t, 60, cfg.RateLimit)
}

func TestLoad_DatabaseURLFromEnv(t *testing.T) {
	t.Setenv("DATABASE_URL", "postgres://user:pass@host:5432/mydb")
	cfg, err := config.Load()
	require.NoError(t, err)
	assert.Equal(t, "postgres://user:pass@host:5432/mydb", cfg.DatabaseURL)
}

func TestLoad_RedisURLFromEnv(t *testing.T) {
	t.Setenv("REDIS_URL", "redis://localhost:6379")
	cfg, err := config.Load()
	require.NoError(t, err)
	assert.Equal(t, "redis://localhost:6379", cfg.RedisURL)
}
