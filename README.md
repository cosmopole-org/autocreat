# AutoCreat — Organizational System Builder

A full-featured, responsive organizational management platform that helps companies digitize and automate their internal processes through visual workflow design, custom forms, role-based access control, and real-time collaboration.

## Overview

AutoCreat enables company owners to:
- Design multi-step organizational workflows using a visual graph editor
- Build custom forms with rich field types for each workflow step
- Define data models as backbone entities persisted through flow executions
- Create role-based access control with granular permissions
- Generate letters/documents from form data using dynamic templates
- Communicate via an integrated ticket/messaging system
- Manage users, roles, and permissions with full audit trails

## Architecture

```
autocreat/
├── client/          # Flutter app (iOS, Android, Web, Desktop)
├── server/          # Go REST API (standalone + Vercel serverless)
└── .github/
    └── workflows/   # CI/CD pipelines
```

## Tech Stack

### Client (Flutter)
| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `go_router` | Navigation |
| `dio` | HTTP client |
| `flutter_quill` | Rich text letter editor |
| `flutter_animate` | Animations |
| `fl_chart` | Dashboard charts |
| `google_fonts` | Typography (Inter) |
| `flutter_secure_storage` | JWT token storage |

### Server (Go)
| Package | Purpose |
|---------|---------|
| `gin` | HTTP framework |
| `gorm` + `driver/postgres` | ORM + PostgreSQL |
| `golang-jwt/jwt/v5` | Authentication |
| `redis/go-redis` | Caching + sessions |
| `gorilla/websocket` | Real-time notifications |
| `uber-go/zap` | Structured logging |

### Database
- PostgreSQL 16 (primary store)
- Redis 7 (sessions, caching, pub/sub)

## Getting Started

### Prerequisites
- Flutter 3.24+ (`flutter --version`)
- Go 1.23+ (`go version`)
- PostgreSQL 16+
- Redis 7+

### Server Setup

```bash
cd server
cp .env.example .env
# Edit .env with your database credentials

# Install dependencies
go mod download

# Run database migrations
make migrate

# Start the server
make run
# → Server running at http://localhost:8080
```

### Client Setup

```bash
cd client
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Run on web
flutter run -d chrome

# Run on mobile
flutter run

# Build for Android
flutter build apk --release

# Build for web
flutter build web --release --base-href /autocreat/
```

## Deployment

### Vercel Serverless (Go API)
```bash
cd server
vercel deploy
```

The `vercel.json` is already configured. Set these environment variables in Vercel:
- `DATABASE_URL` — PostgreSQL connection string
- `JWT_SECRET` — JWT signing secret (min 32 chars)
- `JWT_REFRESH_SECRET` — Refresh token secret

### GitHub Pages (Flutter Web)
Push to `main` branch — the GitHub Actions workflow automatically:
1. Builds Flutter web with `--base-href /autocreat/`
2. Deploys to GitHub Pages at `https://<org>.github.io/autocreat/`

### Docker (Standalone Server)
```bash
cd server
docker-compose up -d
```

## CI/CD Pipelines

| Workflow | Trigger | Output |
|----------|---------|--------|
| `flutter-web.yml` | Push to main | Deploy to GitHub Pages |
| `flutter-android.yml` | Push to main | APK artifact + GitHub Release |
| `go-server.yml` | Push to main | Docker image → ghcr.io |

## Features

### Flow Graph Editor
- Drag-and-drop visual canvas for designing organizational workflows
- Node types: START, STEP, DECISION, END
- Connect nodes with conditional edges
- Assign roles and forms to each step node
- Multi-branch flows with condition-based routing
- Auto-layout algorithm for clean graph presentation

### Form Builder
- 15+ field types: Text, Number, Dropdown, Multi-select, Checkbox, Radio, Date, File, Image, Color, Switch, Table, Rating, Signature, Rich Text
- Model binding: link form fields to data model properties
- Validation rules: required, min/max length, pattern, custom
- Drag-and-drop field reordering

### Data Model Builder
- Define typed data schemas (String, Int, Float, Bool, Date, File, Reference)
- Model entities auto-created when form steps are completed
- Cross-reference models for relational data within flows

### Letter Template Editor
- Notion-like rich text editor (flutter_quill)
- Dynamic variables bound to form/model data
- Auto-generate letters when flow steps complete
- PDF export support

### Role-Based Access Control
- Define custom roles with granular resource permissions
- Assign roles to flow nodes (which role handles which step)
- Flow start assignments: which roles can initiate which flows
- Restriction rules: what data roles can read/write/delete

### Ticket & Messaging
- Create tickets referencing flow instances
- Assign tickets to specific roles
- Threaded message conversations
- Real-time notifications via WebSocket

## API Documentation

Base URL: `http://localhost:8080/api/v1`

### Authentication
```http
POST /auth/register     Register as company owner
POST /auth/login        Login + receive JWT pair
POST /auth/refresh      Refresh access token
POST /auth/logout       Invalidate session
GET  /auth/me           Get current user
```

### Companies
```http
GET    /companies           List my companies
POST   /companies           Create company
GET    /companies/:id       Get company details
PUT    /companies/:id       Update company
DELETE /companies/:id       Delete company
```

### Flows, Forms, Models, Roles, Users, Letters, Tickets
All entities are scoped under `/companies/:cid/` and follow standard CRUD patterns.

## Environment Variables

```env
# Required
DATABASE_URL=postgres://user:pass@host:5432/autocreat?sslmode=disable
JWT_SECRET=at-least-32-character-secret-key
JWT_REFRESH_SECRET=at-least-32-character-refresh-key

# Optional (with defaults)
REDIS_URL=redis://localhost:6379
PORT=8080
ENV=development
ALLOWED_ORIGINS=http://localhost:3000
LOG_LEVEL=info
MAX_CONNECTIONS=100
```

## License

MIT License — see [LICENSE](LICENSE) for details.
