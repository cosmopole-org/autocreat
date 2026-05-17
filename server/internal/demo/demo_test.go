package demo_test

import (
	"encoding/json"
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

// buildDemoRouter builds a minimal router that applies Auth + DemoMode middleware.
func buildDemoRouter() (*gin.Engine, string) {
	cfg := &config.Config{
		JWTSecret:      "demo-test-secret-that-is-32-chars!",
		AccessTokenTTL: 365 * 24 * time.Hour,
	}
	authSvc := service.NewAuthService(nil, cfg)

	// Build a demo JWT
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
	demoToken, _ := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(cfg.JWTSecret))

	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(middleware.Auth(authSvc))
	r.Use(middleware.DemoMode())

	// Register routes that the demo handler should intercept.
	routes := []string{
		"/api/v1/companies",
		"/api/v1/companies/:id",
		"/api/v1/companies/:id/members",
		"/api/v1/stats",
		"/api/v1/roles",
		"/api/v1/roles/:id",
		"/api/v1/users",
		"/api/v1/users/:id",
		"/api/v1/flows",
		"/api/v1/flows/:id",
		"/api/v1/forms",
		"/api/v1/forms/:id",
		"/api/v1/letters",
		"/api/v1/letters/:id",
		"/api/v1/models",
		"/api/v1/models/:id",
		"/api/v1/models/:id/entities",
		"/api/v1/tickets",
		"/api/v1/tickets/:id",
		"/api/v1/instances",
		"/api/v1/instances/:id",
		"/api/v1/instances/my-tasks",
	}
	for _, route := range routes {
		r.GET(route, func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"real": true})
		})
		r.POST(route, func(c *gin.Context) {
			c.JSON(http.StatusCreated, gin.H{"real": true})
		})
		r.PUT(route, func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"real": true})
		})
		r.DELETE(route, func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"real": true})
		})
	}

	return r, demoToken
}

func demoGET(t *testing.T, r *gin.Engine, token, path string) *httptest.ResponseRecorder {
	t.Helper()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, path, nil)
	req.Header.Set("Authorization", "Bearer "+token)
	r.ServeHTTP(w, req)
	return w
}

func demoPOST(t *testing.T, r *gin.Engine, token, path string) *httptest.ResponseRecorder {
	t.Helper()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodPost, path, nil)
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)
	return w
}

// ---- Write operations are blocked ----

func TestDemoMode_BlocksWriteOperations(t *testing.T) {
	r, token := buildDemoRouter()

	for _, method := range []string{"POST", "PUT", "DELETE"} {
		w := httptest.NewRecorder()
		req, _ := http.NewRequest(method, "/api/v1/flows", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "write %s should be intercepted", method)
		var body map[string]interface{}
		require.NoError(t, json.Unmarshal(w.Body.Bytes(), &body))
		assert.Contains(t, body["message"], "Demo mode")
	}
}

// ---- GET routes are intercepted ----

func TestDemoMode_Companies(t *testing.T) {
	r, token := buildDemoRouter()
	w := demoGET(t, r, token, "/api/v1/companies")
	assert.Equal(t, http.StatusOK, w.Code)
	// Should NOT return {"real": true}
	assert.NotContains(t, w.Body.String(), `"real":true`)
}

func TestDemoMode_CompanyByID(t *testing.T) {
	r, token := buildDemoRouter()
	w := demoGET(t, r, token, "/api/v1/companies/"+service.DemoCompanyID.String())
	assert.Equal(t, http.StatusOK, w.Code)
	assert.NotContains(t, w.Body.String(), `"real":true`)
}

func TestDemoMode_Stats(t *testing.T) {
	r, token := buildDemoRouter()
	w := demoGET(t, r, token, "/api/v1/stats")
	assert.Equal(t, http.StatusOK, w.Code)
	assert.NotContains(t, w.Body.String(), `"real":true`)
}

func TestDemoMode_Roles(t *testing.T) {
	r, token := buildDemoRouter()
	w := demoGET(t, r, token, "/api/v1/roles")
	assert.Equal(t, http.StatusOK, w.Code)
	assert.NotContains(t, w.Body.String(), `"real":true`)
}

func TestDemoMode_Users(t *testing.T) {
	r, token := buildDemoRouter()
	w := demoGET(t, r, token, "/api/v1/users")
	assert.Equal(t, http.StatusOK, w.Code)
	assert.NotContains(t, w.Body.String(), `"real":true`)
}

func TestDemoMode_Flows(t *testing.T) {
	r, token := buildDemoRouter()
	w := demoGET(t, r, token, "/api/v1/flows")
	assert.Equal(t, http.StatusOK, w.Code)
	assert.NotContains(t, w.Body.String(), `"real":true`)
}

func TestDemoMode_Forms(t *testing.T) {
	r, token := buildDemoRouter()
	w := demoGET(t, r, token, "/api/v1/forms")
	assert.Equal(t, http.StatusOK, w.Code)
	assert.NotContains(t, w.Body.String(), `"real":true`)
}

func TestDemoMode_Letters(t *testing.T) {
	r, token := buildDemoRouter()
	w := demoGET(t, r, token, "/api/v1/letters")
	assert.Equal(t, http.StatusOK, w.Code)
	assert.NotContains(t, w.Body.String(), `"real":true`)
}

func TestDemoMode_Models(t *testing.T) {
	r, token := buildDemoRouter()
	w := demoGET(t, r, token, "/api/v1/models")
	assert.Equal(t, http.StatusOK, w.Code)
	assert.NotContains(t, w.Body.String(), `"real":true`)
}

func TestDemoMode_Tickets(t *testing.T) {
	r, token := buildDemoRouter()
	w := demoGET(t, r, token, "/api/v1/tickets")
	assert.Equal(t, http.StatusOK, w.Code)
	assert.NotContains(t, w.Body.String(), `"real":true`)
}

func TestDemoMode_Instances(t *testing.T) {
	r, token := buildDemoRouter()
	w := demoGET(t, r, token, "/api/v1/instances")
	assert.Equal(t, http.StatusOK, w.Code)
	assert.NotContains(t, w.Body.String(), `"real":true`)
}

func TestDemoMode_MyTasks(t *testing.T) {
	r, token := buildDemoRouter()
	w := demoGET(t, r, token, "/api/v1/instances/my-tasks")
	assert.Equal(t, http.StatusOK, w.Code)
	assert.NotContains(t, w.Body.String(), `"real":true`)
}

// ---- Non-demo user passes through ----

func TestDemoMode_NonDemoUser_PassesThrough(t *testing.T) {
	cfg := &config.Config{
		JWTSecret:      "demo-test-secret-that-is-32-chars!",
		AccessTokenTTL: 15 * time.Minute,
	}
	authSvc := service.NewAuthService(nil, cfg)

	userID := uuid.New()
	cid := uuid.New()
	now := time.Now()
	claims := &service.Claims{
		UserID:    userID,
		Email:     "real@example.com",
		CompanyID: &cid,
		IsDemo:    false, // NOT demo
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID.String(),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(15 * time.Minute)),
		},
	}
	token, _ := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(cfg.JWTSecret))

	r := gin.New()
	r.Use(middleware.Auth(authSvc))
	r.Use(middleware.DemoMode())
	r.GET("/api/v1/flows", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"real": true})
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest(http.MethodGet, "/api/v1/flows", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	r.ServeHTTP(w, req)

	// Non-demo user gets real handler response.
	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), `"real":true`)
}

// ---- DemoUserID consistency ----

func TestDemoUserID_MatchesDemoToken(t *testing.T) {
	cfg := &config.Config{
		JWTSecret:      "demo-test-secret-that-is-32-chars!",
		AccessTokenTTL: 365 * 24 * time.Hour,
	}
	svc := service.NewAuthService(nil, cfg)

	// Build demo token via the proper route.
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

	// Validate and extract.
	parsed, err := svc.ValidateAccessToken(token)
	require.NoError(t, err)
	assert.Equal(t, service.DemoUserID, parsed.UserID)
	assert.Equal(t, service.DemoCompanyID, *parsed.CompanyID)
	assert.True(t, parsed.IsDemo)
}
