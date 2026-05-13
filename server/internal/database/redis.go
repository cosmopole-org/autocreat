package database

import (
	"context"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
	"go.uber.org/zap"
)

// NewRedisClient parses the Redis URL and returns a connected client.
// Returns nil, nil when redisURL is empty — Redis is treated as disabled, not an error.
func NewRedisClient(redisURL string, log *zap.Logger) (*redis.Client, error) {
	if redisURL == "" {
		log.Info("redis disabled (REDIS_URL not set)")
		return nil, nil
	}

	opts, err := redis.ParseURL(redisURL)
	if err != nil {
		return nil, fmt.Errorf("invalid redis URL: %w", err)
	}

	client := redis.NewClient(opts)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("redis ping failed: %w", err)
	}

	log.Info("redis connected", zap.String("addr", opts.Addr))
	return client, nil
}
