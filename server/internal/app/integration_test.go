// Package app provides full-stack integration tests that run against a real
// PostgreSQL database. Set TEST_DATABASE_URL or rely on the default:
//
//	postgres://postgres:2851332@localhost:5432/autocreat_test?sslmode=disable
package app

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"github.com/autocreat/server/internal/config"
	"github.com/autocreat/server/internal/database"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

// ─────────────────────────── helpers ────────────────────────────────────────

func testDSN() string {
	if v := os.Getenv("TEST_DATABASE_URL"); v != "" {
		return v
	}
	return "postgres://postgres:2851332@localhost:5432/autocreat_test?sslmode=disable"
}

func testConfig() *config.Config {
	return &config.Config{
		JWTSecret:        "integration-test-jwt-secret-32ch!",
		JWTRefreshSecret: "integration-test-refresh-secret!!",
		AccessTokenTTL:   15 * time.Minute,
		RefreshTokenTTL:  7 * 24 * time.Hour,
		RateLimit:        1000,
		RateLimitBurst:   1000,
		AllowedOrigins:   []string{"http://localhost:3000"},
		Port:             "8080",
		Env:              "test",
	}
}

// setupTestApp returns a fully-wired App backed by the test database.
// It runs migrations and returns a cleanup function that truncates all tables.
func setupTestApp(t *testing.T) (*App, func()) {
	t.Helper()

	log, _ := zap.NewDevelopment()
	cfg := testConfig()

	db, err := database.Connect(testDSN(), log)
	require.NoError(t, err, "connect to test database")
	require.NoError(t, database.Migrate(db), "run migrations")

	gin.SetMode(gin.TestMode)

	app := New(cfg, db, nil, log)

	cleanup := func() {
		truncateAll(t, db)
	}
	return app, cleanup
}

// truncateAll removes all rows from every application table in dependency order.
func truncateAll(t *testing.T, db *gorm.DB) {
	t.Helper()
	tables := []string{
		"flow_instance_steps", "flow_instances", "flow_assignments",
		"flow_edges", "flow_nodes", "flows",
		"form_submissions", "form_definitions",
		"model_entities", "model_definitions",
		"generated_letters", "letter_templates",
		"ticket_messages", "tickets",
		"company_members", "roles", "sessions", "users", "companies",
	}
	for _, tbl := range tables {
		db.Exec(fmt.Sprintf("TRUNCATE TABLE %s CASCADE", tbl))
	}
}

// do fires a request against the app and decodes the JSON body into out (if not nil).
func do(t *testing.T, app *App, method, path string, body interface{}, token string) *httptest.ResponseRecorder {
	t.Helper()
	var buf bytes.Buffer
	if body != nil {
		require.NoError(t, json.NewEncoder(&buf).Encode(body))
	}
	req, err := http.NewRequest(method, path, &buf)
	require.NoError(t, err)
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	w := httptest.NewRecorder()
	app.Engine.ServeHTTP(w, req)
	return w
}

// doQ is like do but appends query params.
func doQ(t *testing.T, app *App, method, path string, params map[string]string, body interface{}, token string) *httptest.ResponseRecorder {
	t.Helper()
	if len(params) > 0 {
		path += "?"
		for k, v := range params {
			path += k + "=" + v + "&"
		}
	}
	return do(t, app, method, path, body, token)
}

func decode(t *testing.T, w *httptest.ResponseRecorder, out interface{}) {
	t.Helper()
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), out))
}

// registerAndLogin creates a unique user via /register and returns their access token + user info.
func registerAndLogin(t *testing.T, app *App, suffix string) (accessToken string, userMap map[string]interface{}, companyID string) {
	t.Helper()
	email := fmt.Sprintf("user-%s-%d@test.com", suffix, time.Now().UnixNano())
	w := do(t, app, http.MethodPost, "/api/v1/auth/register", map[string]interface{}{
		"email":       email,
		"password":    "Password123!",
		"firstName":   "Test",
		"lastName":    "User",
		"companyName": "TestCo-" + suffix,
	}, "")
	require.Equal(t, http.StatusCreated, w.Code, "register: %s", w.Body)

	var resp map[string]interface{}
	decode(t, w, &resp)

	accessToken = resp["accessToken"].(string)
	userMap = resp["user"].(map[string]interface{})
	if cid, ok := userMap["companyId"].(string); ok {
		companyID = cid
	}
	return
}

// ─────────────────────────── Health ─────────────────────────────────────────

func TestIntegration_Health(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	w := do(t, app, http.MethodGet, "/health", nil, "")
	assert.Equal(t, http.StatusOK, w.Code)

	var body map[string]interface{}
	decode(t, w, &body)
	assert.Equal(t, "ok", body["status"])
	assert.Equal(t, "autocreat", body["service"])
}

// ─────────────────────────── Auth ────────────────────────────────────────────

func TestIntegration_Auth_RegisterAndLogin(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	email := fmt.Sprintf("auth-test-%d@test.com", time.Now().UnixNano())

	// Register
	w := do(t, app, http.MethodPost, "/api/v1/auth/register", map[string]interface{}{
		"email":     email,
		"password":  "SecurePass123!",
		"firstName": "Alice",
		"lastName":  "Smith",
	}, "")
	assert.Equal(t, http.StatusCreated, w.Code, "register body: %s", w.Body)

	var reg map[string]interface{}
	decode(t, w, &reg)
	assert.NotEmpty(t, reg["accessToken"])
	assert.NotEmpty(t, reg["refreshToken"])
	user := reg["user"].(map[string]interface{})
	assert.Equal(t, email, user["email"])
	assert.Equal(t, "Alice", user["firstName"])
	assert.Equal(t, true, user["isActive"])
	assert.NotNil(t, user["companyId"])

	// Login with same credentials
	w2 := do(t, app, http.MethodPost, "/api/v1/auth/login", map[string]string{
		"email":    email,
		"password": "SecurePass123!",
	}, "")
	assert.Equal(t, http.StatusOK, w2.Code, "login body: %s", w2.Body)

	var login map[string]interface{}
	decode(t, w2, &login)
	assert.NotEmpty(t, login["accessToken"])
}

func TestIntegration_Auth_Register_DuplicateEmail(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	email := fmt.Sprintf("dup-%d@test.com", time.Now().UnixNano())
	body := map[string]interface{}{
		"email": email, "password": "Pass1234!", "firstName": "A", "lastName": "B",
	}
	w1 := do(t, app, http.MethodPost, "/api/v1/auth/register", body, "")
	assert.Equal(t, http.StatusCreated, w1.Code)

	w2 := do(t, app, http.MethodPost, "/api/v1/auth/register", body, "")
	assert.Equal(t, http.StatusConflict, w2.Code, "should fail on duplicate: %s", w2.Body)
}

func TestIntegration_Auth_Login_WrongPassword(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	email := fmt.Sprintf("wp-%d@test.com", time.Now().UnixNano())
	do(t, app, http.MethodPost, "/api/v1/auth/register", map[string]interface{}{
		"email": email, "password": "Correct1!", "firstName": "A", "lastName": "B",
	}, "")

	w := do(t, app, http.MethodPost, "/api/v1/auth/login", map[string]string{
		"email": email, "password": "WrongPass1!",
	}, "")
	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestIntegration_Auth_Login_UnknownEmail(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	w := do(t, app, http.MethodPost, "/api/v1/auth/login", map[string]string{
		"email": "nobody@nowhere.com", "password": "anything123",
	}, "")
	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestIntegration_Auth_Me(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, userMap, _ := registerAndLogin(t, app, "me")

	w := do(t, app, http.MethodGet, "/api/v1/auth/me", nil, token)
	assert.Equal(t, http.StatusOK, w.Code, "me body: %s", w.Body)

	var resp map[string]interface{}
	decode(t, w, &resp)
	assert.Equal(t, userMap["email"], resp["email"])
	assert.Equal(t, userMap["firstName"], resp["firstName"])
}

func TestIntegration_Auth_Me_NoToken(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	w := do(t, app, http.MethodGet, "/api/v1/auth/me", nil, "")
	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestIntegration_Auth_Refresh(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	email := fmt.Sprintf("refresh-%d@test.com", time.Now().UnixNano())
	w := do(t, app, http.MethodPost, "/api/v1/auth/register", map[string]interface{}{
		"email": email, "password": "Pass1234!", "firstName": "R", "lastName": "T",
	}, "")
	require.Equal(t, http.StatusCreated, w.Code)
	var reg map[string]interface{}
	decode(t, w, &reg)
	refreshToken := reg["refreshToken"].(string)

	w2 := do(t, app, http.MethodPost, "/api/v1/auth/refresh", map[string]string{
		"refresh_token": refreshToken,
	}, "")
	assert.Equal(t, http.StatusOK, w2.Code, "refresh body: %s", w2.Body)
	var tok map[string]interface{}
	decode(t, w2, &tok)
	assert.NotEmpty(t, tok["access_token"])
}

func TestIntegration_Auth_Logout(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	email := fmt.Sprintf("logout-%d@test.com", time.Now().UnixNano())
	w := do(t, app, http.MethodPost, "/api/v1/auth/register", map[string]interface{}{
		"email": email, "password": "Pass1234!", "firstName": "L", "lastName": "O",
	}, "")
	require.Equal(t, http.StatusCreated, w.Code)
	var reg map[string]interface{}
	decode(t, w, &reg)
	refreshToken := reg["refreshToken"].(string)

	// Logout invalidates the session
	w2 := do(t, app, http.MethodPost, "/api/v1/auth/logout", map[string]string{
		"refresh_token": refreshToken,
	}, "")
	assert.Equal(t, http.StatusOK, w2.Code)

	// Refresh with the same token should now fail
	w3 := do(t, app, http.MethodPost, "/api/v1/auth/refresh", map[string]string{
		"refresh_token": refreshToken,
	}, "")
	assert.Equal(t, http.StatusUnauthorized, w3.Code, "refresh after logout: %s", w3.Body)
}

func TestIntegration_Auth_Register_InvalidEmail(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	w := do(t, app, http.MethodPost, "/api/v1/auth/register", map[string]interface{}{
		"email": "not-an-email", "password": "Pass1234!", "firstName": "A", "lastName": "B",
	}, "")
	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestIntegration_Auth_Register_ShortPassword(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	w := do(t, app, http.MethodPost, "/api/v1/auth/register", map[string]interface{}{
		"email": "short@test.com", "password": "short", "firstName": "A", "lastName": "B",
	}, "")
	assert.Equal(t, http.StatusBadRequest, w.Code)
}

// ─────────────────────────── Companies ───────────────────────────────────────

func TestIntegration_Companies_List(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, _ := registerAndLogin(t, app, "clist")

	w := do(t, app, http.MethodGet, "/api/v1/companies", nil, token)
	assert.Equal(t, http.StatusOK, w.Code, "companies: %s", w.Body)

	var companies []interface{}
	decode(t, w, &companies)
	assert.GreaterOrEqual(t, len(companies), 1, "should have the auto-created company")
}

func TestIntegration_Companies_Create_And_Get(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, _ := registerAndLogin(t, app, "ccreate")

	w := do(t, app, http.MethodPost, "/api/v1/companies", map[string]interface{}{
		"name":        "ACME Corp",
		"description": "Test company",
		"website":     "https://acme.test",
		"industry":    "technology",
	}, token)
	assert.Equal(t, http.StatusCreated, w.Code, "create company: %s", w.Body)

	var created map[string]interface{}
	decode(t, w, &created)
	assert.Equal(t, "ACME Corp", created["name"])
	cid := created["id"].(string)

	// Get by ID
	w2 := do(t, app, http.MethodGet, "/api/v1/companies/"+cid, nil, token)
	assert.Equal(t, http.StatusOK, w2.Code)
	var got map[string]interface{}
	decode(t, w2, &got)
	assert.Equal(t, "ACME Corp", got["name"])
}

func TestIntegration_Companies_Update(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, _ := registerAndLogin(t, app, "cupd")

	w := do(t, app, http.MethodPost, "/api/v1/companies", map[string]interface{}{
		"name": "Original Name",
	}, token)
	require.Equal(t, http.StatusCreated, w.Code)
	var c map[string]interface{}
	decode(t, w, &c)
	cid := c["id"].(string)

	w2 := do(t, app, http.MethodPut, "/api/v1/companies/"+cid, map[string]interface{}{
		"name": "Updated Name",
	}, token)
	assert.Equal(t, http.StatusOK, w2.Code)
	var updated map[string]interface{}
	decode(t, w2, &updated)
	assert.Equal(t, "Updated Name", updated["name"])
}

func TestIntegration_Companies_Delete(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, _ := registerAndLogin(t, app, "cdel")

	w := do(t, app, http.MethodPost, "/api/v1/companies", map[string]interface{}{
		"name": "ToDelete",
	}, token)
	require.Equal(t, http.StatusCreated, w.Code)
	var c map[string]interface{}
	decode(t, w, &c)
	cid := c["id"].(string)

	w2 := do(t, app, http.MethodDelete, "/api/v1/companies/"+cid, nil, token)
	assert.Equal(t, http.StatusNoContent, w2.Code)

	w3 := do(t, app, http.MethodGet, "/api/v1/companies/"+cid, nil, token)
	assert.Equal(t, http.StatusNotFound, w3.Code)
}

func TestIntegration_Companies_RequireAuth(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	w := do(t, app, http.MethodGet, "/api/v1/companies", nil, "")
	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestIntegration_Companies_GetNonExistent(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, _ := registerAndLogin(t, app, "cnotfound")

	w := do(t, app, http.MethodGet, "/api/v1/companies/00000000-0000-0000-0000-000000000001", nil, token)
	assert.Equal(t, http.StatusNotFound, w.Code)
}

// ─────────────────────────── Roles ───────────────────────────────────────────

func TestIntegration_Roles_CRUD(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, companyID := registerAndLogin(t, app, "roles")

	// Create role
	w := doQ(t, app, http.MethodPost, "/api/v1/roles", map[string]string{"companyId": companyID},
		map[string]interface{}{
			"name":        "Manager",
			"description": "Team manager",
			"level":       "manager",
			"isActive":    true,
			"permissions": []map[string]interface{}{
				{"resource": "tickets", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": false, "customActions": []string{}},
			},
		}, token)
	assert.Equal(t, http.StatusCreated, w.Code, "create role: %s", w.Body)

	var created map[string]interface{}
	decode(t, w, &created)
	assert.Equal(t, "Manager", created["name"])
	rid := created["id"].(string)

	// List roles
	wl := doQ(t, app, http.MethodGet, "/api/v1/roles", map[string]string{"companyId": companyID}, nil, token)
	assert.Equal(t, http.StatusOK, wl.Code)
	var roles []interface{}
	decode(t, wl, &roles)
	assert.GreaterOrEqual(t, len(roles), 1)

	// Get by ID
	wg := do(t, app, http.MethodGet, "/api/v1/roles/"+rid, nil, token)
	assert.Equal(t, http.StatusOK, wg.Code)

	// Update
	wu := do(t, app, http.MethodPut, "/api/v1/roles/"+rid, map[string]interface{}{
		"name": "Senior Manager",
	}, token)
	assert.Equal(t, http.StatusOK, wu.Code)
	var updated map[string]interface{}
	decode(t, wu, &updated)
	assert.Equal(t, "Senior Manager", updated["name"])

	// Delete
	wd := do(t, app, http.MethodDelete, "/api/v1/roles/"+rid, nil, token)
	assert.Equal(t, http.StatusNoContent, wd.Code)
}

func TestIntegration_Roles_MissingCompanyID(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, _ := registerAndLogin(t, app, "roles-nocid")

	w := do(t, app, http.MethodGet, "/api/v1/roles", nil, token)
	assert.Equal(t, http.StatusBadRequest, w.Code)
}

// ─────────────────────────── Users ───────────────────────────────────────────

func TestIntegration_Users_CRUD(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, userMap, companyID := registerAndLogin(t, app, "users")

	// List users (owner should be included)
	wl := doQ(t, app, http.MethodGet, "/api/v1/users", map[string]string{"companyId": companyID}, nil, token)
	assert.Equal(t, http.StatusOK, wl.Code, "list users: %s", wl.Body)

	// Create user in company
	wc := doQ(t, app, http.MethodPost, "/api/v1/users", map[string]string{"companyId": companyID},
		map[string]interface{}{
			"email":     fmt.Sprintf("member-%d@test.com", time.Now().UnixNano()),
			"password":  "MemberPass1!",
			"firstName": "Bob",
			"lastName":  "Jones",
		}, token)
	assert.Equal(t, http.StatusCreated, wc.Code, "create user: %s", wc.Body)

	var created map[string]interface{}
	decode(t, wc, &created)
	uid := created["id"].(string)

	// Get by ID
	wg := do(t, app, http.MethodGet, "/api/v1/users/"+uid, nil, token)
	assert.Equal(t, http.StatusOK, wg.Code)

	// Update
	wu := do(t, app, http.MethodPut, "/api/v1/users/"+uid, map[string]interface{}{
		"firstName": "Robert",
	}, token)
	assert.Equal(t, http.StatusOK, wu.Code)
	var updated map[string]interface{}
	decode(t, wu, &updated)
	assert.Equal(t, "Robert", updated["firstName"])

	_ = userMap // suppress unused warning
}

func TestIntegration_Users_Delete(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, companyID := registerAndLogin(t, app, "userdel")

	wc := doQ(t, app, http.MethodPost, "/api/v1/users", map[string]string{"companyId": companyID},
		map[string]interface{}{
			"email":     fmt.Sprintf("del-%d@test.com", time.Now().UnixNano()),
			"password":  "DelPass123!",
			"firstName": "Del",
			"lastName":  "User",
		}, token)
	require.Equal(t, http.StatusCreated, wc.Code)
	var created map[string]interface{}
	decode(t, wc, &created)
	uid := created["id"].(string)

	wd := do(t, app, http.MethodDelete, "/api/v1/users/"+uid, nil, token)
	assert.Equal(t, http.StatusNoContent, wd.Code)

	wg := do(t, app, http.MethodGet, "/api/v1/users/"+uid, nil, token)
	assert.Equal(t, http.StatusNotFound, wg.Code)
}

// ─────────────────────────── Flows ───────────────────────────────────────────

func TestIntegration_Flows_CRUD(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, companyID := registerAndLogin(t, app, "flows")

	// Create flow
	wc := doQ(t, app, http.MethodPost, "/api/v1/flows", map[string]string{"companyId": companyID},
		map[string]interface{}{
			"name":        "Onboarding Flow",
			"description": "New employee onboarding",
			"status":      "draft",
		}, token)
	assert.Equal(t, http.StatusCreated, wc.Code, "create flow: %s", wc.Body)
	var flow map[string]interface{}
	decode(t, wc, &flow)
	assert.Equal(t, "Onboarding Flow", flow["name"])
	fid := flow["id"].(string)

	// List
	wl := doQ(t, app, http.MethodGet, "/api/v1/flows", map[string]string{"companyId": companyID}, nil, token)
	assert.Equal(t, http.StatusOK, wl.Code)
	var flows []interface{}
	decode(t, wl, &flows)
	assert.GreaterOrEqual(t, len(flows), 1)

	// Get by ID
	wg := do(t, app, http.MethodGet, "/api/v1/flows/"+fid, nil, token)
	assert.Equal(t, http.StatusOK, wg.Code)

	// Update
	wu := do(t, app, http.MethodPut, "/api/v1/flows/"+fid, map[string]interface{}{
		"name": "Updated Onboarding",
	}, token)
	assert.Equal(t, http.StatusOK, wu.Code)
	var updated map[string]interface{}
	decode(t, wu, &updated)
	assert.Equal(t, "Updated Onboarding", updated["name"])

	// Delete
	wd := do(t, app, http.MethodDelete, "/api/v1/flows/"+fid, nil, token)
	assert.Equal(t, http.StatusNoContent, wd.Code)
}

func TestIntegration_Flows_NodesAndEdges(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, companyID := registerAndLogin(t, app, "flownodes")

	// Create flow
	wc := doQ(t, app, http.MethodPost, "/api/v1/flows", map[string]string{"companyId": companyID},
		map[string]interface{}{"name": "Test Flow"}, token)
	require.Equal(t, http.StatusCreated, wc.Code)
	var flow map[string]interface{}
	decode(t, wc, &flow)
	fid := flow["id"].(string)

	// Create start node
	wn1 := do(t, app, http.MethodPost, "/api/v1/flows/"+fid+"/nodes",
		map[string]interface{}{"label": "Start", "type": "start", "x": 100, "y": 100}, token)
	assert.Equal(t, http.StatusCreated, wn1.Code, "create start node: %s", wn1.Body)
	var n1 map[string]interface{}
	decode(t, wn1, &n1)
	nid1 := n1["id"].(string)

	// Create end node
	wn2 := do(t, app, http.MethodPost, "/api/v1/flows/"+fid+"/nodes",
		map[string]interface{}{"label": "End", "type": "end", "x": 400, "y": 100}, token)
	assert.Equal(t, http.StatusCreated, wn2.Code)
	var n2 map[string]interface{}
	decode(t, wn2, &n2)
	nid2 := n2["id"].(string)

	// Create edge
	we := do(t, app, http.MethodPost, "/api/v1/flows/"+fid+"/edges",
		map[string]interface{}{"sourceNodeId": nid1, "targetNodeId": nid2, "label": "next"}, token)
	assert.Equal(t, http.StatusCreated, we.Code, "create edge: %s", we.Body)
	var edge map[string]interface{}
	decode(t, we, &edge)
	eid := edge["id"].(string)

	// List nodes
	wln := do(t, app, http.MethodGet, "/api/v1/flows/"+fid+"/nodes", nil, token)
	assert.Equal(t, http.StatusOK, wln.Code)
	var nodes []interface{}
	decode(t, wln, &nodes)
	assert.Equal(t, 2, len(nodes))

	// List edges
	wle := do(t, app, http.MethodGet, "/api/v1/flows/"+fid+"/edges", nil, token)
	assert.Equal(t, http.StatusOK, wle.Code)
	var edges []interface{}
	decode(t, wle, &edges)
	assert.Equal(t, 1, len(edges))

	// Update node
	wun := do(t, app, http.MethodPut, "/api/v1/flows/"+fid+"/nodes/"+nid1,
		map[string]interface{}{"label": "Begin", "type": "start", "x": 150, "y": 150}, token)
	assert.Equal(t, http.StatusOK, wun.Code)

	// Delete edge
	wde := do(t, app, http.MethodDelete, "/api/v1/flows/"+fid+"/edges/"+eid, nil, token)
	assert.Equal(t, http.StatusNoContent, wde.Code)

	// Delete node
	wdn := do(t, app, http.MethodDelete, "/api/v1/flows/"+fid+"/nodes/"+nid1, nil, token)
	assert.Equal(t, http.StatusNoContent, wdn.Code)
}

func TestIntegration_Flows_SaveGraph(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, companyID := registerAndLogin(t, app, "savegraph")

	wc := doQ(t, app, http.MethodPost, "/api/v1/flows", map[string]string{"companyId": companyID},
		map[string]interface{}{"name": "Graph Flow"}, token)
	require.Equal(t, http.StatusCreated, wc.Code)
	var flow map[string]interface{}
	decode(t, wc, &flow)
	fid := flow["id"].(string)

	graph := map[string]interface{}{
		"nodes": []map[string]interface{}{
			{"id": "node-1", "label": "Start", "type": "start", "x": 0, "y": 0},
			{"id": "node-2", "label": "End", "type": "end", "x": 300, "y": 0},
		},
		"edges": []map[string]interface{}{
			{"id": "edge-1", "sourceNodeId": "node-1", "targetNodeId": "node-2", "label": "go"},
		},
	}
	ws := do(t, app, http.MethodPut, "/api/v1/flows/"+fid+"/graph", graph, token)
	assert.Equal(t, http.StatusOK, ws.Code, "save graph: %s", ws.Body)
}

// ─────────────────────────── Tickets ─────────────────────────────────────────

func TestIntegration_Tickets_CRUD(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, companyID := registerAndLogin(t, app, "tickets")

	// Create ticket
	wc := doQ(t, app, http.MethodPost, "/api/v1/tickets", map[string]string{"companyId": companyID},
		map[string]interface{}{
			"title":       "Bug: Login fails",
			"description": "Users cannot log in on mobile",
			"priority":    "high",
			"tags":        []string{"bug", "auth"},
		}, token)
	assert.Equal(t, http.StatusCreated, wc.Code, "create ticket: %s", wc.Body)
	var ticket map[string]interface{}
	decode(t, wc, &ticket)
	assert.Equal(t, "Bug: Login fails", ticket["title"])
	assert.Equal(t, "open", ticket["status"])
	tid := ticket["id"].(string)

	// List
	wl := doQ(t, app, http.MethodGet, "/api/v1/tickets", map[string]string{"companyId": companyID}, nil, token)
	assert.Equal(t, http.StatusOK, wl.Code)
	var tickets []interface{}
	decode(t, wl, &tickets)
	assert.GreaterOrEqual(t, len(tickets), 1)

	// Get by ID
	wg := do(t, app, http.MethodGet, "/api/v1/tickets/"+tid, nil, token)
	assert.Equal(t, http.StatusOK, wg.Code)

	// Update
	wu := do(t, app, http.MethodPut, "/api/v1/tickets/"+tid, map[string]interface{}{
		"title": "Bug: Login fails on mobile",
	}, token)
	assert.Equal(t, http.StatusOK, wu.Code)
	var updated map[string]interface{}
	decode(t, wu, &updated)
	assert.Equal(t, "Bug: Login fails on mobile", updated["title"])

	// Update status
	ws := do(t, app, http.MethodPatch, "/api/v1/tickets/"+tid+"/status", map[string]interface{}{
		"status": "inProgress",
	}, token)
	assert.Equal(t, http.StatusOK, ws.Code, "update status: %s", ws.Body)
	var statusUpdated map[string]interface{}
	decode(t, ws, &statusUpdated)
	assert.Equal(t, "inProgress", statusUpdated["status"])
}

func TestIntegration_Tickets_Messages(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, companyID := registerAndLogin(t, app, "ticketmsg")

	wc := doQ(t, app, http.MethodPost, "/api/v1/tickets", map[string]string{"companyId": companyID},
		map[string]interface{}{"title": "Msg Test Ticket"}, token)
	require.Equal(t, http.StatusCreated, wc.Code)
	var ticket map[string]interface{}
	decode(t, wc, &ticket)
	tid := ticket["id"].(string)

	// Send message
	wm := do(t, app, http.MethodPost, "/api/v1/tickets/"+tid+"/messages",
		map[string]interface{}{"content": "This is a reply"}, token)
	assert.Equal(t, http.StatusCreated, wm.Code, "send message: %s", wm.Body)
	var msg map[string]interface{}
	decode(t, wm, &msg)
	assert.Equal(t, "This is a reply", msg["content"])

	// Get ticket with messages
	wg := do(t, app, http.MethodGet, "/api/v1/tickets/"+tid, nil, token)
	assert.Equal(t, http.StatusOK, wg.Code)
	var got map[string]interface{}
	decode(t, wg, &got)
	msgs := got["messages"].([]interface{})
	assert.GreaterOrEqual(t, len(msgs), 1)
}

func TestIntegration_Tickets_FilterByStatus(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, companyID := registerAndLogin(t, app, "ticketstatus")

	// Create open ticket
	doQ(t, app, http.MethodPost, "/api/v1/tickets", map[string]string{"companyId": companyID},
		map[string]interface{}{"title": "Open ticket", "priority": "low"}, token)

	// Filter by status=open
	wl := doQ(t, app, http.MethodGet, "/api/v1/tickets",
		map[string]string{"companyId": companyID, "status": "open"}, nil, token)
	assert.Equal(t, http.StatusOK, wl.Code)
	var tickets []interface{}
	decode(t, wl, &tickets)
	for _, tt := range tickets {
		m := tt.(map[string]interface{})
		assert.Equal(t, "open", m["status"])
	}
}

// ─────────────────────────── Forms ───────────────────────────────────────────

func TestIntegration_Forms_CRUD(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, companyID := registerAndLogin(t, app, "forms")

	fields := []map[string]interface{}{
		{"id": "f1", "label": "Name", "type": "text", "required": true},
		{"id": "f2", "label": "Age", "type": "number", "required": false},
	}

	// Create form
	wc := doQ(t, app, http.MethodPost, "/api/v1/forms", map[string]string{"companyId": companyID},
		map[string]interface{}{
			"name":        "Employee Info",
			"description": "Basic employee info form",
			"fields":      fields,
		}, token)
	assert.Equal(t, http.StatusCreated, wc.Code, "create form: %s", wc.Body)
	var form map[string]interface{}
	decode(t, wc, &form)
	fid := form["id"].(string)

	// List
	wl := doQ(t, app, http.MethodGet, "/api/v1/forms", map[string]string{"companyId": companyID}, nil, token)
	assert.Equal(t, http.StatusOK, wl.Code)

	// Get
	wg := do(t, app, http.MethodGet, "/api/v1/forms/"+fid, nil, token)
	assert.Equal(t, http.StatusOK, wg.Code)

	// Update
	wu := do(t, app, http.MethodPut, "/api/v1/forms/"+fid, map[string]interface{}{
		"name": "Updated Form",
	}, token)
	assert.Equal(t, http.StatusOK, wu.Code)

	// Delete
	wd := do(t, app, http.MethodDelete, "/api/v1/forms/"+fid, nil, token)
	assert.Equal(t, http.StatusNoContent, wd.Code)
}

// ─────────────────────────── Models ──────────────────────────────────────────

func TestIntegration_Models_CRUD_WithEntities(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, companyID := registerAndLogin(t, app, "models")

	fields := []map[string]interface{}{
		{"id": "f1", "name": "Name", "type": "text", "required": true},
	}

	// Create model definition
	wc := doQ(t, app, http.MethodPost, "/api/v1/models", map[string]string{"companyId": companyID},
		map[string]interface{}{
			"name":        "Product",
			"description": "Product catalog",
			"fields":      fields,
		}, token)
	assert.Equal(t, http.StatusCreated, wc.Code, "create model: %s", wc.Body)
	var model map[string]interface{}
	decode(t, wc, &model)
	mid := model["id"].(string)

	// List
	wl := doQ(t, app, http.MethodGet, "/api/v1/models", map[string]string{"companyId": companyID}, nil, token)
	assert.Equal(t, http.StatusOK, wl.Code)

	// Create entity
	we := doQ(t, app, http.MethodPost, "/api/v1/models/"+mid+"/entities",
		map[string]string{"companyId": companyID},
		map[string]interface{}{"data": map[string]interface{}{"Name": "Widget A"}}, token)
	assert.Equal(t, http.StatusCreated, we.Code, "create entity: %s", we.Body)
	var entity map[string]interface{}
	decode(t, we, &entity)
	require.NotNil(t, entity["id"], "entity id should not be nil")
	eid := entity["id"].(string)

	// List entities
	wle := do(t, app, http.MethodGet, "/api/v1/models/"+mid+"/entities", nil, token)
	assert.Equal(t, http.StatusOK, wle.Code)
	var entities []interface{}
	decode(t, wle, &entities)
	assert.GreaterOrEqual(t, len(entities), 1)

	// Get entity
	wge := do(t, app, http.MethodGet, "/api/v1/models/"+mid+"/entities/"+eid, nil, token)
	assert.Equal(t, http.StatusOK, wge.Code)

	// Update entity
	wue := doQ(t, app, http.MethodPut, "/api/v1/models/"+mid+"/entities/"+eid,
		map[string]string{"companyId": companyID},
		map[string]interface{}{"data": map[string]interface{}{"Name": "Widget B"}}, token)
	assert.Equal(t, http.StatusOK, wue.Code)

	// Delete entity
	wde := doQ(t, app, http.MethodDelete, "/api/v1/models/"+mid+"/entities/"+eid,
		map[string]string{"companyId": companyID}, nil, token)
	assert.Equal(t, http.StatusNoContent, wde.Code)

	// Delete model
	wdm := do(t, app, http.MethodDelete, "/api/v1/models/"+mid, nil, token)
	assert.Equal(t, http.StatusNoContent, wdm.Code)
}

// ─────────────────────────── Letters ─────────────────────────────────────────

func TestIntegration_Letters_CRUD_AndGenerate(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, companyID := registerAndLogin(t, app, "letters")

	// Create letter template
	wc := doQ(t, app, http.MethodPost, "/api/v1/letters", map[string]string{"companyId": companyID},
		map[string]interface{}{
			"name":      "Welcome Letter",
			"content":   "Dear {{firstName}}, welcome to {{company}}!",
			"variables": []string{"firstName", "company"},
		}, token)
	assert.Equal(t, http.StatusCreated, wc.Code, "create letter: %s", wc.Body)
	var letter map[string]interface{}
	decode(t, wc, &letter)
	lid := letter["id"].(string)

	// List
	wl := doQ(t, app, http.MethodGet, "/api/v1/letters", map[string]string{"companyId": companyID}, nil, token)
	assert.Equal(t, http.StatusOK, wl.Code)

	// Get
	wg := do(t, app, http.MethodGet, "/api/v1/letters/"+lid, nil, token)
	assert.Equal(t, http.StatusOK, wg.Code)

	// Update
	wu := do(t, app, http.MethodPut, "/api/v1/letters/"+lid, map[string]interface{}{
		"name": "Welcome Letter v2",
	}, token)
	assert.Equal(t, http.StatusOK, wu.Code)

	// Generate
	wgen := do(t, app, http.MethodPost, "/api/v1/letters/"+lid+"/generate",
		map[string]interface{}{
			"data": map[string]string{
				"firstName": "Alice",
				"company":   "ACME Corp",
			},
		}, token)
	assert.Equal(t, http.StatusCreated, wgen.Code, "generate letter: %s", wgen.Body)
	var generated map[string]interface{}
	decode(t, wgen, &generated)
	assert.Contains(t, generated["generatedContent"].(string), "Alice")
	assert.Contains(t, generated["generatedContent"].(string), "ACME Corp")

	// Delete
	wd := do(t, app, http.MethodDelete, "/api/v1/letters/"+lid, nil, token)
	assert.Equal(t, http.StatusNoContent, wd.Code)
}

// ─────────────────────────── Stats ───────────────────────────────────────────

func TestIntegration_Stats(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, companyID := registerAndLogin(t, app, "stats")

	w := doQ(t, app, http.MethodGet, "/api/v1/stats", map[string]string{"companyId": companyID}, nil, token)
	assert.Equal(t, http.StatusOK, w.Code, "stats: %s", w.Body)

	var stats map[string]interface{}
	decode(t, w, &stats)
	// Stats should have numeric counts
	assert.NotNil(t, stats)
}

// ─────────────────────────── Company Members ─────────────────────────────────

func TestIntegration_CompanyMembers_AddAndRemove(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, companyID := registerAndLogin(t, app, "members")

	// Create a role to assign
	wr := doQ(t, app, http.MethodPost, "/api/v1/roles", map[string]string{"companyId": companyID},
		map[string]interface{}{"name": "Member Role", "level": "member"}, token)
	require.Equal(t, http.StatusCreated, wr.Code)
	var role map[string]interface{}
	decode(t, wr, &role)
	roleID := role["id"].(string)

	// Create a second user
	email2 := fmt.Sprintf("member2-%d@test.com", time.Now().UnixNano())
	w2 := do(t, app, http.MethodPost, "/api/v1/auth/register", map[string]interface{}{
		"email": email2, "password": "Pass1234!", "firstName": "Bob", "lastName": "Builder",
	}, "")
	require.Equal(t, http.StatusCreated, w2.Code)
	var reg2 map[string]interface{}
	decode(t, w2, &reg2)
	user2ID := reg2["user"].(map[string]interface{})["id"].(string)

	// Add member to company
	wam := do(t, app, http.MethodPost, "/api/v1/companies/"+companyID+"/members",
		map[string]interface{}{"userId": user2ID, "roleId": roleID}, token)
	assert.Equal(t, http.StatusCreated, wam.Code, "add member: %s", wam.Body)

	// List members
	wlm := do(t, app, http.MethodGet, "/api/v1/companies/"+companyID+"/members", nil, token)
	assert.Equal(t, http.StatusOK, wlm.Code)
	var members []interface{}
	decode(t, wlm, &members)
	assert.GreaterOrEqual(t, len(members), 2)

	// Remove member
	wrm := do(t, app, http.MethodDelete, "/api/v1/companies/"+companyID+"/members/"+user2ID, nil, token)
	assert.Equal(t, http.StatusNoContent, wrm.Code)
}

// ─────────────────────────── Flow Instances ──────────────────────────────────

func TestIntegration_FlowInstances_StartAndAdvance(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, userMap, companyID := registerAndLogin(t, app, "instances")
	userID := userMap["id"].(string)

	// Create a flow
	wf := doQ(t, app, http.MethodPost, "/api/v1/flows", map[string]string{"companyId": companyID},
		map[string]interface{}{"name": "Approval Flow"}, token)
	require.Equal(t, http.StatusCreated, wf.Code)
	var flow map[string]interface{}
	decode(t, wf, &flow)
	fid := flow["id"].(string)

	// Add start node
	wn1 := do(t, app, http.MethodPost, "/api/v1/flows/"+fid+"/nodes",
		map[string]interface{}{"label": "Start", "type": "start", "x": 0, "y": 0}, token)
	require.Equal(t, http.StatusCreated, wn1.Code)
	var n1 map[string]interface{}
	decode(t, wn1, &n1)
	startNodeID := n1["id"].(string)

	// Add step node
	wn2 := do(t, app, http.MethodPost, "/api/v1/flows/"+fid+"/nodes",
		map[string]interface{}{"label": "Review", "type": "step", "x": 200, "y": 0}, token)
	require.Equal(t, http.StatusCreated, wn2.Code)
	var n2 map[string]interface{}
	decode(t, wn2, &n2)
	stepNodeID := n2["id"].(string)

	// Add edge
	do(t, app, http.MethodPost, "/api/v1/flows/"+fid+"/edges",
		map[string]interface{}{"sourceNodeId": startNodeID, "targetNodeId": stepNodeID}, token)

	// Start instance
	wi := doQ(t, app, http.MethodPost, "/api/v1/instances", map[string]string{"companyId": companyID},
		map[string]interface{}{
			"flowId":    fid,
			"startedBy": userID,
		}, token)
	assert.Equal(t, http.StatusCreated, wi.Code, "start instance: %s", wi.Body)
	var inst map[string]interface{}
	decode(t, wi, &inst)
	assert.Equal(t, "ACTIVE", inst["status"])
	iid := inst["id"].(string)

	// Get instance
	wgi := do(t, app, http.MethodGet, "/api/v1/instances/"+iid, nil, token)
	assert.Equal(t, http.StatusOK, wgi.Code)

	// List instances
	wli := doQ(t, app, http.MethodGet, "/api/v1/instances", map[string]string{"companyId": companyID}, nil, token)
	assert.Equal(t, http.StatusOK, wli.Code)

	// My tasks
	wmt := doQ(t, app, http.MethodGet, "/api/v1/instances/my-tasks", map[string]string{"companyId": companyID}, nil, token)
	assert.Equal(t, http.StatusOK, wmt.Code)

	// Advance instance
	wa := do(t, app, http.MethodPost, "/api/v1/instances/"+iid+"/advance",
		map[string]interface{}{"comment": "Looks good"}, token)
	assert.Equal(t, http.StatusOK, wa.Code, "advance: %s", wa.Body)

	_ = stepNodeID
}

func TestIntegration_FlowInstances_Reject(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, userMap, companyID := registerAndLogin(t, app, "inst-reject")
	userID := userMap["id"].(string)

	// Create minimal flow
	wf := doQ(t, app, http.MethodPost, "/api/v1/flows", map[string]string{"companyId": companyID},
		map[string]interface{}{"name": "Reject Test"}, token)
	require.Equal(t, http.StatusCreated, wf.Code)
	var flow map[string]interface{}
	decode(t, wf, &flow)
	fid := flow["id"].(string)

	wn := do(t, app, http.MethodPost, "/api/v1/flows/"+fid+"/nodes",
		map[string]interface{}{"label": "Start", "type": "start", "x": 0, "y": 0}, token)
	require.Equal(t, http.StatusCreated, wn.Code)

	wi := doQ(t, app, http.MethodPost, "/api/v1/instances", map[string]string{"companyId": companyID},
		map[string]interface{}{"flowId": fid, "startedBy": userID}, token)
	require.Equal(t, http.StatusCreated, wi.Code)
	var inst map[string]interface{}
	decode(t, wi, &inst)
	iid := inst["id"].(string)

	// Reject instance
	wr := do(t, app, http.MethodPost, "/api/v1/instances/"+iid+"/reject",
		map[string]interface{}{"reason": "Not approved"}, token)
	assert.Equal(t, http.StatusOK, wr.Code, "reject: %s", wr.Body)
	var rejected map[string]interface{}
	decode(t, wr, &rejected)
	assert.Equal(t, "REJECTED", rejected["status"])
}

// ─────────────────────────── Role Assign to User ─────────────────────────────

func TestIntegration_Users_AssignRole(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, companyID := registerAndLogin(t, app, "assignrole")

	// Create role
	wr := doQ(t, app, http.MethodPost, "/api/v1/roles", map[string]string{"companyId": companyID},
		map[string]interface{}{"name": "Analyst"}, token)
	require.Equal(t, http.StatusCreated, wr.Code)
	var role map[string]interface{}
	decode(t, wr, &role)
	roleID := role["id"].(string)

	// Create user
	wc := doQ(t, app, http.MethodPost, "/api/v1/users", map[string]string{"companyId": companyID},
		map[string]interface{}{
			"email":     fmt.Sprintf("analyst-%d@test.com", time.Now().UnixNano()),
			"password":  "Analyst123!",
			"firstName": "Ana",
			"lastName":  "Lyst",
		}, token)
	require.Equal(t, http.StatusCreated, wc.Code)
	var u map[string]interface{}
	decode(t, wc, &u)
	uid := u["id"].(string)

	// Assign role
	wa := do(t, app, http.MethodPatch, "/api/v1/users/"+uid+"/role",
		map[string]interface{}{"roleId": roleID}, token)
	assert.Equal(t, http.StatusOK, wa.Code, "assign role: %s", wa.Body)
	var updated map[string]interface{}
	decode(t, wa, &updated)
	assert.Equal(t, roleID, updated["roleId"])
}

// ─────────────────────────── Edge cases ─────────────────────────────────────

func TestIntegration_InvalidUUID_Returns400(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, _ := registerAndLogin(t, app, "uuid-err")

	cases := []struct{ method, path string }{
		{http.MethodGet, "/api/v1/companies/not-a-uuid"},
		{http.MethodGet, "/api/v1/tickets/bad-id"},
		{http.MethodGet, "/api/v1/flows/bad-id"},
		{http.MethodGet, "/api/v1/roles/bad-id"},
		{http.MethodGet, "/api/v1/users/bad-id"},
		{http.MethodGet, "/api/v1/letters/bad-id"},
		{http.MethodGet, "/api/v1/models/bad-id"},
	}
	for _, tc := range cases {
		w := do(t, app, tc.method, tc.path, nil, token)
		assert.Equal(t, http.StatusBadRequest, w.Code, "%s %s should be 400", tc.method, tc.path)
	}
}

func TestIntegration_MissingRequiredFields_Returns400(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, companyID := registerAndLogin(t, app, "missing-fields")

	// Ticket without title
	w := doQ(t, app, http.MethodPost, "/api/v1/tickets", map[string]string{"companyId": companyID},
		map[string]interface{}{"description": "no title"}, token)
	assert.Equal(t, http.StatusBadRequest, w.Code)

	// Flow without name
	w2 := doQ(t, app, http.MethodPost, "/api/v1/flows", map[string]string{"companyId": companyID},
		map[string]interface{}{"description": "no name"}, token)
	assert.Equal(t, http.StatusBadRequest, w2.Code)
}

func TestIntegration_Unauthenticated_Returns401(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	paths := []string{
		"/api/v1/companies",
		"/api/v1/roles",
		"/api/v1/users",
		"/api/v1/flows",
		"/api/v1/tickets",
		"/api/v1/forms",
		"/api/v1/models",
		"/api/v1/letters",
		"/api/v1/stats",
	}
	for _, path := range paths {
		w := do(t, app, http.MethodGet, path, nil, "")
		assert.Equal(t, http.StatusUnauthorized, w.Code, "path: %s", path)
	}
}

func TestIntegration_DemoLogin_WorksWithoutDB(t *testing.T) {
	// Demo login should work even on the real server (uses hardcoded credentials)
	app, cleanup := setupTestApp(t)
	defer cleanup()

	w := do(t, app, http.MethodPost, "/api/v1/auth/login", map[string]string{
		"email":    "demo@autocreat.io",
		"password": "Demo123!",
	}, "")
	assert.Equal(t, http.StatusOK, w.Code)
	var resp map[string]interface{}
	decode(t, w, &resp)
	assert.NotEmpty(t, resp["accessToken"])
	user := resp["user"].(map[string]interface{})
	assert.Equal(t, "demo@autocreat.io", user["email"])
}

func TestIntegration_Tickets_InvalidStatus_Returns400(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, companyID := registerAndLogin(t, app, "invalidstatus")

	wc := doQ(t, app, http.MethodPost, "/api/v1/tickets", map[string]string{"companyId": companyID},
		map[string]interface{}{"title": "Status Test"}, token)
	require.Equal(t, http.StatusCreated, wc.Code)
	var ticket map[string]interface{}
	decode(t, wc, &ticket)
	tid := ticket["id"].(string)

	// Try to set invalid status
	ws := do(t, app, http.MethodPatch, "/api/v1/tickets/"+tid+"/status",
		map[string]interface{}{"status": ""}, token)
	// Empty status fails binding
	assert.Equal(t, http.StatusBadRequest, ws.Code)
}

func TestIntegration_CompanyCreate_MissingName(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, _ := registerAndLogin(t, app, "comp-noname")

	w := do(t, app, http.MethodPost, "/api/v1/companies", map[string]interface{}{
		"description": "no name",
	}, token)
	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestIntegration_MultipleUsers_IsolatedData(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	// Two separate users in separate companies
	token1, _, cid1 := registerAndLogin(t, app, "iso1")
	token2, _, cid2 := registerAndLogin(t, app, "iso2")

	// User1 creates a ticket in company1
	doQ(t, app, http.MethodPost, "/api/v1/tickets", map[string]string{"companyId": cid1},
		map[string]interface{}{"title": "Company1 Ticket"}, token1)

	// User2 lists tickets in company2 — should not see company1 ticket
	wl := doQ(t, app, http.MethodGet, "/api/v1/tickets", map[string]string{"companyId": cid2}, nil, token2)
	assert.Equal(t, http.StatusOK, wl.Code)
	var tickets []interface{}
	decode(t, wl, &tickets)
	for _, tt := range tickets {
		m := tt.(map[string]interface{})
		assert.Equal(t, cid2, m["companyId"])
	}
}
