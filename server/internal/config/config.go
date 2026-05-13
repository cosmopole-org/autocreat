package config

import (
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/joho/godotenv"
)

// Config holds all application configuration loaded from environment variables.
type Config struct {
	Env              string
	Port             string
	DatabaseURL      string
	RedisURL         string
	JWTSecret        string
	JWTRefreshSecret string
	AllowedOrigins   []string
	AccessTokenTTL   time.Duration
	RefreshTokenTTL  time.Duration
	RateLimit        int
	RateLimitBurst   int

	// DB Pool
	DBMaxIdleConns    int
	DBMaxOpenConns    int
	DBConnMaxLifetime time.Duration
}

// Load reads configuration from environment variables, optionally loading a .env file first.
func Load() (*Config, error) {
	// Attempt to load .env file; ignore error if it doesn't exist (production uses real env vars).
	_ = godotenv.Load()

	cfg := &Config{
		Env:               getEnv("ENV", "development"),
		Port:              getEnv("PORT", "8080"),
		DatabaseURL:       getEnv("DATABASE_URL", "postgres://postgres:postgres@localhost:5432/autocreat?sslmode=disable"),
		RedisURL:          getEnv("REDIS_URL", ""),
		JWTSecret:         getEnv("JWT_SECRET", "change-me-in-production"),
		JWTRefreshSecret:  getEnv("JWT_REFRESH_SECRET", "change-me-refresh-in-production"),
		AccessTokenTTL:    getDurationEnv("ACCESS_TOKEN_TTL", 15*time.Minute),
		RefreshTokenTTL:   getDurationEnv("REFRESH_TOKEN_TTL", 7*24*time.Hour),
		RateLimit:         getIntEnv("RATE_LIMIT", 60),
		RateLimitBurst:    getIntEnv("RATE_LIMIT_BURST", 20),
		DBMaxIdleConns:    getIntEnv("DB_MAX_IDLE_CONNS", 10),
		DBMaxOpenConns:    getIntEnv("DB_MAX_OPEN_CONNS", 100),
		DBConnMaxLifetime: getDurationEnv("DB_CONN_MAX_LIFETIME", time.Hour),
	}

	origins := getEnv("ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:8080")
	cfg.AllowedOrigins = strings.Split(origins, ",")
	for i, o := range cfg.AllowedOrigins {
		cfg.AllowedOrigins[i] = strings.TrimSpace(o)
	}

	return cfg, nil
}

func getEnv(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}

func getIntEnv(key string, fallback int) int {
	if val := os.Getenv(key); val != "" {
		if n, err := strconv.Atoi(val); err == nil {
			return n
		}
	}
	return fallback
}

func getDurationEnv(key string, fallback time.Duration) time.Duration {
	if val := os.Getenv(key); val != "" {
		if d, err := time.ParseDuration(val); err == nil {
			return d
		}
	}
	return fallback
}
