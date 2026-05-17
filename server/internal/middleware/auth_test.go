package middleware_test

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/autocreat/server/internal/config"
	"github.com/autocreat/server/internal/middleware"
	"github.com/autocreat/server/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func init() {
	gin.SetMode(gin.TestMode)
}

func testAuthService() *service.AuthService {
	cfg := &config.Config{
		JWTSecret:        "test-secret-that-is-long-enough!",
		JWTRefreshSecret: "test-refresh-secret-long-enough!",
		AccessTokenTTL:   15 * time.Minute,
		RefreshTokenTTL:  7 * 24 * time.Hour,
	}
	return service.NewAuthService(nil, cfg)
}

func buildValidToken(t *testing.T, svc *service.AuthService, cfg *config.Config) string {
	t.Helper()
	userID := uuid.New()
	cid := uuid.New()
	now := time.Now()
	claims := &service.Claims{
		UserID:    userID,
		Email:     "test@example.com",
		CompanyID: &cid,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID.String(),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(15 * time.Minute)),
		},
	}
	token, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(cfg.JWTSecret))
	require.NoError(t, err)
	return token
}

func newGinWithAuth(svc *service.AuthService) *gin.Engine {
	r := gin.New()
	r.Use(middleware.Auth(svc))
	r.GET("/protected", func(c *gin.Context) {
		userID, exists := c.Get(middleware.ContextUserID)
		if !exists {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "no userID"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"userID": userID.(uuid.UUID).String()})
	})
	return r
}

func TestAuth_MissingAuthorizationHeader(t *testing.T) {
	svc := testAuthService()
	r := newGinWithAuth(svc)

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, "/protected", nil)
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestAuth_InvalidFormat_NoBearer(t *testing.T) {
	svc := testAuthService()
	r := newGinWithAuth(svc)

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, "/protected", nil)
	req.Header.Set("Authorization", "Token abc123")
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestAuth_InvalidToken(t *testing.T) {
	svc := testAuthService()
	r := newGinWithAuth(svc)

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, "/protected", nil)
	req.Header.Set("Authorization", "Bearer not.a.real.token")
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestAuth_ValidToken(t *testing.T) {
	cfg := &config.Config{
		JWTSecret:        "test-secret-that-is-long-enough!",
		JWTRefreshSecret: "test-refresh-secret-long-enough!",
		AccessTokenTTL:   15 * time.Minute,
	}
	svc := service.NewAuthService(nil, cfg)
	r := newGinWithAuth(svc)

	token := buildValidToken(t, svc, cfg)

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, "/protected", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
}

func TestAuth_BearerCaseInsensitive(t *testing.T) {
	cfg := &config.Config{
		JWTSecret:       "test-secret-that-is-long-enough!",
		AccessTokenTTL:  15 * time.Minute,
	}
	svc := service.NewAuthService(nil, cfg)
	r := newGinWithAuth(svc)

	token := buildValidToken(t, svc, cfg)

	for _, prefix := range []string{"Bearer", "bearer", "BEARER"} {
		w := httptest.NewRecorder()
		req, _ := http.NewRequest(http.MethodGet, "/protected", nil)
		req.Header.Set("Authorization", prefix+" "+token)
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusOK, w.Code, "prefix: %s", prefix)
	}
}

func TestAuth_SetsContextValues(t *testing.T) {
	cfg := &config.Config{
		JWTSecret:      "test-secret-that-is-long-enough!",
		AccessTokenTTL: 15 * time.Minute,
	}
	svc := service.NewAuthService(nil, cfg)

	userID := uuid.New()
	cid := uuid.New()
	now := time.Now()
	claims := &service.Claims{
		UserID:    userID,
		Email:     "ctx@example.com",
		CompanyID: &cid,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID.String(),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(15 * time.Minute)),
		},
	}
	token, _ := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(cfg.JWTSecret))

	var capturedUserID uuid.UUID
	var capturedEmail string
	var capturedCompanyID uuid.UUID

	r := gin.New()
	r.Use(middleware.Auth(svc))
	r.GET("/check", func(c *gin.Context) {
		capturedUserID = c.MustGet(middleware.ContextUserID).(uuid.UUID)
		capturedEmail = c.MustGet(middleware.ContextEmail).(string)
		capturedCompanyID = c.MustGet(middleware.ContextCompanyID).(uuid.UUID)
		c.JSON(http.StatusOK, gin.H{})
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, "/check", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Equal(t, userID, capturedUserID)
	assert.Equal(t, "ctx@example.com", capturedEmail)
	assert.Equal(t, cid, capturedCompanyID)
}

func TestAuth_ExpiredToken(t *testing.T) {
	cfg := &config.Config{
		JWTSecret:      "test-secret-that-is-long-enough!",
		AccessTokenTTL: 15 * time.Minute,
	}
	svc := service.NewAuthService(nil, cfg)
	r := newGinWithAuth(svc)

	userID := uuid.New()
	now := time.Now()
	claims := &service.Claims{
		UserID: userID,
		Email:  "old@example.com",
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID.String(),
			IssuedAt:  jwt.NewNumericDate(now.Add(-2 * time.Hour)),
			ExpiresAt: jwt.NewNumericDate(now.Add(-1 * time.Hour)), // already expired
		},
	}
	token, _ := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(cfg.JWTSecret))

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, "/protected", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestAuth_DemoTokenSetsIsDemoFlag(t *testing.T) {
	cfg := &config.Config{
		JWTSecret:      "test-secret-that-is-long-enough!",
		AccessTokenTTL: 15 * time.Minute,
	}
	svc := service.NewAuthService(nil, cfg)

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
	token, _ := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(cfg.JWTSecret))

	var capturedIsDemo interface{}
	r := gin.New()
	r.Use(middleware.Auth(svc))
	r.GET("/demo-check", func(c *gin.Context) {
		capturedIsDemo, _ = c.Get(middleware.ContextIsDemo)
		c.JSON(http.StatusOK, gin.H{})
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, "/demo-check", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Equal(t, true, capturedIsDemo)
}
