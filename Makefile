.PHONY: all server client build-android build-web deploy-web help

# Default target
all: help

## Server targets
server-run:
	cd server && go run ./cmd/server

server-build:
	cd server && CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o autocreat-server ./cmd/server

server-test:
	cd server && TEST_DATABASE_URL=postgres://postgres:2851332@localhost:5432/autocreat_test?sslmode=disable go test -v -race -cover ./...

server-lint:
	cd server && golangci-lint run

server-migrate:
	cd server && go run ./cmd/server -migrate

server-docker-build:
	docker build -t autocreat-server:latest server/

server-docker-run:
	docker-compose -f server/docker-compose.yml up -d

server-docker-stop:
	docker-compose -f server/docker-compose.yml down

## Client targets
client-deps:
	cd client && flutter pub get

client-codegen:
	cd client && flutter pub run build_runner build --delete-conflicting-outputs

client-run-web:
	cd client && NO_PROXY=localhost,127.0.0.1 no_proxy=localhost,127.0.0.1 flutter run -d chrome --web-port 8080

client-run-web-server:
	cd client && NO_PROXY=localhost,127.0.0.1 no_proxy=localhost,127.0.0.1 flutter run -d web-server --web-port 8080

client-run-mobile:
	cd client && flutter run

client-build-android:
	cd client && flutter build apk --release --split-per-abi

client-build-web:
	cd client && flutter build web --release --base-href /autocreat/

client-analyze:
	cd client && flutter analyze

client-test:
	cd client && flutter test

## Combined targets
setup:
	@echo "Setting up AutoCreat development environment..."
	cd server && go mod download
	cd client && flutter pub get
	cd client && flutter pub run build_runner build --delete-conflicting-outputs
	@echo "✓ Setup complete!"

dev:
	@echo "Starting development servers..."
	$(MAKE) server-docker-run
	@sleep 2
	$(MAKE) server-run &
	$(MAKE) client-run-web-server

help:
	@echo "AutoCreat — Build Targets"
	@echo ""
	@echo "Server:"
	@echo "  make server-run          Start Go server (development)"
	@echo "  make server-build        Build Go server binary"
	@echo "  make server-test         Run Go tests"
	@echo "  make server-docker-run   Start PostgreSQL + Redis via Docker"
	@echo ""
	@echo "Client:"
	@echo "  make client-deps         Install Flutter dependencies"
	@echo "  make client-codegen      Run code generation (freezed, riverpod)"
	@echo "  make client-run-web      Run Flutter web in Chrome (sets NO_PROXY)"
	@echo "  make client-run-web-server Run Flutter web-server (sets NO_PROXY)"
	@echo "  make client-build-android Build Android APK"
	@echo "  make client-build-web    Build Flutter web bundle"
	@echo ""
	@echo "Combined:"
	@echo "  make setup               Install all dependencies"
	@echo "  make dev                 Start full dev environment"
