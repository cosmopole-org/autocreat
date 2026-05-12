.PHONY: run build test lint tidy docker-up docker-down migrate

# Run the development server
run:
	go run ./cmd/server

# Build the production binary
build:
	CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o bin/server ./cmd/server

# Run tests
test:
	go test ./... -v -race -count=1

# Lint
lint:
	golangci-lint run ./...

# Tidy dependencies
tidy:
	go mod tidy

# Start Docker Compose stack
docker-up:
	docker compose up -d --build

# Stop Docker Compose stack
docker-down:
	docker compose down

# Run only postgres + redis locally (for local dev without containerizing the app)
deps-up:
	docker compose up -d postgres redis

deps-down:
	docker compose stop postgres redis

# Format
fmt:
	gofmt -w .

# Generate go.sum
gosum:
	go mod download

.DEFAULT_GOAL := run
