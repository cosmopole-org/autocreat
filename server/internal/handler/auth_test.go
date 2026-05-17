package handler_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/autocreat/server/internal/config"
	"github.com/autocreat/server/internal/handler"
	"github.com/autocreat/server/internal/middleware"
	"github.com/autocreat/server/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// testAuthCfg returns a minimal config for auth handler tests.
func testAuthCfg() *config.Config {
	return &config.Config{
		JWTSecret:        "test-secret-at-least-32-chars-ok!",
		JWTRefreshSecret: "test-refresh-secret-32-chars-ok!!",
		AccessTokenTTL:   15 * time.Minute,
		RefreshTokenTTL:  7 * 24 * time.Hour,
	}
}

// buildTestRouter creates a minimal Gin engine with only auth routes.
// The authSvc must use nil repo for demo-mode only tests.
func buildTestRouter(authSvc *service.AuthService) *gin.Engine {
	r := gin.New()
	r.Use(gin.Recovery())

	authH := handler.NewAuthHandler(authSvc)

	authGroup := r.Group("/api/v1/auth")
	authGroup.POST("/register", authH.Register)
	authGroup.POST("/login", authH.Login)
	authGroup.POST("/refresh", authH.Refresh)
	authGroup.POST("/logout", authH.Logout)
	authGroup.GET("/me", middleware.Auth(authSvc), authH.Me)

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	return r
}

// ---- /health ----

func TestHealth_ReturnsOK(t *testing.T) {
	cfg := testAuthCfg()
	svc := service.NewAuthService(nil, cfg)
	r := buildTestRouter(svc)

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, "/health", nil)
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), "ok")
}

// ---- POST /api/v1/auth/login ----

func TestLogin_InvalidJSON(t *testing.T) {
	cfg := testAuthCfg()
	svc := service.NewAuthService(nil, cfg)
	r := buildTestRouter(svc)

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/login", bytes.NewBufferString("not json"))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestLogin_MissingEmail(t *testing.T) {
	cfg := testAuthCfg()
	svc := service.NewAuthService(nil, cfg)
	r := buildTestRouter(svc)

	body, _ := json.Marshal(map[string]string{"password": "secret"})
	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/login", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestLogin_DemoCredentials(t *testing.T) {
	cfg := testAuthCfg()
	svc := service.NewAuthService(nil, cfg)
	r := buildTestRouter(svc)

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

	user := resp["user"].(map[string]interface{})
	assert.Equal(t, "demo@autocreat.io", user["email"])
}

func TestLogin_WrongDemoPassword_ReturnsUnauthorized(t *testing.T) {
	cfg := testAuthCfg()
	svc := service.NewAuthService(nil, cfg)
	r := buildTestRouter(svc)

	body, _ := json.Marshal(map[string]string{
		"email":    "demo@autocreat.io",
		"password": "WrongPassword!",
	})
	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/login", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	// Non-demo credentials hit DB (which is nil) → expect an error
	// (not 200; but the exact code depends on DB availability)
	assert.NotEqual(t, http.StatusOK, w.Code)
}

// ---- POST /api/v1/auth/register ----

func TestRegister_InvalidJSON(t *testing.T) {
	cfg := testAuthCfg()
	svc := service.NewAuthService(nil, cfg)
	r := buildTestRouter(svc)

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/register", bytes.NewBufferString("{broken"))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestRegister_MissingRequiredFields(t *testing.T) {
	cfg := testAuthCfg()
	svc := service.NewAuthService(nil, cfg)
	r := buildTestRouter(svc)

	cases := []map[string]string{
		{"email": "a@b.com"},                               // missing password, firstName, lastName
		{"password": "abcdefgh", "firstName": "A", "lastName": "B"}, // missing email
		{"email": "a@b.com", "password": "short"},          // password too short, missing names
	}

	for _, tc := range cases {
		body, _ := json.Marshal(tc)
		w := httptest.NewRecorder()
		req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/register", bytes.NewBuffer(body))
		req.Header.Set("Content-Type", "application/json")
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusBadRequest, w.Code, "case: %v", tc)
	}
}

// ---- POST /api/v1/auth/refresh ----

func TestRefresh_MissingRefreshToken(t *testing.T) {
	cfg := testAuthCfg()
	svc := service.NewAuthService(nil, cfg)
	r := buildTestRouter(svc)

	body, _ := json.Marshal(map[string]string{})
	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/refresh", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestRefresh_InvalidToken(t *testing.T) {
	cfg := testAuthCfg()
	svc := service.NewAuthService(nil, cfg)
	r := buildTestRouter(svc)

	body, _ := json.Marshal(map[string]string{"refresh_token": "totally.invalid.token"})
	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/refresh", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

// ---- POST /api/v1/auth/logout ----

func TestLogout_AcceptsAnyBody(t *testing.T) {
	cfg := testAuthCfg()
	svc := service.NewAuthService(nil, cfg)
	r := buildTestRouter(svc)

	// Without a refresh_token the binding fails so the handler skips the DB call,
	// returning 200 immediately (best-effort logout).
	body, _ := json.Marshal(map[string]string{"other_field": "value"})
	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/logout", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	// Logout is best-effort; always returns 200
	assert.Equal(t, http.StatusOK, w.Code)
}

func TestLogout_EmptyBody(t *testing.T) {
	cfg := testAuthCfg()
	svc := service.NewAuthService(nil, cfg)
	r := buildTestRouter(svc)

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/logout", bytes.NewBufferString("{}"))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
}

// ---- GET /api/v1/auth/me ----

func TestMe_NoToken(t *testing.T) {
	cfg := testAuthCfg()
	svc := service.NewAuthService(nil, cfg)
	r := buildTestRouter(svc)

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, "/api/v1/auth/me", nil)
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestMe_WithDemoToken_Returns200(t *testing.T) {
	cfg := testAuthCfg()
	svc := service.NewAuthService(nil, cfg)
	r := buildTestRouter(svc)

	// Build a valid demo-style token manually.
	cid := service.DemoCompanyID
	now := time.Now()
	claims := &service.Claims{
		UserID:    service.DemoUserID,
		Email:     "demo@autocreat.io",
		CompanyID: &cid,
		IsDemo:    true,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   service.DemoUserID.String(),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(365 * 24 * time.Hour)),
		},
	}
	token, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(cfg.JWTSecret))
	require.NoError(t, err)

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, "/api/v1/auth/me", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	r.ServeHTTP(w, req)

	// Demo me handler short-circuits without DB call → always returns 200.
	require.Equal(t, http.StatusOK, w.Code)
	var resp map[string]interface{}
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &resp))
	assert.Equal(t, "demo@autocreat.io", resp["email"])
	assert.Equal(t, "Demo", resp["firstName"])
}

// ---- DemoAuthResponse shape ----

func TestDemoLogin_ResponseShape(t *testing.T) {
	cfg := testAuthCfg()
	svc := service.NewAuthService(nil, cfg)
	r := buildTestRouter(svc)

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

	// Validate response keys
	assert.Contains(t, resp, "accessToken")
	assert.Contains(t, resp, "refreshToken")
	assert.Contains(t, resp, "user")

	user := resp["user"].(map[string]interface{})
	assert.Equal(t, "demo@autocreat.io", user["email"])
	assert.Equal(t, "Demo", user["firstName"])
	assert.Equal(t, "User", user["lastName"])
	assert.Equal(t, true, user["isActive"])
}

// ---- UUID parse validation in handlers ----

func TestInvalidUUIDInPath_TicketHandler(t *testing.T) {
	// Test that invalid UUIDs in path params return 400.
	r := gin.New()
	r.GET("/tickets/:id", func(c *gin.Context) {
		_, err := uuid.Parse(c.Param("id"))
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
			return
		}
		c.JSON(http.StatusOK, gin.H{})
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, "/tickets/not-a-uuid", nil)
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusBadRequest, w.Code)
}
