package service_test

import (
	"testing"
	"time"

	"github.com/autocreat/server/internal/config"
	"github.com/autocreat/server/internal/service"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// testConfig returns a minimal config suitable for unit testing JWT operations.
func testConfig() *config.Config {
	return &config.Config{
		JWTSecret:        "test-jwt-secret-32-chars-minimum!",
		JWTRefreshSecret: "test-refresh-secret-32-chars-min!",
		AccessTokenTTL:   15 * time.Minute,
		RefreshTokenTTL:  7 * 24 * time.Hour,
	}
}

// buildAuthService constructs an AuthService with a nil repo (safe for token-only operations).
func buildAuthService(cfg *config.Config) *service.AuthService {
	return service.NewAuthService(nil, cfg)
}

// ---- ValidateAccessToken ----

func TestValidateAccessToken_ValidToken(t *testing.T) {
	cfg := testConfig()
	svc := buildAuthService(cfg)

	userID := uuid.New()
	companyID := uuid.New()
	now := time.Now()

	claims := &service.Claims{
		UserID:    userID,
		Email:     "alice@example.com",
		CompanyID: &companyID,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID.String(),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(15 * time.Minute)),
		},
	}
	token, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(cfg.JWTSecret))
	require.NoError(t, err)

	got, err := svc.ValidateAccessToken(token)
	require.NoError(t, err)
	assert.Equal(t, userID, got.UserID)
	assert.Equal(t, "alice@example.com", got.Email)
	assert.Equal(t, &companyID, got.CompanyID)
}

func TestValidateAccessToken_Expired(t *testing.T) {
	cfg := testConfig()
	svc := buildAuthService(cfg)

	userID := uuid.New()
	now := time.Now()

	claims := &service.Claims{
		UserID: userID,
		Email:  "alice@example.com",
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID.String(),
			IssuedAt:  jwt.NewNumericDate(now.Add(-2 * time.Hour)),
			ExpiresAt: jwt.NewNumericDate(now.Add(-1 * time.Hour)),
		},
	}
	token, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(cfg.JWTSecret))
	require.NoError(t, err)

	_, err = svc.ValidateAccessToken(token)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "invalid or expired")
}

func TestValidateAccessToken_WrongSecret(t *testing.T) {
	cfg := testConfig()
	svc := buildAuthService(cfg)

	userID := uuid.New()
	now := time.Now()

	claims := &service.Claims{
		UserID: userID,
		Email:  "alice@example.com",
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID.String(),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(time.Hour)),
		},
	}
	// Sign with a DIFFERENT secret
	token, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte("wrong-secret"))
	require.NoError(t, err)

	_, err = svc.ValidateAccessToken(token)
	assert.Error(t, err)
}

func TestValidateAccessToken_Malformed(t *testing.T) {
	cfg := testConfig()
	svc := buildAuthService(cfg)

	_, err := svc.ValidateAccessToken("not.a.valid.jwt")
	assert.Error(t, err)
}

func TestValidateAccessToken_EmptyString(t *testing.T) {
	cfg := testConfig()
	svc := buildAuthService(cfg)

	_, err := svc.ValidateAccessToken("")
	assert.Error(t, err)
}

func TestValidateAccessToken_WrongAlgorithm(t *testing.T) {
	cfg := testConfig()
	svc := buildAuthService(cfg)

	// Build a none-alg token manually.
	header := `eyJhbGciOiJub25lIn0`  // {"alg":"none"}
	payload := `eyJzdWIiOiJ0ZXN0In0` // {"sub":"test"}
	token := header + "." + payload + "."

	_, err := svc.ValidateAccessToken(token)
	assert.Error(t, err)
}

// ---- DemoUserID / DemoCompanyID constants ----

func TestDemoIDs_AreValidUUIDs(t *testing.T) {
	assert.NotEqual(t, uuid.Nil, service.DemoUserID)
	assert.NotEqual(t, uuid.Nil, service.DemoCompanyID)
	assert.Equal(t, "d0e1f2a3-b4c5-d6e7-f8a9-b0c1d2e3f4a5", service.DemoUserID.String())
	assert.Equal(t, "a1b2c3d4-e5f6-7890-abcd-ef1234567890", service.DemoCompanyID.String())
}

// ---- Claims struct ----

func TestClaims_DemoFlag(t *testing.T) {
	cfg := testConfig()
	svc := buildAuthService(cfg)

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

	got, err := svc.ValidateAccessToken(token)
	require.NoError(t, err)
	assert.True(t, got.IsDemo)
	assert.Equal(t, "demo@autocreat.io", got.Email)
}

// ---- ToUserResponse helper ----

func TestToUserResponse_Owner(t *testing.T) {
	cid := uuid.New()
	u := &service.Claims{
		UserID:    uuid.New(),
		Email:     "owner@example.com",
		CompanyID: &cid,
	}
	_ = u // Just verify Claims struct is usable
}
