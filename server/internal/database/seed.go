package database

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/autocreat/server/internal/models"
	"github.com/google/uuid"
	"go.uber.org/zap"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// ---------- Deterministic seed UUIDs ----------

var (
	// Company
	seedCompanyID = uuid.MustParse("a1b2c3d4-e5f6-7890-abcd-ef1234567890")

	// Roles
	seedRoleAdminID   = uuid.MustParse("b0000001-0000-0000-0000-000000000001")
	seedRoleOpsID     = uuid.MustParse("b0000001-0000-0000-0000-000000000002")
	seedRoleSupportID = uuid.MustParse("b0000001-0000-0000-0000-000000000003")
	seedRoleDevID     = uuid.MustParse("b0000001-0000-0000-0000-000000000004")
	seedRoleViewerID  = uuid.MustParse("b0000001-0000-0000-0000-000000000005")

	// Users
	seedUserAlexandraID = uuid.MustParse("c0000001-0000-0000-0000-000000000001")
	seedUserMarcusID    = uuid.MustParse("c0000001-0000-0000-0000-000000000002")
	seedUserSofiaID     = uuid.MustParse("c0000001-0000-0000-0000-000000000003")
	seedUserJamesID     = uuid.MustParse("c0000001-0000-0000-0000-000000000004")
	seedUserEmilyID     = uuid.MustParse("c0000001-0000-0000-0000-000000000005")
	// seedUserDemoID must match service.DemoUserID so that /auth/me works for demo logins.
	seedUserDemoID = uuid.MustParse("d0e1f2a3-b4c5-d6e7-f8a9-b0c1d2e3f4a5")

	// Forms
	seedFormOnboardingID = uuid.MustParse("d0000001-0000-0000-0000-000000000001")
	seedFormProjectID    = uuid.MustParse("d0000001-0000-0000-0000-000000000002")
	seedFormBugID        = uuid.MustParse("d0000001-0000-0000-0000-000000000003")
	seedFormFeedbackID   = uuid.MustParse("d0000001-0000-0000-0000-000000000004")

	// Flows
	seedFlowOnboardingID = uuid.MustParse("e0000001-0000-0000-0000-000000000001")
	seedFlowBugID        = uuid.MustParse("e0000001-0000-0000-0000-000000000002")
	seedFlowProjectID    = uuid.MustParse("e0000001-0000-0000-0000-000000000003")

	// Flow nodes – Onboarding
	seedFlowOnbNodeStartID   = uuid.MustParse("e1000001-0000-0000-0000-000000000001")
	seedFlowOnbNodeHRID      = uuid.MustParse("e1000001-0000-0000-0000-000000000002")
	seedFlowOnbNodeITID      = uuid.MustParse("e1000001-0000-0000-0000-000000000003")
	seedFlowOnbNodeMgrID     = uuid.MustParse("e1000001-0000-0000-0000-000000000004")
	seedFlowOnbNodeWelcomeID = uuid.MustParse("e1000001-0000-0000-0000-000000000005")
	seedFlowOnbNodeEndID     = uuid.MustParse("e1000001-0000-0000-0000-000000000006")

	// Flow nodes – Bug
	seedFlowBugNodeStartID  = uuid.MustParse("e2000001-0000-0000-0000-000000000001")
	seedFlowBugNodeTriageID = uuid.MustParse("e2000001-0000-0000-0000-000000000002")
	seedFlowBugNodeDevID    = uuid.MustParse("e2000001-0000-0000-0000-000000000003")
	seedFlowBugNodeQAID     = uuid.MustParse("e2000001-0000-0000-0000-000000000004")
	seedFlowBugNodeEndID    = uuid.MustParse("e2000001-0000-0000-0000-000000000005")

	// Flow nodes – Project
	seedFlowProjNodeStartID    = uuid.MustParse("e3000001-0000-0000-0000-000000000001")
	seedFlowProjNodeReviewID   = uuid.MustParse("e3000001-0000-0000-0000-000000000002")
	seedFlowProjNodeDirectorID = uuid.MustParse("e3000001-0000-0000-0000-000000000003")
	seedFlowProjNodeContractID = uuid.MustParse("e3000001-0000-0000-0000-000000000004")
	seedFlowProjNodeEndOkID    = uuid.MustParse("e3000001-0000-0000-0000-000000000005")
	seedFlowProjNodeEndRejID   = uuid.MustParse("e3000001-0000-0000-0000-000000000006")

	// Letters
	seedLetterWelcomeID  = uuid.MustParse("f0000001-0000-0000-0000-000000000001")
	seedLetterApprovalID = uuid.MustParse("f0000001-0000-0000-0000-000000000002")
	seedLetterContractID = uuid.MustParse("f0000001-0000-0000-0000-000000000003")

	// Model definitions
	seedModelClientID = uuid.MustParse("f1000001-0000-0000-0000-000000000001")
	seedModelAssetID  = uuid.MustParse("f1000001-0000-0000-0000-000000000002")

	// Tickets
	seedTicket1ID = uuid.MustParse("a2000001-0000-0000-0000-000000000001")
	seedTicket2ID = uuid.MustParse("a2000001-0000-0000-0000-000000000002")
	seedTicket3ID = uuid.MustParse("a2000001-0000-0000-0000-000000000003")
	seedTicket4ID = uuid.MustParse("a2000001-0000-0000-0000-000000000004")
	seedTicket5ID = uuid.MustParse("a2000001-0000-0000-0000-000000000005")
	seedTicket6ID = uuid.MustParse("a2000001-0000-0000-0000-000000000006")
	seedTicket7ID = uuid.MustParse("a2000001-0000-0000-0000-000000000007")
	seedTicket8ID = uuid.MustParse("a2000001-0000-0000-0000-000000000008")

	// Flow instances
	seedInstanceBugID     = uuid.MustParse("a3000001-0000-0000-0000-000000000001")
	seedInstanceOnbID     = uuid.MustParse("a3000001-0000-0000-0000-000000000002")
	seedInstanceProjectID = uuid.MustParse("a3000001-0000-0000-0000-000000000003")
)

// mustJSONStr marshals v to a JSON string, panicking on error (safe for static seed data).
func mustJSONStr(v interface{}) string {
	b, err := json.Marshal(v)
	if err != nil {
		panic(fmt.Sprintf("seed: mustJSONStr: %v", err))
	}
	return string(b)
}

// hashPassword returns a bcrypt hash of the given password.
func hashPassword(pw string) string {
	h, err := bcrypt.GenerateFromPassword([]byte(pw), bcrypt.DefaultCost)
	if err != nil {
		panic(fmt.Sprintf("seed: bcrypt: %v", err))
	}
	return string(h)
}

// pUUID is a helper that returns a pointer to a uuid.UUID value.
func pUUID(u uuid.UUID) *uuid.UUID { return &u }

// SeedDatabase populates all tables with realistic demo data when the companies
// table is empty. Running it a second time is safe (idempotent via ID checks).
func SeedDatabase(db *gorm.DB, log *zap.Logger) error {
	// Guard: only seed if the company table is empty.
	var count int64
	if err := db.Model(&models.Company{}).Count(&count).Error; err != nil {
		return fmt.Errorf("seed: count companies: %w", err)
	}
	if count > 0 {
		log.Info("seed: database already seeded, skipping")
		return nil
	}

	log.Info("seed: seeding database with demo data…")

	pw := hashPassword("Demo123!")

	// ------------------------------------------------------------------ Company
	company := models.Company{
		BaseModel:   models.BaseModel{ID: seedCompanyID, CreatedAt: daysAgo(90), UpdatedAt: daysAgo(90)},
		Name:        "Horizon Digital Agency",
		Description: "Full-service digital transformation and automation agency serving enterprise clients worldwide",
		OwnerID:     seedUserAlexandraID,
	}
	if err := db.Create(&company).Error; err != nil {
		return fmt.Errorf("seed: create company: %w", err)
	}

	// ------------------------------------------------------------------ Roles
	type permMap = map[string]interface{}
	allCRUD := []permMap{
		{"resource": "companies", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": true},
		{"resource": "users", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": true},
		{"resource": "roles", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": true},
		{"resource": "flows", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": true},
		{"resource": "forms", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": true},
		{"resource": "models", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": true},
		{"resource": "letters", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": true},
		{"resource": "tickets", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": true},
		{"resource": "instances", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": true},
	}
	opsPerm := []permMap{
		{"resource": "companies", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
		{"resource": "users", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": false},
		{"resource": "roles", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
		{"resource": "flows", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": false},
		{"resource": "forms", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": false},
		{"resource": "models", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": false},
		{"resource": "letters", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": false},
		{"resource": "tickets", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": true},
		{"resource": "instances", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": false},
	}
	supportPerm := []permMap{
		{"resource": "companies", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
		{"resource": "users", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
		{"resource": "roles", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
		{"resource": "flows", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
		{"resource": "forms", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
		{"resource": "models", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
		{"resource": "letters", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
		{"resource": "tickets", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": true},
		{"resource": "instances", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
	}
	devPerm := []permMap{
		{"resource": "companies", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
		{"resource": "users", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
		{"resource": "roles", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
		{"resource": "flows", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": true},
		{"resource": "forms", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": true},
		{"resource": "models", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": true},
		{"resource": "letters", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": false},
		{"resource": "tickets", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": false},
		{"resource": "instances", "canCreate": true, "canRead": true, "canUpdate": true, "canDelete": false},
	}
	viewerPerm := []permMap{
		{"resource": "companies", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
		{"resource": "users", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
		{"resource": "roles", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
		{"resource": "flows", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
		{"resource": "forms", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
		{"resource": "models", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
		{"resource": "letters", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
		{"resource": "tickets", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
		{"resource": "instances", "canCreate": false, "canRead": true, "canUpdate": false, "canDelete": false},
	}

	roles := []models.Role{
		{
			BaseModel:   models.BaseModel{ID: seedRoleAdminID, CreatedAt: daysAgo(90), UpdatedAt: daysAgo(90)},
			CompanyID:   seedCompanyID,
			Name:        "Administrator",
			Description: "Full access to all resources and settings",
			Level:       "admin",
			IsActive:    true,
			Permissions: mustJSONStr(allCRUD),
		},
		{
			BaseModel:   models.BaseModel{ID: seedRoleOpsID, CreatedAt: daysAgo(90), UpdatedAt: daysAgo(90)},
			CompanyID:   seedCompanyID,
			Name:        "Operations Manager",
			Description: "Manages day-to-day operations across most resources",
			Level:       "manager",
			IsActive:    true,
			Permissions: mustJSONStr(opsPerm),
		},
		{
			BaseModel:   models.BaseModel{ID: seedRoleSupportID, CreatedAt: daysAgo(90), UpdatedAt: daysAgo(90)},
			CompanyID:   seedCompanyID,
			Name:        "Support Agent",
			Description: "Handles tickets and has read access to most resources",
			Level:       "member",
			IsActive:    true,
			Permissions: mustJSONStr(supportPerm),
		},
		{
			BaseModel:   models.BaseModel{ID: seedRoleDevID, CreatedAt: daysAgo(90), UpdatedAt: daysAgo(90)},
			CompanyID:   seedCompanyID,
			Name:        "Developer",
			Description: "Full access to flows, forms and model definitions",
			Level:       "member",
			IsActive:    true,
			Permissions: mustJSONStr(devPerm),
		},
		{
			BaseModel:   models.BaseModel{ID: seedRoleViewerID, CreatedAt: daysAgo(90), UpdatedAt: daysAgo(90)},
			CompanyID:   seedCompanyID,
			Name:        "Viewer",
			Description: "Read-only access to all resources",
			Level:       "viewer",
			IsActive:    true,
			Permissions: mustJSONStr(viewerPerm),
		},
	}
	if err := db.Create(&roles).Error; err != nil {
		return fmt.Errorf("seed: create roles: %w", err)
	}

	// ------------------------------------------------------------------ Users
	users := []models.User{
		{
			BaseModel:    models.BaseModel{ID: seedUserAlexandraID, CreatedAt: daysAgo(90), UpdatedAt: daysAgo(90)},
			Email:        "admin@horizondigital.com",
			PasswordHash: pw,
			FirstName:    "Alexandra",
			LastName:     "Chen",
			CompanyID:    pUUID(seedCompanyID),
			RoleID:       pUUID(seedRoleAdminID),
			IsActive:     true,
			IsOwner:      true,
		},
		{
			BaseModel:    models.BaseModel{ID: seedUserMarcusID, CreatedAt: daysAgo(85), UpdatedAt: daysAgo(85)},
			Email:        "marcus@horizondigital.com",
			PasswordHash: pw,
			FirstName:    "Marcus",
			LastName:     "Thompson",
			CompanyID:    pUUID(seedCompanyID),
			RoleID:       pUUID(seedRoleOpsID),
			IsActive:     true,
		},
		{
			BaseModel:    models.BaseModel{ID: seedUserSofiaID, CreatedAt: daysAgo(80), UpdatedAt: daysAgo(80)},
			Email:        "sofia@horizondigital.com",
			PasswordHash: pw,
			FirstName:    "Sofia",
			LastName:     "Rodriguez",
			CompanyID:    pUUID(seedCompanyID),
			RoleID:       pUUID(seedRoleSupportID),
			IsActive:     true,
		},
		{
			BaseModel:    models.BaseModel{ID: seedUserJamesID, CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)},
			Email:        "james@horizondigital.com",
			PasswordHash: pw,
			FirstName:    "James",
			LastName:     "Park",
			CompanyID:    pUUID(seedCompanyID),
			RoleID:       pUUID(seedRoleDevID),
			IsActive:     true,
		},
		{
			BaseModel:    models.BaseModel{ID: seedUserEmilyID, CreatedAt: daysAgo(75), UpdatedAt: daysAgo(75)},
			Email:        "emily@horizondigital.com",
			PasswordHash: pw,
			FirstName:    "Emily",
			LastName:     "Watson",
			CompanyID:    pUUID(seedCompanyID),
			RoleID:       pUUID(seedRoleSupportID),
			IsActive:     true,
		},
		{
			BaseModel:    models.BaseModel{ID: seedUserDemoID, CreatedAt: daysAgo(60), UpdatedAt: daysAgo(60)},
			Email:        "demo@autocreat.io",
			PasswordHash: pw,
			FirstName:    "Demo",
			LastName:     "User",
			CompanyID:    pUUID(seedCompanyID),
			RoleID:       pUUID(seedRoleAdminID),
			IsActive:     true,
		},
	}
	if err := db.Create(&users).Error; err != nil {
		return fmt.Errorf("seed: create users: %w", err)
	}

	// Update company owner_id (now the user exists)
	if err := db.Model(&models.Company{}).Where("id = ?", seedCompanyID).
		Update("owner_id", seedUserAlexandraID).Error; err != nil {
		return fmt.Errorf("seed: update company owner: %w", err)
	}

	// CompanyMembers
	members := []models.CompanyMember{
		{CompanyID: seedCompanyID, UserID: seedUserAlexandraID, RoleID: seedRoleAdminID, JoinedAt: daysAgo(90)},
		{CompanyID: seedCompanyID, UserID: seedUserMarcusID, RoleID: seedRoleOpsID, JoinedAt: daysAgo(85)},
		{CompanyID: seedCompanyID, UserID: seedUserSofiaID, RoleID: seedRoleSupportID, JoinedAt: daysAgo(80)},
		{CompanyID: seedCompanyID, UserID: seedUserJamesID, RoleID: seedRoleDevID, JoinedAt: daysAgo(78)},
		{CompanyID: seedCompanyID, UserID: seedUserEmilyID, RoleID: seedRoleSupportID, JoinedAt: daysAgo(75)},
		{CompanyID: seedCompanyID, UserID: seedUserDemoID, RoleID: seedRoleAdminID, JoinedAt: daysAgo(60)},
	}
	if err := db.Create(&members).Error; err != nil {
		return fmt.Errorf("seed: create members: %w", err)
	}

	// ------------------------------------------------------------------ Forms
	type formField struct {
		ID          string   `json:"id"`
		Name        string   `json:"name"`
		Label       string   `json:"label"`
		FieldType   string   `json:"fieldType"`
		Required    bool     `json:"required"`
		Placeholder string   `json:"placeholder,omitempty"`
		Options     []string `json:"options,omitempty"`
		HelpText    string   `json:"helpText,omitempty"`
	}

	onboardingFields := []formField{
		{ID: "ff-onb-001", Name: "full_name", Label: "Full Name", FieldType: "text", Required: true, Placeholder: "Enter your full name"},
		{ID: "ff-onb-002", Name: "department", Label: "Department", FieldType: "select", Required: true, Options: []string{"Engineering", "HR", "Sales", "Marketing", "Operations"}, Placeholder: "Select department"},
		{ID: "ff-onb-003", Name: "start_date", Label: "Start Date", FieldType: "date", Required: true},
		{ID: "ff-onb-004", Name: "remote_work", Label: "Remote Work", FieldType: "checkbox", HelpText: "Check if the employee will work remotely"},
		{ID: "ff-onb-005", Name: "equipment_needs", Label: "Equipment Needs", FieldType: "multiselect", Options: []string{"Laptop", "Monitor", "Headset", "Keyboard", "Mouse"}, HelpText: "Select all required equipment"},
		{ID: "ff-onb-006", Name: "emergency_contact", Label: "Emergency Contact", FieldType: "text", Placeholder: "Name and phone number"},
		{ID: "ff-onb-007", Name: "notes", Label: "Notes", FieldType: "textarea", Placeholder: "Any additional notes…"},
	}
	projectFields := []formField{
		{ID: "ff-proj-001", Name: "project_title", Label: "Project Title", FieldType: "text", Required: true, Placeholder: "Enter project title"},
		{ID: "ff-proj-002", Name: "budget_estimate", Label: "Budget Estimate ($)", FieldType: "number", Required: true, Placeholder: "0"},
		{ID: "ff-proj-003", Name: "timeline", Label: "Timeline", FieldType: "select", Required: true, Options: []string{"1 week", "2 weeks", "1 month", "3 months", "6 months"}},
		{ID: "ff-proj-004", Name: "team_size", Label: "Team Size", FieldType: "number", Placeholder: "Number of people"},
		{ID: "ff-proj-005", Name: "risk_level", Label: "Risk Level", FieldType: "radio", Required: true, Options: []string{"Low", "Medium", "High"}},
		{ID: "ff-proj-006", Name: "description", Label: "Description", FieldType: "textarea", Required: true, Placeholder: "Describe the project…"},
		{ID: "ff-proj-007", Name: "attachments_required", Label: "Attachments Required", FieldType: "checkbox"},
	}
	bugFields := []formField{
		{ID: "ff-bug-001", Name: "bug_title", Label: "Bug Title", FieldType: "text", Required: true, Placeholder: "Brief description of the bug"},
		{ID: "ff-bug-002", Name: "severity", Label: "Severity", FieldType: "select", Required: true, Options: []string{"Critical", "High", "Medium", "Low"}},
		{ID: "ff-bug-003", Name: "module", Label: "Affected Module", FieldType: "select", Options: []string{"Frontend", "Backend", "Database", "API", "Mobile"}},
		{ID: "ff-bug-004", Name: "steps_to_reproduce", Label: "Steps to Reproduce", FieldType: "textarea", Required: true, Placeholder: "1. Go to…\n2. Click…\n3. Observe…"},
		{ID: "ff-bug-005", Name: "expected_behavior", Label: "Expected Behavior", FieldType: "textarea", Placeholder: "What should happen?"},
		{ID: "ff-bug-006", Name: "actual_behavior", Label: "Actual Behavior", FieldType: "textarea", Placeholder: "What actually happens?"},
		{ID: "ff-bug-007", Name: "browser_os", Label: "Browser / OS", FieldType: "text", Placeholder: "Chrome 120 / macOS Sonoma"},
		{ID: "ff-bug-008", Name: "screenshot_url", Label: "Screenshot URL", FieldType: "text", Placeholder: "https://…"},
	}
	feedbackFields := []formField{
		{ID: "ff-fb-001", Name: "client_name", Label: "Client Name", FieldType: "text", Placeholder: "Your name or company"},
		{ID: "ff-fb-002", Name: "rating", Label: "Overall Rating", FieldType: "radio", Required: true, Options: []string{"1 star", "2 stars", "3 stars", "4 stars", "5 stars"}},
		{ID: "ff-fb-003", Name: "service_quality", Label: "Service Quality", FieldType: "select", Options: []string{"Excellent", "Good", "Average", "Poor"}},
		{ID: "ff-fb-004", Name: "response_time", Label: "Response Time", FieldType: "select", Options: []string{"Excellent", "Good", "Average", "Poor"}},
		{ID: "ff-fb-005", Name: "would_recommend", Label: "Would Recommend", FieldType: "checkbox", HelpText: "Check if you would recommend us to others"},
		{ID: "ff-fb-006", Name: "comments", Label: "Comments", FieldType: "textarea", Placeholder: "Share your experience…"},
		{ID: "ff-fb-007", Name: "contact_permission", Label: "May we contact you?", FieldType: "checkbox"},
	}

	forms := []models.FormDefinition{
		{
			BaseModel:   models.BaseModel{ID: seedFormOnboardingID, CreatedAt: daysAgo(80), UpdatedAt: daysAgo(80)},
			CompanyID:   seedCompanyID,
			Name:        "Employee Onboarding Form",
			Description: "Collects essential information for new employee onboarding",
			Fields:      mustJSONStr(onboardingFields),
		},
		{
			BaseModel:   models.BaseModel{ID: seedFormProjectID, CreatedAt: daysAgo(75), UpdatedAt: daysAgo(75)},
			CompanyID:   seedCompanyID,
			Name:        "Project Approval Request",
			Description: "Formal request form for new project approvals",
			Fields:      mustJSONStr(projectFields),
		},
		{
			BaseModel:   models.BaseModel{ID: seedFormBugID, CreatedAt: daysAgo(70), UpdatedAt: daysAgo(70)},
			CompanyID:   seedCompanyID,
			Name:        "Bug Report Form",
			Description: "Structured form for reporting software bugs",
			Fields:      mustJSONStr(bugFields),
		},
		{
			BaseModel:   models.BaseModel{ID: seedFormFeedbackID, CreatedAt: daysAgo(65), UpdatedAt: daysAgo(65)},
			CompanyID:   seedCompanyID,
			Name:        "Client Feedback Survey",
			Description: "Post-engagement client satisfaction survey",
			Fields:      mustJSONStr(feedbackFields),
		},
	}
	if err := db.Create(&forms).Error; err != nil {
		return fmt.Errorf("seed: create forms: %w", err)
	}

	// ------------------------------------------------------------------ Flows
	flows := []models.Flow{
		{
			BaseModel:   models.BaseModel{ID: seedFlowOnboardingID, CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)},
			CompanyID:   seedCompanyID,
			Name:        "Employee Onboarding Process",
			Description: "End-to-end onboarding workflow for new hires",
			Status:      "active",
		},
		{
			BaseModel:   models.BaseModel{ID: seedFlowBugID, CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)},
			CompanyID:   seedCompanyID,
			Name:        "Bug Resolution Workflow",
			Description: "Structured process for triaging and fixing reported bugs",
			Status:      "active",
		},
		{
			BaseModel:   models.BaseModel{ID: seedFlowProjectID, CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)},
			CompanyID:   seedCompanyID,
			Name:        "Client Project Approval",
			Description: "Multi-stage approval pipeline for new client projects",
			Status:      "active",
		},
	}
	if err := db.Create(&flows).Error; err != nil {
		return fmt.Errorf("seed: create flows: %w", err)
	}

	// Flow nodes – Employee Onboarding
	onbNodes := []models.FlowNode{
		{BaseModel: models.BaseModel{ID: seedFlowOnbNodeStartID, CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, Type: models.NodeTypeStart, Label: "Start", X: 100, Y: 300, Width: 160, Height: 60},
		{BaseModel: models.BaseModel{ID: seedFlowOnbNodeHRID, CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, Type: models.NodeTypeStep, Label: "HR Review", X: 320, Y: 300, Width: 160, Height: 60, AssignedRoleID: pUUID(seedRoleOpsID), AssignedFormID: pUUID(seedFormOnboardingID), Description: "HR team reviews onboarding form and verifies information"},
		{BaseModel: models.BaseModel{ID: seedFlowOnbNodeITID, CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, Type: models.NodeTypeStep, Label: "IT Setup", X: 540, Y: 300, Width: 160, Height: 60, AssignedRoleID: pUUID(seedRoleDevID), Description: "IT team sets up equipment and accounts"},
		{BaseModel: models.BaseModel{ID: seedFlowOnbNodeMgrID, CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, Type: models.NodeTypeDecision, Label: "Manager Approval", X: 760, Y: 300, Width: 160, Height: 60, AssignedRoleID: pUUID(seedRoleOpsID), Description: "Manager approves or rejects the onboarding completion"},
		{BaseModel: models.BaseModel{ID: seedFlowOnbNodeWelcomeID, CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, Type: models.NodeTypeStep, Label: "Welcome Meeting", X: 980, Y: 200, Width: 160, Height: 60, AssignedRoleID: pUUID(seedRoleOpsID), Description: "Schedule and conduct welcome meeting"},
		{BaseModel: models.BaseModel{ID: seedFlowOnbNodeEndID, CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, Type: models.NodeTypeEnd, Label: "Onboarding Complete", X: 1200, Y: 300, Width: 160, Height: 60},
	}
	if err := db.Create(&onbNodes).Error; err != nil {
		return fmt.Errorf("seed: create onboarding nodes: %w", err)
	}

	onbEdges := []models.FlowEdge{
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000001-0001-0000-0000-000000000001"), CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, SourceNodeID: seedFlowOnbNodeStartID, TargetNodeID: seedFlowOnbNodeHRID, Label: "Begin"},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000001-0001-0000-0000-000000000002"), CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, SourceNodeID: seedFlowOnbNodeHRID, TargetNodeID: seedFlowOnbNodeITID, Label: "Approved"},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000001-0001-0000-0000-000000000003"), CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, SourceNodeID: seedFlowOnbNodeITID, TargetNodeID: seedFlowOnbNodeMgrID, Label: "Setup Done"},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000001-0001-0000-0000-000000000004"), CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, SourceNodeID: seedFlowOnbNodeMgrID, TargetNodeID: seedFlowOnbNodeWelcomeID, Label: "Yes", ConditionID: "approved"},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000001-0001-0000-0000-000000000005"), CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, SourceNodeID: seedFlowOnbNodeMgrID, TargetNodeID: seedFlowOnbNodeHRID, Label: "No", ConditionID: "rejected"},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000001-0001-0000-0000-000000000006"), CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, SourceNodeID: seedFlowOnbNodeWelcomeID, TargetNodeID: seedFlowOnbNodeEndID, Label: "Done"},
	}
	if err := db.Create(&onbEdges).Error; err != nil {
		return fmt.Errorf("seed: create onboarding edges: %w", err)
	}

	// Flow nodes – Bug Resolution
	bugNodes := []models.FlowNode{
		{BaseModel: models.BaseModel{ID: seedFlowBugNodeStartID, CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)}, FlowID: seedFlowBugID, Type: models.NodeTypeStart, Label: "Start", X: 100, Y: 300, Width: 160, Height: 60},
		{BaseModel: models.BaseModel{ID: seedFlowBugNodeTriageID, CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)}, FlowID: seedFlowBugID, Type: models.NodeTypeStep, Label: "Triage", X: 320, Y: 300, Width: 160, Height: 60, AssignedRoleID: pUUID(seedRoleSupportID), AssignedFormID: pUUID(seedFormBugID), Description: "Support agent triages and categorises the bug"},
		{BaseModel: models.BaseModel{ID: seedFlowBugNodeDevID, CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)}, FlowID: seedFlowBugID, Type: models.NodeTypeStep, Label: "Developer Fix", X: 540, Y: 300, Width: 160, Height: 60, AssignedRoleID: pUUID(seedRoleDevID), Description: "Developer investigates and applies a fix"},
		{BaseModel: models.BaseModel{ID: seedFlowBugNodeQAID, CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)}, FlowID: seedFlowBugID, Type: models.NodeTypeDecision, Label: "QA Review", X: 760, Y: 300, Width: 160, Height: 60, Description: "QA verifies the fix"},
		{BaseModel: models.BaseModel{ID: seedFlowBugNodeEndID, CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)}, FlowID: seedFlowBugID, Type: models.NodeTypeEnd, Label: "Resolved", X: 980, Y: 300, Width: 160, Height: 60},
	}
	if err := db.Create(&bugNodes).Error; err != nil {
		return fmt.Errorf("seed: create bug nodes: %w", err)
	}

	bugEdges := []models.FlowEdge{
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000002-0001-0000-0000-000000000001"), CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)}, FlowID: seedFlowBugID, SourceNodeID: seedFlowBugNodeStartID, TargetNodeID: seedFlowBugNodeTriageID, Label: "Report Filed"},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000002-0001-0000-0000-000000000002"), CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)}, FlowID: seedFlowBugID, SourceNodeID: seedFlowBugNodeTriageID, TargetNodeID: seedFlowBugNodeDevID, Label: "Confirmed"},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000002-0001-0000-0000-000000000003"), CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)}, FlowID: seedFlowBugID, SourceNodeID: seedFlowBugNodeDevID, TargetNodeID: seedFlowBugNodeQAID, Label: "Fixed"},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000002-0001-0000-0000-000000000004"), CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)}, FlowID: seedFlowBugID, SourceNodeID: seedFlowBugNodeQAID, TargetNodeID: seedFlowBugNodeEndID, Label: "Passed", ConditionID: "approved"},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000002-0001-0000-0000-000000000005"), CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)}, FlowID: seedFlowBugID, SourceNodeID: seedFlowBugNodeQAID, TargetNodeID: seedFlowBugNodeDevID, Label: "Failed", ConditionID: "rejected"},
	}
	if err := db.Create(&bugEdges).Error; err != nil {
		return fmt.Errorf("seed: create bug edges: %w", err)
	}

	// Flow nodes – Project Approval
	projNodes := []models.FlowNode{
		{BaseModel: models.BaseModel{ID: seedFlowProjNodeStartID, CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, Type: models.NodeTypeStart, Label: "Start", X: 100, Y: 300, Width: 160, Height: 60},
		{BaseModel: models.BaseModel{ID: seedFlowProjNodeReviewID, CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, Type: models.NodeTypeStep, Label: "Initial Review", X: 320, Y: 300, Width: 160, Height: 60, AssignedRoleID: pUUID(seedRoleOpsID), AssignedFormID: pUUID(seedFormProjectID), Description: "Operations Manager performs initial project review"},
		{BaseModel: models.BaseModel{ID: seedFlowProjNodeDirectorID, CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, Type: models.NodeTypeDecision, Label: "Director Approval", X: 540, Y: 300, Width: 160, Height: 60, AssignedRoleID: pUUID(seedRoleAdminID), Description: "Director makes final approval decision"},
		{BaseModel: models.BaseModel{ID: seedFlowProjNodeContractID, CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, Type: models.NodeTypeStep, Label: "Contract Sent", X: 760, Y: 200, Width: 160, Height: 60, AssignedRoleID: pUUID(seedRoleOpsID), Description: "Ops manager sends contract to client"},
		{BaseModel: models.BaseModel{ID: seedFlowProjNodeEndOkID, CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, Type: models.NodeTypeEnd, Label: "Project Approved", X: 980, Y: 200, Width: 160, Height: 60},
		{BaseModel: models.BaseModel{ID: seedFlowProjNodeEndRejID, CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, Type: models.NodeTypeEnd, Label: "Project Rejected", X: 760, Y: 400, Width: 160, Height: 60},
	}
	if err := db.Create(&projNodes).Error; err != nil {
		return fmt.Errorf("seed: create project nodes: %w", err)
	}

	projEdges := []models.FlowEdge{
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000003-0001-0000-0000-000000000001"), CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, SourceNodeID: seedFlowProjNodeStartID, TargetNodeID: seedFlowProjNodeReviewID, Label: "Request Submitted"},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000003-0001-0000-0000-000000000002"), CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, SourceNodeID: seedFlowProjNodeReviewID, TargetNodeID: seedFlowProjNodeDirectorID, Label: "Review Complete"},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000003-0001-0000-0000-000000000003"), CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, SourceNodeID: seedFlowProjNodeDirectorID, TargetNodeID: seedFlowProjNodeContractID, Label: "Approved", ConditionID: "approved"},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000003-0001-0000-0000-000000000004"), CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, SourceNodeID: seedFlowProjNodeDirectorID, TargetNodeID: seedFlowProjNodeEndRejID, Label: "Rejected", ConditionID: "rejected"},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000003-0001-0000-0000-000000000005"), CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, SourceNodeID: seedFlowProjNodeContractID, TargetNodeID: seedFlowProjNodeEndOkID, Label: "Done"},
	}
	if err := db.Create(&projEdges).Error; err != nil {
		return fmt.Errorf("seed: create project edges: %w", err)
	}

	// ------------------------------------------------------------------ Letter Templates
	welcomeDelta := map[string]interface{}{
		"ops": []interface{}{
			map[string]interface{}{"insert": "Welcome to "},
			map[string]interface{}{"insert": "{{company.name}}", "attributes": map[string]interface{}{"bold": true}},
			map[string]interface{}{"insert": "!\n\nDear "},
			map[string]interface{}{"insert": "{{user.name}}", "attributes": map[string]interface{}{"bold": true}},
			map[string]interface{}{"insert": ",\n\nWe are thrilled to have you join our team. Your start date is confirmed as "},
			map[string]interface{}{"insert": "{{start_date}}", "attributes": map[string]interface{}{"italic": true}},
			map[string]interface{}{"insert": ".\n\nWarm regards,\nAlexandra Chen\nCEO, Horizon Digital Agency\n"},
		},
	}
	approvalDelta := map[string]interface{}{
		"ops": []interface{}{
			map[string]interface{}{"insert": "Project Approval Notice\n", "attributes": map[string]interface{}{"bold": true}},
			map[string]interface{}{"insert": "\nDear "},
			map[string]interface{}{"insert": "{{requester.name}}", "attributes": map[string]interface{}{"bold": true}},
			map[string]interface{}{"insert": ",\n\nYour project \"{{project.title}}\" has been approved. Budget: ${{project.budget}}.\n\nBest regards,\nMarcus Thompson\nOperations Manager\n"},
		},
	}
	contractDelta := map[string]interface{}{
		"ops": []interface{}{
			map[string]interface{}{"insert": "Service Agreement\n", "attributes": map[string]interface{}{"bold": true}},
			map[string]interface{}{"insert": "\nThis Agreement is entered into as of "},
			map[string]interface{}{"insert": "{{contract_date}}", "attributes": map[string]interface{}{"italic": true}},
			map[string]interface{}{"insert": " between Horizon Digital Agency and "},
			map[string]interface{}{"insert": "{{client.company_name}}", "attributes": map[string]interface{}{"bold": true}},
			map[string]interface{}{"insert": ".\n\nScope: {{service_description}}\nValue: ${{contract_value}}\nTerm: {{start_date}} – {{end_date}}\n"},
		},
	}

	letters := []models.LetterTemplate{
		{
			BaseModel:    models.BaseModel{ID: seedLetterWelcomeID, CreatedAt: daysAgo(77), UpdatedAt: daysAgo(77)},
			CompanyID:    seedCompanyID,
			Name:         "Welcome Letter",
			Description:  "Sent to new employees on their first day",
			Content:      "Welcome to {{company.name}}!\n\nDear {{user.name}},\n\nWe are thrilled to have you join our team. Your start date is confirmed as {{start_date}}.\n\nWarm regards,\nAlexandra Chen",
			DeltaContent: mustJSONStr(welcomeDelta),
			Variables:    mustJSONStr([]string{"company.name", "user.name", "start_date", "manager.name"}),
			Status:       "active",
			Category:     "onboarding",
		},
		{
			BaseModel:    models.BaseModel{ID: seedLetterApprovalID, CreatedAt: daysAgo(73), UpdatedAt: daysAgo(73)},
			CompanyID:    seedCompanyID,
			Name:         "Project Approval Notice",
			Description:  "Formal notification of project approval",
			Content:      "Dear {{requester.name}},\n\nYour project \"{{project.title}}\" has been approved. Budget: ${{project.budget}}.\n\nBest regards,\nMarcus Thompson",
			DeltaContent: mustJSONStr(approvalDelta),
			Variables:    mustJSONStr([]string{"requester.name", "project.title", "project.budget", "project.timeline", "approval_date"}),
			Status:       "active",
			Category:     "approval",
		},
		{
			BaseModel:    models.BaseModel{ID: seedLetterContractID, CreatedAt: daysAgo(69), UpdatedAt: daysAgo(69)},
			CompanyID:    seedCompanyID,
			Name:         "Contract Template",
			Description:  "Standard service agreement contract for client engagements",
			Content:      "Service Agreement\n\nThis Agreement is entered into as of {{contract_date}} between Horizon Digital Agency and {{client.company_name}}.\n\nScope: {{service_description}}\nValue: ${{contract_value}}\nTerm: {{start_date}} – {{end_date}}",
			DeltaContent: mustJSONStr(contractDelta),
			Variables:    mustJSONStr([]string{"contract_date", "client.company_name", "service_description", "contract_value", "start_date", "end_date"}),
			Status:       "active",
			Category:     "contract",
		},
	}
	if err := db.Create(&letters).Error; err != nil {
		return fmt.Errorf("seed: create letter templates: %w", err)
	}

	// ------------------------------------------------------------------ Model Definitions
	type modelField struct {
		ID       string `json:"id"`
		Name     string `json:"name"`
		Label    string `json:"label"`
		Type     string `json:"type"`
		Required bool   `json:"required"`
	}
	clientFields := []modelField{
		{ID: "mf-cl-001", Name: "company_name", Label: "Company Name", Type: "text", Required: true},
		{ID: "mf-cl-002", Name: "industry", Label: "Industry", Type: "text"},
		{ID: "mf-cl-003", Name: "contact_email", Label: "Contact Email", Type: "email"},
		{ID: "mf-cl-004", Name: "annual_revenue", Label: "Annual Revenue ($)", Type: "number"},
		{ID: "mf-cl-005", Name: "contract_value", Label: "Contract Value ($)", Type: "number"},
		{ID: "mf-cl-006", Name: "status", Label: "Status", Type: "text"},
		{ID: "mf-cl-007", Name: "notes", Label: "Notes", Type: "text"},
	}
	assetFields := []modelField{
		{ID: "mf-as-001", Name: "asset_name", Label: "Asset Name", Type: "text", Required: true},
		{ID: "mf-as-002", Name: "asset_type", Label: "Asset Type", Type: "text"},
		{ID: "mf-as-003", Name: "serial_number", Label: "Serial Number", Type: "text"},
		{ID: "mf-as-004", Name: "assigned_to", Label: "Assigned To", Type: "text"},
		{ID: "mf-as-005", Name: "purchase_date", Label: "Purchase Date", Type: "date"},
		{ID: "mf-as-006", Name: "warranty_expiry", Label: "Warranty Expiry", Type: "date"},
		{ID: "mf-as-007", Name: "value", Label: "Value ($)", Type: "number"},
		{ID: "mf-as-008", Name: "location", Label: "Location", Type: "text"},
	}

	modelDefs := []models.ModelDefinition{
		{
			BaseModel:   models.BaseModel{ID: seedModelClientID, CreatedAt: daysAgo(66), UpdatedAt: daysAgo(66)},
			CompanyID:   seedCompanyID,
			Name:        "Client",
			Description: "CRM-style client/customer records",
			Fields:      mustJSONStr(clientFields),
		},
		{
			BaseModel:   models.BaseModel{ID: seedModelAssetID, CreatedAt: daysAgo(64), UpdatedAt: daysAgo(64)},
			CompanyID:   seedCompanyID,
			Name:        "Asset",
			Description: "Tracks company hardware and digital assets",
			Fields:      mustJSONStr(assetFields),
		},
	}
	if err := db.Create(&modelDefs).Error; err != nil {
		return fmt.Errorf("seed: create model definitions: %w", err)
	}

	// ------------------------------------------------------------------ Tickets + Messages
	marcusIDp := pUUID(seedUserMarcusID)
	jamesIDp := pUUID(seedUserJamesID)

	tickets := []models.Ticket{
		{
			BaseModel:  models.BaseModel{ID: seedTicket1ID, CreatedAt: daysAgo(45), UpdatedAt: daysAgo(44)},
			CompanyID:  seedCompanyID,
			Title:      "Cannot access company dashboard",
			Status:     models.TicketStatusOpen,
			Priority:   models.TicketPriorityHigh,
			CreatorID:  seedUserSofiaID,
			AssigneeID: marcusIDp,
		},
		{
			BaseModel:  models.BaseModel{ID: seedTicket2ID, CreatedAt: daysAgo(40), UpdatedAt: daysAgo(38)},
			CompanyID:  seedCompanyID,
			Title:      "Flow editor crashes on save",
			Status:     models.TicketStatusInProgress,
			Priority:   models.TicketPriorityUrgent,
			CreatorID:  seedUserJamesID,
			AssigneeID: jamesIDp,
		},
		{
			BaseModel: models.BaseModel{ID: seedTicket3ID, CreatedAt: daysAgo(38), UpdatedAt: daysAgo(37)},
			CompanyID: seedCompanyID,
			Title:     "Request: Add bulk user import feature",
			Status:    models.TicketStatusOpen,
			Priority:  models.TicketPriorityMedium,
			CreatorID: seedUserEmilyID,
		},
		{
			BaseModel:  models.BaseModel{ID: seedTicket4ID, CreatedAt: daysAgo(55), UpdatedAt: daysAgo(20)},
			CompanyID:  seedCompanyID,
			Title:      "Performance issues in ticket list view",
			Status:     models.TicketStatusClosed,
			Priority:   models.TicketPriorityMedium,
			CreatorID:  seedUserMarcusID,
			AssigneeID: jamesIDp,
		},
		{
			BaseModel:  models.BaseModel{ID: seedTicket5ID, CreatedAt: daysAgo(30), UpdatedAt: daysAgo(28)},
			CompanyID:  seedCompanyID,
			Title:      "Form submission not saving data",
			Status:     models.TicketStatusInProgress,
			Priority:   models.TicketPriorityHigh,
			CreatorID:  seedUserSofiaID,
			AssigneeID: jamesIDp,
		},
		{
			BaseModel: models.BaseModel{ID: seedTicket6ID, CreatedAt: daysAgo(25), UpdatedAt: daysAgo(24)},
			CompanyID: seedCompanyID,
			Title:     "Integration with Slack notifications",
			Status:    models.TicketStatusOpen,
			Priority:  models.TicketPriorityLow,
			CreatorID: seedUserMarcusID,
		},
		{
			BaseModel:  models.BaseModel{ID: seedTicket7ID, CreatedAt: daysAgo(60), UpdatedAt: daysAgo(15)},
			CompanyID:  seedCompanyID,
			Title:      "User role permissions not applying correctly",
			Status:     models.TicketStatusClosed,
			Priority:   models.TicketPriorityHigh,
			CreatorID:  seedUserEmilyID,
			AssigneeID: marcusIDp,
		},
		{
			BaseModel:  models.BaseModel{ID: seedTicket8ID, CreatedAt: daysAgo(10), UpdatedAt: daysAgo(9)},
			CompanyID:  seedCompanyID,
			Title:      "Generate letter template not working",
			Status:     models.TicketStatusInProgress,
			Priority:   models.TicketPriorityHigh,
			CreatorID:  seedUserSofiaID,
			AssigneeID: jamesIDp,
		},
	}
	if err := db.Create(&tickets).Error; err != nil {
		return fmt.Errorf("seed: create tickets: %w", err)
	}

	emptyAttach := "[]"
	messages := []models.TicketMessage{
		// Ticket 1 – Cannot access company dashboard (3 messages)
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000001-0001-0000-0000-000000000001"), CreatedAt: daysAgo(45), UpdatedAt: daysAgo(45)}, TicketID: seedTicket1ID, SenderID: seedUserSofiaID, Content: "Hi team, I've been unable to access the company dashboard since this morning. When I navigate to it I get a blank white screen. I've tried refreshing and clearing cache but the issue persists.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000001-0001-0000-0000-000000000002"), CreatedAt: daysAgo(44), UpdatedAt: daysAgo(44)}, TicketID: seedTicket1ID, SenderID: seedUserMarcusID, Content: "Thanks for reporting this, Sofia. I can reproduce the issue from my end too for the support agent role. It looks like a recent permission change might be blocking dashboard access. I'll investigate.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000001-0001-0000-0000-000000000003"), CreatedAt: daysAgo(44), UpdatedAt: daysAgo(44)}, TicketID: seedTicket1ID, SenderID: seedUserSofiaID, Content: "Thank you Marcus. Just to confirm – the issue is only happening on the dashboard page. All other pages like Tickets and Forms load fine for me.", Attachments: emptyAttach},

		// Ticket 2 – Flow editor crashes on save (4 messages)
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000002-0001-0000-0000-000000000001"), CreatedAt: daysAgo(40), UpdatedAt: daysAgo(40)}, TicketID: seedTicket2ID, SenderID: seedUserJamesID, Content: "I've found a critical bug in the flow editor. When you have more than 8 nodes and try to save the graph, the browser throws a 413 Payload Too Large error and the save fails.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000002-0001-0000-0000-000000000002"), CreatedAt: daysAgo(39), UpdatedAt: daysAgo(39)}, TicketID: seedTicket2ID, SenderID: seedUserAlexandraID, Content: "This is a blocker for the onboarding flow we're building. James, can you look into increasing the payload limit?", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000002-0001-0000-0000-000000000003"), CreatedAt: daysAgo(38), UpdatedAt: daysAgo(38)}, TicketID: seedTicket2ID, SenderID: seedUserJamesID, Content: "I've identified two fixes: (1) increase nginx client_max_body_size to 10mb, and (2) add server-side pagination to the graph load endpoint. Implementing both now. ETA: today.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000002-0001-0000-0000-000000000004"), CreatedAt: daysAgo(38), UpdatedAt: daysAgo(38)}, TicketID: seedTicket2ID, SenderID: seedUserJamesID, Content: "Fix deployed to staging. Testing confirmed flows with 15+ nodes save correctly. Will deploy to production after QA sign-off.", Attachments: emptyAttach},

		// Ticket 3 – Bulk user import (2 messages)
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000003-0001-0000-0000-000000000001"), CreatedAt: daysAgo(38), UpdatedAt: daysAgo(38)}, TicketID: seedTicket3ID, SenderID: seedUserEmilyID, Content: "Feature request: We need a way to bulk-import users from a CSV file. We have a new client with 150 employees to onboard and creating them one-by-one is not feasible.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000003-0001-0000-0000-000000000002"), CreatedAt: daysAgo(37), UpdatedAt: daysAgo(37)}, TicketID: seedTicket3ID, SenderID: seedUserMarcusID, Content: "Great idea Emily. I'm adding this to our Q2 roadmap. We'll design the CSV schema to include: full_name, email, role_name, and an optional password.", Attachments: emptyAttach},

		// Ticket 4 – Performance issues (5 messages)
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000004-0001-0000-0000-000000000001"), CreatedAt: daysAgo(55), UpdatedAt: daysAgo(55)}, TicketID: seedTicket4ID, SenderID: seedUserMarcusID, Content: "The ticket list page is very slow when there are more than 200 tickets. Initial load takes 8+ seconds.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000004-0001-0000-0000-000000000002"), CreatedAt: daysAgo(52), UpdatedAt: daysAgo(52)}, TicketID: seedTicket4ID, SenderID: seedUserJamesID, Content: "I'll add pagination (default 50/page), add a DB index on company_id+status, and change messages to lazy-load.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000004-0001-0000-0000-000000000003"), CreatedAt: daysAgo(50), UpdatedAt: daysAgo(50)}, TicketID: seedTicket4ID, SenderID: seedUserMarcusID, Content: "Any ETA? This is really impacting the support team's productivity.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000004-0001-0000-0000-000000000004"), CreatedAt: daysAgo(22), UpdatedAt: daysAgo(22)}, TicketID: seedTicket4ID, SenderID: seedUserJamesID, Content: "Deployed fix: added pagination, DB indexes, and lazy-load for messages. List load time is now under 300ms for 500+ tickets.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000004-0001-0000-0000-000000000005"), CreatedAt: daysAgo(20), UpdatedAt: daysAgo(20)}, TicketID: seedTicket4ID, SenderID: seedUserMarcusID, Content: "Confirmed – ticket list is lightning fast now. Closing this ticket. Great work James!", Attachments: emptyAttach},

		// Ticket 5 – Form submission not saving (3 messages)
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000005-0001-0000-0000-000000000001"), CreatedAt: daysAgo(30), UpdatedAt: daysAgo(30)}, TicketID: seedTicket5ID, SenderID: seedUserSofiaID, Content: "When I complete a form within a flow instance and click Submit, I get a success toast but when I reload the instance the form data is missing.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000005-0001-0000-0000-000000000002"), CreatedAt: daysAgo(29), UpdatedAt: daysAgo(29)}, TicketID: seedTicket5ID, SenderID: seedUserJamesID, Content: "Reproducing now. The issue looks like a race condition – the frontend sends the form submission and immediately advances the instance step before the DB write completes.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000005-0001-0000-0000-000000000003"), CreatedAt: daysAgo(28), UpdatedAt: daysAgo(28)}, TicketID: seedTicket5ID, SenderID: seedUserSofiaID, Content: "Thanks James. Can you let me know when the fix is deployed so I can retest?", Attachments: emptyAttach},

		// Ticket 6 – Slack integration (2 messages)
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000006-0001-0000-0000-000000000001"), CreatedAt: daysAgo(25), UpdatedAt: daysAgo(25)}, TicketID: seedTicket6ID, SenderID: seedUserMarcusID, Content: "Would love to have Slack notifications when a ticket is assigned or a flow instance reaches a step requiring action.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000006-0001-0000-0000-000000000002"), CreatedAt: daysAgo(24), UpdatedAt: daysAgo(24)}, TicketID: seedTicket6ID, SenderID: seedUserAlexandraID, Content: "Agreed – a webhook/integration system is on our roadmap. I've added Slack as the first integration target for Q3.", Attachments: emptyAttach},

		// Ticket 7 – Role permissions (4 messages)
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000007-0001-0000-0000-000000000001"), CreatedAt: daysAgo(60), UpdatedAt: daysAgo(60)}, TicketID: seedTicket7ID, SenderID: seedUserEmilyID, Content: "The Viewer role isn't restricting access properly. Users with the Viewer role can still click the 'Create Ticket' button.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000007-0001-0000-0000-000000000002"), CreatedAt: daysAgo(58), UpdatedAt: daysAgo(58)}, TicketID: seedTicket7ID, SenderID: seedUserMarcusID, Content: "Confirmed. The backend is correctly rejecting the create request (403 Forbidden), but the frontend isn't reading the permissions from the JWT claims to hide the button.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000007-0001-0000-0000-000000000003"), CreatedAt: daysAgo(17), UpdatedAt: daysAgo(17)}, TicketID: seedTicket7ID, SenderID: seedUserMarcusID, Content: "Fix deployed: the frontend now reads the permissions object from user context and conditionally renders action buttons.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000007-0001-0000-0000-000000000004"), CreatedAt: daysAgo(15), UpdatedAt: daysAgo(15)}, TicketID: seedTicket7ID, SenderID: seedUserEmilyID, Content: "Tested with a Viewer account – all create/edit/delete buttons are properly hidden. Closing this ticket.", Attachments: emptyAttach},

		// Ticket 8 – Letter generation (3 messages)
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000008-0001-0000-0000-000000000001"), CreatedAt: daysAgo(10), UpdatedAt: daysAgo(10)}, TicketID: seedTicket8ID, SenderID: seedUserSofiaID, Content: "When I try to generate a letter from the Welcome Letter template, I click 'Generate' and the page just spins indefinitely. No error message is shown.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000008-0001-0000-0000-000000000002"), CreatedAt: daysAgo(9), UpdatedAt: daysAgo(9)}, TicketID: seedTicket8ID, SenderID: seedUserJamesID, Content: "Found the issue. The letter generation endpoint is treating the Quill delta JSON as a plain string. The variable substitution then fails silently. Fix incoming.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000008-0001-0000-0000-000000000003"), CreatedAt: daysAgo(9), UpdatedAt: daysAgo(9)}, TicketID: seedTicket8ID, SenderID: seedUserSofiaID, Content: "Thanks James – any idea on ETA? We have 3 new employees starting next week and need to get their welcome letters out.", Attachments: emptyAttach},
	}
	if err := db.Create(&messages).Error; err != nil {
		return fmt.Errorf("seed: create ticket messages: %w", err)
	}

	// ------------------------------------------------------------------ Flow Instances
	completedAt := daysAgo(50)
	instances := []models.FlowInstance{
		{
			BaseModel:     models.BaseModel{ID: seedInstanceBugID, CreatedAt: daysAgo(35), UpdatedAt: daysAgo(33)},
			FlowID:        seedFlowBugID,
			CurrentNodeID: pUUID(seedFlowBugNodeDevID),
			Status:        models.InstanceStatusActive,
			StartedByID:   seedUserSofiaID,
			CompanyID:     seedCompanyID,
		},
		{
			BaseModel:     models.BaseModel{ID: seedInstanceOnbID, CreatedAt: daysAgo(70), UpdatedAt: daysAgo(50)},
			FlowID:        seedFlowOnboardingID,
			CurrentNodeID: pUUID(seedFlowOnbNodeEndID),
			Status:        models.InstanceStatusCompleted,
			StartedByID:   seedUserAlexandraID,
			CompanyID:     seedCompanyID,
		},
		{
			BaseModel:     models.BaseModel{ID: seedInstanceProjectID, CreatedAt: daysAgo(20), UpdatedAt: daysAgo(18)},
			FlowID:        seedFlowProjectID,
			CurrentNodeID: pUUID(seedFlowProjNodeDirectorID),
			Status:        models.InstanceStatusActive,
			StartedByID:   seedUserMarcusID,
			CompanyID:     seedCompanyID,
		},
	}
	if err := db.Create(&instances).Error; err != nil {
		return fmt.Errorf("seed: create flow instances: %w", err)
	}

	// Instance steps for the completed onboarding instance
	steps := []models.FlowInstanceStep{
		{
			BaseModel:        models.BaseModel{ID: uuid.MustParse("cc000001-0001-0000-0000-000000000001"), CreatedAt: daysAgo(70), UpdatedAt: daysAgo(68)},
			FlowInstanceID:   seedInstanceOnbID,
			NodeID:           seedFlowOnbNodeHRID,
			Status:           models.StepStatusCompleted,
			AssignedToRoleID: pUUID(seedRoleOpsID),
			CompletedAt:      &completedAt,
		},
		{
			BaseModel:        models.BaseModel{ID: uuid.MustParse("cc000001-0001-0000-0000-000000000002"), CreatedAt: daysAgo(68), UpdatedAt: daysAgo(65)},
			FlowInstanceID:   seedInstanceOnbID,
			NodeID:           seedFlowOnbNodeITID,
			Status:           models.StepStatusCompleted,
			AssignedToRoleID: pUUID(seedRoleDevID),
			CompletedAt:      &completedAt,
		},
		{
			BaseModel:        models.BaseModel{ID: uuid.MustParse("cc000001-0001-0000-0000-000000000003"), CreatedAt: daysAgo(65), UpdatedAt: daysAgo(62)},
			FlowInstanceID:   seedInstanceOnbID,
			NodeID:           seedFlowOnbNodeMgrID,
			Status:           models.StepStatusCompleted,
			AssignedToRoleID: pUUID(seedRoleOpsID),
			CompletedAt:      &completedAt,
		},
		{
			BaseModel:        models.BaseModel{ID: uuid.MustParse("cc000001-0001-0000-0000-000000000004"), CreatedAt: daysAgo(62), UpdatedAt: daysAgo(58)},
			FlowInstanceID:   seedInstanceOnbID,
			NodeID:           seedFlowOnbNodeWelcomeID,
			Status:           models.StepStatusCompleted,
			AssignedToRoleID: pUUID(seedRoleOpsID),
			CompletedAt:      &completedAt,
		},
	}
	if err := db.Create(&steps).Error; err != nil {
		return fmt.Errorf("seed: create flow instance steps: %w", err)
	}

	log.Info("seed: database seeded successfully",
		zap.Int("roles", len(roles)),
		zap.Int("users", len(users)),
		zap.Int("forms", len(forms)),
		zap.Int("flows", len(flows)),
		zap.Int("letters", len(letters)),
		zap.Int("model_defs", len(modelDefs)),
		zap.Int("tickets", len(tickets)),
		zap.Int("instances", len(instances)),
	)
	return nil
}

// daysAgo returns a time.Time that is n days before now (UTC midnight).
func daysAgo(n int) time.Time {
	return time.Now().UTC().Truncate(24*time.Hour).AddDate(0, 0, -n)
}
