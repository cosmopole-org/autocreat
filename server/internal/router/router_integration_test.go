package router

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/autocreat/server/internal/config"
	"github.com/autocreat/server/internal/handler"
	"github.com/autocreat/server/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
)

func init() {
	gin.SetMode(gin.TestMode)
}

// buildMinimalRouter creates a router with only non-DB routes for integration testing.
func buildMinimalRouter() (*gin.Engine, *service.AuthService) {
	cfg := &config.Config{
		JWTSecret:        "integration-test-secret-32-chars!",
		JWTRefreshSecret: "integration-refresh-secret-32-ok!",
		AccessTokenTTL:   15 * time.Minute,
		RefreshTokenTTL:  7 * 24 * time.Hour,
		RateLimit:        1000,
		RateLimitBurst:   1000,
		AllowedOrigins:   []string{"http://localhost:3000"},
	}
	log, _ := zap.NewDevelopment()
	authSvc := service.NewAuthService(nil, cfg)
	hub := service.NewHub(log)
	authH := handler.NewAuthHandler(authSvc)
	realtimeH := handler.NewRealtimeHandler(hub, log)

	return New(Options{
		AuthHandler:     authH,
		CompanyHandler:  nil,
		RoleHandler:     nil,
		UserHandler:     nil,
		FlowHandler:     nil,
		FormHandler:     nil,
		ModelHandler:    nil,
		LetterHandler:   nil,
		TicketHandler:   nil,
		StatsHandler:    nil,
		RealtimeHandler: realtimeH,
		AuthService:     authSvc,
		AllowedOrigins:  cfg.AllowedOrigins,
		RateLimitRPS:    cfg.RateLimit,
		RateLimitBurst:  cfg.RateLimitBurst,
		Log:             log,
	}), authSvc
}

// ---- Health endpoint ----

func TestRouter_Health(t *testing.T) {
	r, _ := buildMinimalRouter()

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, "/health", nil)
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	var body map[string]interface{}
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &body))
	assert.Equal(t, "ok", body["status"])
	assert.Equal(t, "autocreat", body["service"])
}

// ---- Demo login flow ----

func TestRouter_DemoLogin(t *testing.T) {
	r, _ := buildMinimalRouter()

	body, _ := json.Marshal(map[string]string{
		"email":    "demo@autocreat.io",
		"password": "Demo123!",
	})
	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/login", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
	var resp map[string]interface{}
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &resp))
	assert.NotEmpty(t, resp["accessToken"])
	assert.NotEmpty(t, resp["refreshToken"])
}

// ---- Auth required for protected endpoints ----

func TestRouter_ProtectedEndpoints_RequireAuth(t *testing.T) {
	r, _ := buildMinimalRouter()

	protectedGET := []string{
		"/api/v1/companies",
		"/api/v1/roles",
		"/api/v1/users",
		"/api/v1/flows",
		"/api/v1/forms",
		"/api/v1/models",
		"/api/v1/letters",
		"/api/v1/tickets",
		"/api/v1/stats",
	}

	for _, path := range protectedGET {
		w := httptest.NewRecorder()
		req, _ := http.NewRequest(http.MethodGet, path, nil)
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusUnauthorized, w.Code, "path: %s should require auth", path)
	}
}

// ---- CORS headers on preflight ----

func TestRouter_CORS_PreflightResponse(t *testing.T) {
	r, _ := buildMinimalRouter()

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodOptions, "/api/v1/auth/login", nil)
	req.Header.Set("Origin", "http://localhost:3000")
	req.Header.Set("Access-Control-Request-Method", "POST")
	req.Header.Set("Access-Control-Request-Headers", "Content-Type,Authorization")
	r.ServeHTTP(w, req)

	assert.Equal(t, "http://localhost:3000", w.Header().Get("Access-Control-Allow-Origin"))
}

// ---- Rate limiting ----

func TestRouter_RateLimit(t *testing.T) {
	cfg := &config.Config{
		JWTSecret:        "integration-test-secret-32-chars!",
		JWTRefreshSecret: "integration-refresh-secret-32-ok!",
		AccessTokenTTL:   15 * time.Minute,
		RateLimit:        0,    // 0 tokens/sec refill
		RateLimitBurst:   1,    // only 1 burst token
		AllowedOrigins:   []string{"*"},
	}
	log, _ := zap.NewDevelopment()
	authSvc := service.NewAuthService(nil, cfg)
	authH := handler.NewAuthHandler(authSvc)

	r := New(Options{
		AuthHandler:    authH,
		AuthService:    authSvc,
		AllowedOrigins: cfg.AllowedOrigins,
		RateLimitRPS:   cfg.RateLimit,
		RateLimitBurst: cfg.RateLimitBurst,
		Log:            log,
	})

	// First request uses the burst token.
	w1 := httptest.NewRecorder()
	req1, _ := http.NewRequest(http.MethodGet, "/health", nil)
	req1.RemoteAddr = "5.5.5.5:1234"
	r.ServeHTTP(w1, req1)
	assert.Equal(t, http.StatusOK, w1.Code)

	// Second request should be rate-limited.
	w2 := httptest.NewRecorder()
	req2, _ := http.NewRequest(http.MethodGet, "/health", nil)
	req2.RemoteAddr = "5.5.5.5:1234"
	r.ServeHTTP(w2, req2)
	assert.Equal(t, http.StatusTooManyRequests, w2.Code)
}

// ---- Invalid auth register ----

func TestRouter_Register_ValidationErrors(t *testing.T) {
	r, _ := buildMinimalRouter()

	cases := []struct {
		name string
		body map[string]interface{}
	}{
		{"empty body", map[string]interface{}{}},
		{"invalid email", map[string]interface{}{
			"email": "not-an-email", "password": "password123", "firstName": "A", "lastName": "B",
		}},
		{"short password", map[string]interface{}{
			"email": "a@b.com", "password": "short", "firstName": "A", "lastName": "B",
		}},
	}

	for _, tc := range cases {
		body, _ := json.Marshal(tc.body)
		w := httptest.NewRecorder()
		req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/register", bytes.NewBuffer(body))
		req.Header.Set("Content-Type", "application/json")
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusBadRequest, w.Code, "case: %s", tc.name)
	}
}

// ---- Demo mode via JWT ----

func TestRouter_DemoMode_InterceptsRequests(t *testing.T) {
	r, authSvc := buildMinimalRouter()

	// Get demo token by logging in.
	body, _ := json.Marshal(map[string]string{
		"email":    "demo@autocreat.io",
		"password": "Demo123!",
	})
	loginW := httptest.NewRecorder()
	loginReq, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/login", bytes.NewBuffer(body))
	loginReq.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(loginW, loginReq)
	require.Equal(t, http.StatusOK, loginW.Code)

	var loginResp map[string]interface{}
	require.NoError(t, json.Unmarshal(loginW.Body.Bytes(), &loginResp))
	accessToken := loginResp["accessToken"].(string)
	_ = authSvc // used implicitly

	// Demo token can access /me but will get 404 (no DB).
	meW := httptest.NewRecorder()
	meReq, _ := http.NewRequest(http.MethodGet, "/api/v1/auth/me", nil)
	meReq.Header.Set("Authorization", "Bearer "+accessToken)
	r.ServeHTTP(meW, meReq)
	// Demo mode intercepts before /auth/me can hit the DB.
	// The demo handler returns demo data or passes through.
	assert.NotEqual(t, http.StatusUnauthorized, meW.Code)
}

// ---- Refresh with invalid token ----

func TestRouter_Refresh_InvalidToken(t *testing.T) {
	r, _ := buildMinimalRouter()

	body, _ := json.Marshal(map[string]string{"refresh_token": "invalid.token.here"})
	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/refresh", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

// ---- Logout always succeeds ----

func TestRouter_Logout_AlwaysOK(t *testing.T) {
	r, _ := buildMinimalRouter()

	// Empty body: binding fails → handler skips DB call and returns 200.
	body, _ := json.Marshal(map[string]string{})
	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/logout", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
}

// ---- Token validation in protected routes ----

func TestRouter_ValidToken_PassesAuth(t *testing.T) {
	r, authSvc := buildMinimalRouter()
	_ = authSvc

	// Build a valid non-demo token.
	cfg := &config.Config{
		JWTSecret:      "integration-test-secret-32-chars!",
		AccessTokenTTL: 15 * time.Minute,
	}
	userID := uuid.New()
	cid := uuid.New()
	now := time.Now()
	claims := &service.Claims{
		UserID:    userID,
		Email:     "user@test.com",
		CompanyID: &cid,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID.String(),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(cfg.AccessTokenTTL)),
		},
	}
	token, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(cfg.JWTSecret))
	require.NoError(t, err)

	// /api/v1/auth/me will fail DB lookup but should pass auth middleware.
	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, "/api/v1/auth/me", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	r.ServeHTTP(w, req)

	// Should not be 401 (auth passed); may be 404 due to nil DB.
	assert.NotEqual(t, http.StatusUnauthorized, w.Code)
}
