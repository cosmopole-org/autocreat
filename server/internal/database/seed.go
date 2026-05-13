package database

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/autocreat/server/internal/models"
	"github.com/google/uuid"
	"go.uber.org/zap"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/datatypes"
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
	seedUserDemoID      = uuid.MustParse("c0000001-0000-0000-0000-000000000006")

	// Forms
	seedFormOnboardingID  = uuid.MustParse("d0000001-0000-0000-0000-000000000001")
	seedFormProjectID     = uuid.MustParse("d0000001-0000-0000-0000-000000000002")
	seedFormBugID         = uuid.MustParse("d0000001-0000-0000-0000-000000000003")
	seedFormFeedbackID    = uuid.MustParse("d0000001-0000-0000-0000-000000000004")

	// Flows
	seedFlowOnboardingID = uuid.MustParse("e0000001-0000-0000-0000-000000000001")
	seedFlowBugID        = uuid.MustParse("e0000001-0000-0000-0000-000000000002")
	seedFlowProjectID    = uuid.MustParse("e0000001-0000-0000-0000-000000000003")

	// Flow nodes – Onboarding
	seedFlowOnbNodeStartID    = uuid.MustParse("e1000001-0000-0000-0000-000000000001")
	seedFlowOnbNodeHRID       = uuid.MustParse("e1000001-0000-0000-0000-000000000002")
	seedFlowOnbNodeITID       = uuid.MustParse("e1000001-0000-0000-0000-000000000003")
	seedFlowOnbNodeMgrID      = uuid.MustParse("e1000001-0000-0000-0000-000000000004")
	seedFlowOnbNodeWelcomeID  = uuid.MustParse("e1000001-0000-0000-0000-000000000005")
	seedFlowOnbNodeEndID      = uuid.MustParse("e1000001-0000-0000-0000-000000000006")

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
	seedLetterWelcomeID   = uuid.MustParse("f0000001-0000-0000-0000-000000000001")
	seedLetterApprovalID  = uuid.MustParse("f0000001-0000-0000-0000-000000000002")
	seedLetterContractID  = uuid.MustParse("f0000001-0000-0000-0000-000000000003")

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
	seedInstanceBugID      = uuid.MustParse("a3000001-0000-0000-0000-000000000001")
	seedInstanceOnbID      = uuid.MustParse("a3000001-0000-0000-0000-000000000002")
	seedInstanceProjectID  = uuid.MustParse("a3000001-0000-0000-0000-000000000003")
)

// mustJSON marshals v to datatypes.JSON, panicking on error (safe for static seed data).
func mustJSON(v interface{}) datatypes.JSON {
	b, err := json.Marshal(v)
	if err != nil {
		panic(fmt.Sprintf("seed: mustJSON: %v", err))
	}
	return datatypes.JSON(b)
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
	allCRUD := permMap{
		"companies": permMap{"create": true, "read": true, "update": true, "delete": true},
		"users":     permMap{"create": true, "read": true, "update": true, "delete": true},
		"roles":     permMap{"create": true, "read": true, "update": true, "delete": true},
		"flows":     permMap{"create": true, "read": true, "update": true, "delete": true},
		"forms":     permMap{"create": true, "read": true, "update": true, "delete": true},
		"models":    permMap{"create": true, "read": true, "update": true, "delete": true},
		"letters":   permMap{"create": true, "read": true, "update": true, "delete": true},
		"tickets":   permMap{"create": true, "read": true, "update": true, "delete": true},
		"instances": permMap{"create": true, "read": true, "update": true, "delete": true},
	}
	opsPerm := permMap{
		"companies": permMap{"read": true},
		"users":     permMap{"create": true, "read": true, "update": true},
		"roles":     permMap{"read": true},
		"flows":     permMap{"create": true, "read": true, "update": true},
		"forms":     permMap{"create": true, "read": true, "update": true},
		"models":    permMap{"create": true, "read": true, "update": true},
		"letters":   permMap{"create": true, "read": true, "update": true},
		"tickets":   permMap{"create": true, "read": true, "update": true, "delete": true},
		"instances": permMap{"create": true, "read": true, "update": true},
	}
	supportPerm := permMap{
		"companies": permMap{"read": true},
		"users":     permMap{"read": true},
		"roles":     permMap{"read": true},
		"flows":     permMap{"read": true},
		"forms":     permMap{"read": true},
		"models":    permMap{"read": true},
		"letters":   permMap{"read": true},
		"tickets":   permMap{"create": true, "read": true, "update": true, "delete": true},
		"instances": permMap{"read": true},
	}
	devPerm := permMap{
		"companies": permMap{"read": true},
		"users":     permMap{"read": true},
		"roles":     permMap{"read": true},
		"flows":     permMap{"create": true, "read": true, "update": true, "delete": true},
		"forms":     permMap{"create": true, "read": true, "update": true, "delete": true},
		"models":    permMap{"create": true, "read": true, "update": true, "delete": true},
		"letters":   permMap{"create": true, "read": true, "update": true},
		"tickets":   permMap{"create": true, "read": true, "update": true},
		"instances": permMap{"create": true, "read": true, "update": true},
	}
	viewerPerm := permMap{
		"companies": permMap{"read": true},
		"users":     permMap{"read": true},
		"roles":     permMap{"read": true},
		"flows":     permMap{"read": true},
		"forms":     permMap{"read": true},
		"models":    permMap{"read": true},
		"letters":   permMap{"read": true},
		"tickets":   permMap{"read": true},
		"instances": permMap{"read": true},
	}

	roles := []models.Role{
		{
			BaseModel:   models.BaseModel{ID: seedRoleAdminID, CreatedAt: daysAgo(90), UpdatedAt: daysAgo(90)},
			CompanyID:   seedCompanyID,
			Name:        "Administrator",
			Description: "Full access to all resources and settings",
			Color:       "#6366f1",
			Permissions: mustJSON(allCRUD),
		},
		{
			BaseModel:   models.BaseModel{ID: seedRoleOpsID, CreatedAt: daysAgo(90), UpdatedAt: daysAgo(90)},
			CompanyID:   seedCompanyID,
			Name:        "Operations Manager",
			Description: "Manages day-to-day operations across most resources",
			Color:       "#10b981",
			Permissions: mustJSON(opsPerm),
		},
		{
			BaseModel:   models.BaseModel{ID: seedRoleSupportID, CreatedAt: daysAgo(90), UpdatedAt: daysAgo(90)},
			CompanyID:   seedCompanyID,
			Name:        "Support Agent",
			Description: "Handles tickets and has read access to most resources",
			Color:       "#f59e0b",
			Permissions: mustJSON(supportPerm),
		},
		{
			BaseModel:   models.BaseModel{ID: seedRoleDevID, CreatedAt: daysAgo(90), UpdatedAt: daysAgo(90)},
			CompanyID:   seedCompanyID,
			Name:        "Developer",
			Description: "Full access to flows, forms and model definitions",
			Color:       "#3b82f6",
			Permissions: mustJSON(devPerm),
		},
		{
			BaseModel:   models.BaseModel{ID: seedRoleViewerID, CreatedAt: daysAgo(90), UpdatedAt: daysAgo(90)},
			CompanyID:   seedCompanyID,
			Name:        "Viewer",
			Description: "Read-only access to all resources",
			Color:       "#6b7280",
			Permissions: mustJSON(viewerPerm),
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
			FullName:     "Alexandra Chen",
			CompanyID:    pUUID(seedCompanyID),
			RoleID:       pUUID(seedRoleAdminID),
			IsActive:     true,
			IsOwner:      true,
		},
		{
			BaseModel:    models.BaseModel{ID: seedUserMarcusID, CreatedAt: daysAgo(85), UpdatedAt: daysAgo(85)},
			Email:        "marcus@horizondigital.com",
			PasswordHash: pw,
			FullName:     "Marcus Thompson",
			CompanyID:    pUUID(seedCompanyID),
			RoleID:       pUUID(seedRoleOpsID),
			IsActive:     true,
		},
		{
			BaseModel:    models.BaseModel{ID: seedUserSofiaID, CreatedAt: daysAgo(80), UpdatedAt: daysAgo(80)},
			Email:        "sofia@horizondigital.com",
			PasswordHash: pw,
			FullName:     "Sofia Rodriguez",
			CompanyID:    pUUID(seedCompanyID),
			RoleID:       pUUID(seedRoleSupportID),
			IsActive:     true,
		},
		{
			BaseModel:    models.BaseModel{ID: seedUserJamesID, CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)},
			Email:        "james@horizondigital.com",
			PasswordHash: pw,
			FullName:     "James Park",
			CompanyID:    pUUID(seedCompanyID),
			RoleID:       pUUID(seedRoleDevID),
			IsActive:     true,
		},
		{
			BaseModel:    models.BaseModel{ID: seedUserEmilyID, CreatedAt: daysAgo(75), UpdatedAt: daysAgo(75)},
			Email:        "emily@horizondigital.com",
			PasswordHash: pw,
			FullName:     "Emily Watson",
			CompanyID:    pUUID(seedCompanyID),
			RoleID:       pUUID(seedRoleSupportID),
			IsActive:     true,
		},
		{
			BaseModel:    models.BaseModel{ID: seedUserDemoID, CreatedAt: daysAgo(60), UpdatedAt: daysAgo(60)},
			Email:        "demo@autocreat.io",
			PasswordHash: pw,
			FullName:     "Demo User",
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
		FieldType   string   `json:"field_type"`
		Required    bool     `json:"required"`
		Placeholder string   `json:"placeholder,omitempty"`
		Options     []string `json:"options,omitempty"`
		HelpText    string   `json:"help_text,omitempty"`
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
			Fields:      mustJSON(onboardingFields),
		},
		{
			BaseModel:   models.BaseModel{ID: seedFormProjectID, CreatedAt: daysAgo(75), UpdatedAt: daysAgo(75)},
			CompanyID:   seedCompanyID,
			Name:        "Project Approval Request",
			Description: "Formal request form for new project approvals",
			Fields:      mustJSON(projectFields),
		},
		{
			BaseModel:   models.BaseModel{ID: seedFormBugID, CreatedAt: daysAgo(70), UpdatedAt: daysAgo(70)},
			CompanyID:   seedCompanyID,
			Name:        "Bug Report Form",
			Description: "Structured form for reporting software bugs",
			Fields:      mustJSON(bugFields),
		},
		{
			BaseModel:   models.BaseModel{ID: seedFormFeedbackID, CreatedAt: daysAgo(65), UpdatedAt: daysAgo(65)},
			CompanyID:   seedCompanyID,
			Name:        "Client Feedback Survey",
			Description: "Post-engagement client satisfaction survey",
			Fields:      mustJSON(feedbackFields),
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
			IsActive:    true,
		},
		{
			BaseModel:   models.BaseModel{ID: seedFlowBugID, CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)},
			CompanyID:   seedCompanyID,
			Name:        "Bug Resolution Workflow",
			Description: "Structured process for triaging and fixing reported bugs",
			IsActive:    true,
		},
		{
			BaseModel:   models.BaseModel{ID: seedFlowProjectID, CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)},
			CompanyID:   seedCompanyID,
			Name:        "Client Project Approval",
			Description: "Multi-stage approval pipeline for new client projects",
			IsActive:    true,
		},
	}
	if err := db.Create(&flows).Error; err != nil {
		return fmt.Errorf("seed: create flows: %w", err)
	}

	// Flow nodes – Employee Onboarding
	emptyProps := mustJSON(map[string]interface{}{})
	onbNodes := []models.FlowNode{
		{BaseModel: models.BaseModel{ID: seedFlowOnbNodeStartID, CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, NodeType: models.NodeTypeStart, Name: "Start", PositionX: 100, PositionY: 300, Properties: emptyProps},
		{BaseModel: models.BaseModel{ID: seedFlowOnbNodeHRID, CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, NodeType: models.NodeTypeStep, Name: "HR Review", PositionX: 320, PositionY: 300, AssignedRoleID: pUUID(seedRoleOpsID), AssignedFormID: pUUID(seedFormOnboardingID), Properties: mustJSON(map[string]string{"description": "HR team reviews onboarding form and verifies information"})},
		{BaseModel: models.BaseModel{ID: seedFlowOnbNodeITID, CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, NodeType: models.NodeTypeStep, Name: "IT Setup", PositionX: 540, PositionY: 300, AssignedRoleID: pUUID(seedRoleDevID), Properties: mustJSON(map[string]string{"description": "IT team sets up equipment and accounts"})},
		{BaseModel: models.BaseModel{ID: seedFlowOnbNodeMgrID, CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, NodeType: models.NodeTypeDecision, Name: "Manager Approval", PositionX: 760, PositionY: 300, AssignedRoleID: pUUID(seedRoleOpsID), Properties: mustJSON(map[string]string{"description": "Manager approves or rejects the onboarding completion"})},
		{BaseModel: models.BaseModel{ID: seedFlowOnbNodeWelcomeID, CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, NodeType: models.NodeTypeStep, Name: "Welcome Meeting", PositionX: 980, PositionY: 200, AssignedRoleID: pUUID(seedRoleOpsID), Properties: mustJSON(map[string]string{"description": "Schedule and conduct welcome meeting"})},
		{BaseModel: models.BaseModel{ID: seedFlowOnbNodeEndID, CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, NodeType: models.NodeTypeEnd, Name: "Onboarding Complete", PositionX: 1200, PositionY: 300, Properties: emptyProps},
	}
	if err := db.Create(&onbNodes).Error; err != nil {
		return fmt.Errorf("seed: create onboarding nodes: %w", err)
	}

	onbEdges := []models.FlowEdge{
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000001-0001-0000-0000-000000000001"), CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, SourceNodeID: seedFlowOnbNodeStartID, TargetNodeID: seedFlowOnbNodeHRID, Label: "Begin", Condition: emptyProps},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000001-0001-0000-0000-000000000002"), CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, SourceNodeID: seedFlowOnbNodeHRID, TargetNodeID: seedFlowOnbNodeITID, Label: "Approved", Condition: emptyProps},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000001-0001-0000-0000-000000000003"), CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, SourceNodeID: seedFlowOnbNodeITID, TargetNodeID: seedFlowOnbNodeMgrID, Label: "Setup Done", Condition: emptyProps},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000001-0001-0000-0000-000000000004"), CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, SourceNodeID: seedFlowOnbNodeMgrID, TargetNodeID: seedFlowOnbNodeWelcomeID, Label: "Yes", Condition: mustJSON(map[string]string{"outcome": "approved"})},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000001-0001-0000-0000-000000000005"), CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, SourceNodeID: seedFlowOnbNodeMgrID, TargetNodeID: seedFlowOnbNodeHRID, Label: "No", Condition: mustJSON(map[string]string{"outcome": "rejected"})},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000001-0001-0000-0000-000000000006"), CreatedAt: daysAgo(78), UpdatedAt: daysAgo(78)}, FlowID: seedFlowOnboardingID, SourceNodeID: seedFlowOnbNodeWelcomeID, TargetNodeID: seedFlowOnbNodeEndID, Label: "Done", Condition: emptyProps},
	}
	if err := db.Create(&onbEdges).Error; err != nil {
		return fmt.Errorf("seed: create onboarding edges: %w", err)
	}

	// Flow nodes – Bug Resolution
	bugNodes := []models.FlowNode{
		{BaseModel: models.BaseModel{ID: seedFlowBugNodeStartID, CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)}, FlowID: seedFlowBugID, NodeType: models.NodeTypeStart, Name: "Start", PositionX: 100, PositionY: 300, Properties: emptyProps},
		{BaseModel: models.BaseModel{ID: seedFlowBugNodeTriageID, CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)}, FlowID: seedFlowBugID, NodeType: models.NodeTypeStep, Name: "Triage", PositionX: 320, PositionY: 300, AssignedRoleID: pUUID(seedRoleSupportID), AssignedFormID: pUUID(seedFormBugID), Properties: mustJSON(map[string]string{"description": "Support agent triages and categorises the bug"})},
		{BaseModel: models.BaseModel{ID: seedFlowBugNodeDevID, CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)}, FlowID: seedFlowBugID, NodeType: models.NodeTypeStep, Name: "Developer Fix", PositionX: 540, PositionY: 300, AssignedRoleID: pUUID(seedRoleDevID), Properties: mustJSON(map[string]string{"description": "Developer investigates and applies a fix"})},
		{BaseModel: models.BaseModel{ID: seedFlowBugNodeQAID, CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)}, FlowID: seedFlowBugID, NodeType: models.NodeTypeDecision, Name: "QA Review", PositionX: 760, PositionY: 300, Properties: mustJSON(map[string]string{"description": "QA verifies the fix"})},
		{BaseModel: models.BaseModel{ID: seedFlowBugNodeEndID, CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)}, FlowID: seedFlowBugID, NodeType: models.NodeTypeEnd, Name: "Resolved", PositionX: 980, PositionY: 300, Properties: emptyProps},
	}
	if err := db.Create(&bugNodes).Error; err != nil {
		return fmt.Errorf("seed: create bug nodes: %w", err)
	}

	bugEdges := []models.FlowEdge{
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000002-0001-0000-0000-000000000001"), CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)}, FlowID: seedFlowBugID, SourceNodeID: seedFlowBugNodeStartID, TargetNodeID: seedFlowBugNodeTriageID, Label: "Report Filed", Condition: emptyProps},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000002-0001-0000-0000-000000000002"), CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)}, FlowID: seedFlowBugID, SourceNodeID: seedFlowBugNodeTriageID, TargetNodeID: seedFlowBugNodeDevID, Label: "Confirmed", Condition: emptyProps},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000002-0001-0000-0000-000000000003"), CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)}, FlowID: seedFlowBugID, SourceNodeID: seedFlowBugNodeDevID, TargetNodeID: seedFlowBugNodeQAID, Label: "Fixed", Condition: emptyProps},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000002-0001-0000-0000-000000000004"), CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)}, FlowID: seedFlowBugID, SourceNodeID: seedFlowBugNodeQAID, TargetNodeID: seedFlowBugNodeEndID, Label: "Passed", Condition: mustJSON(map[string]string{"outcome": "approved"})},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000002-0001-0000-0000-000000000005"), CreatedAt: daysAgo(72), UpdatedAt: daysAgo(72)}, FlowID: seedFlowBugID, SourceNodeID: seedFlowBugNodeQAID, TargetNodeID: seedFlowBugNodeDevID, Label: "Failed", Condition: mustJSON(map[string]string{"outcome": "rejected"})},
	}
	if err := db.Create(&bugEdges).Error; err != nil {
		return fmt.Errorf("seed: create bug edges: %w", err)
	}

	// Flow nodes – Project Approval
	projNodes := []models.FlowNode{
		{BaseModel: models.BaseModel{ID: seedFlowProjNodeStartID, CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, NodeType: models.NodeTypeStart, Name: "Start", PositionX: 100, PositionY: 300, Properties: emptyProps},
		{BaseModel: models.BaseModel{ID: seedFlowProjNodeReviewID, CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, NodeType: models.NodeTypeStep, Name: "Initial Review", PositionX: 320, PositionY: 300, AssignedRoleID: pUUID(seedRoleOpsID), AssignedFormID: pUUID(seedFormProjectID), Properties: mustJSON(map[string]string{"description": "Operations Manager performs initial project review"})},
		{BaseModel: models.BaseModel{ID: seedFlowProjNodeDirectorID, CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, NodeType: models.NodeTypeDecision, Name: "Director Approval", PositionX: 540, PositionY: 300, AssignedRoleID: pUUID(seedRoleAdminID), Properties: mustJSON(map[string]string{"description": "Director makes final approval decision"})},
		{BaseModel: models.BaseModel{ID: seedFlowProjNodeContractID, CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, NodeType: models.NodeTypeStep, Name: "Contract Sent", PositionX: 760, PositionY: 200, AssignedRoleID: pUUID(seedRoleOpsID), Properties: mustJSON(map[string]string{"description": "Ops manager sends contract to client"})},
		{BaseModel: models.BaseModel{ID: seedFlowProjNodeEndOkID, CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, NodeType: models.NodeTypeEnd, Name: "Project Approved", PositionX: 980, PositionY: 200, Properties: emptyProps},
		{BaseModel: models.BaseModel{ID: seedFlowProjNodeEndRejID, CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, NodeType: models.NodeTypeEnd, Name: "Project Rejected", PositionX: 760, PositionY: 400, Properties: emptyProps},
	}
	if err := db.Create(&projNodes).Error; err != nil {
		return fmt.Errorf("seed: create project nodes: %w", err)
	}

	projEdges := []models.FlowEdge{
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000003-0001-0000-0000-000000000001"), CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, SourceNodeID: seedFlowProjNodeStartID, TargetNodeID: seedFlowProjNodeReviewID, Label: "Request Submitted", Condition: emptyProps},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000003-0001-0000-0000-000000000002"), CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, SourceNodeID: seedFlowProjNodeReviewID, TargetNodeID: seedFlowProjNodeDirectorID, Label: "Review Complete", Condition: emptyProps},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000003-0001-0000-0000-000000000003"), CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, SourceNodeID: seedFlowProjNodeDirectorID, TargetNodeID: seedFlowProjNodeContractID, Label: "Approved", Condition: mustJSON(map[string]string{"outcome": "approved"})},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000003-0001-0000-0000-000000000004"), CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, SourceNodeID: seedFlowProjNodeDirectorID, TargetNodeID: seedFlowProjNodeEndRejID, Label: "Rejected", Condition: mustJSON(map[string]string{"outcome": "rejected"})},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("ee000003-0001-0000-0000-000000000005"), CreatedAt: daysAgo(68), UpdatedAt: daysAgo(68)}, FlowID: seedFlowProjectID, SourceNodeID: seedFlowProjNodeContractID, TargetNodeID: seedFlowProjNodeEndOkID, Label: "Done", Condition: emptyProps},
	}
	if err := db.Create(&projEdges).Error; err != nil {
		return fmt.Errorf("seed: create project edges: %w", err)
	}

	// ------------------------------------------------------------------ Letter Templates
	welcomeContent := map[string]interface{}{
		"ops": []interface{}{
			map[string]interface{}{"insert": "Welcome to "},
			map[string]interface{}{"insert": "{{company.name}}", "attributes": map[string]interface{}{"bold": true}},
			map[string]interface{}{"insert": "!\n\n"},
			map[string]interface{}{"insert": "Dear "},
			map[string]interface{}{"insert": "{{user.name}}", "attributes": map[string]interface{}{"bold": true}},
			map[string]interface{}{"insert": ",\n\nWe are absolutely thrilled to have you join our team at Horizon Digital Agency. Your skills and expertise make you a wonderful addition and we look forward to achieving great things together.\n\nYour start date is confirmed as "},
			map[string]interface{}{"insert": "{{start_date}}", "attributes": map[string]interface{}{"italic": true}},
			map[string]interface{}{"insert": ". Please report to the main office at 9:00 AM where your manager, {{manager.name}}, will be there to greet you.\n\nIf you have any questions before your first day, please don't hesitate to reach out to the HR team at hr@horizondigital.com.\n\nWe look forward to seeing you soon!\n\nWarm regards,\n"},
			map[string]interface{}{"insert": "Alexandra Chen\n", "attributes": map[string]interface{}{"bold": true}},
			map[string]interface{}{"insert": "CEO, Horizon Digital Agency\n"},
		},
	}
	approvalContent := map[string]interface{}{
		"ops": []interface{}{
			map[string]interface{}{"insert": "Project Approval Notice\n", "attributes": map[string]interface{}{"bold": true, "size": "large"}},
			map[string]interface{}{"insert": "\nDear "},
			map[string]interface{}{"insert": "{{requester.name}}", "attributes": map[string]interface{}{"bold": true}},
			map[string]interface{}{"insert": ",\n\nWe are pleased to inform you that your project request has been approved.\n\n"},
			map[string]interface{}{"insert": "Project Details\n", "attributes": map[string]interface{}{"bold": true}},
			map[string]interface{}{"insert": "• Project Title: {{project.title}}\n• Budget Approved: ${{project.budget}}\n• Timeline: {{project.timeline}}\n• Team Size: {{project.team_size}}\n\n"},
			map[string]interface{}{"insert": "Next Steps\n", "attributes": map[string]interface{}{"bold": true}},
			map[string]interface{}{"insert": "1. Review the attached project brief\n2. Schedule a kick-off meeting with your team\n3. Submit the signed contract to the operations team\n\nApproved on "},
			map[string]interface{}{"insert": "{{approval_date}}", "attributes": map[string]interface{}{"italic": true}},
			map[string]interface{}{"insert": "\n\nBest regards,\n"},
			map[string]interface{}{"insert": "Marcus Thompson\n", "attributes": map[string]interface{}{"bold": true}},
			map[string]interface{}{"insert": "Operations Manager, Horizon Digital Agency\n"},
		},
	}
	contractContent := map[string]interface{}{
		"ops": []interface{}{
			map[string]interface{}{"insert": "Service Agreement\n", "attributes": map[string]interface{}{"bold": true, "size": "large"}},
			map[string]interface{}{"insert": "\nThis Service Agreement (\"Agreement\") is entered into as of "},
			map[string]interface{}{"insert": "{{contract_date}}", "attributes": map[string]interface{}{"italic": true}},
			map[string]interface{}{"insert": " between Horizon Digital Agency (\"Agency\") and "},
			map[string]interface{}{"insert": "{{client.company_name}}", "attributes": map[string]interface{}{"bold": true}},
			map[string]interface{}{"insert": " (\"Client\").\n\n"},
			map[string]interface{}{"insert": "1. Scope of Services\n", "attributes": map[string]interface{}{"bold": true}},
			map[string]interface{}{"insert": "The Agency agrees to provide the following services: {{service_description}}\n\n"},
			map[string]interface{}{"insert": "2. Compensation\n", "attributes": map[string]interface{}{"bold": true}},
			map[string]interface{}{"insert": "The Client agrees to pay ${{contract_value}} as outlined in the attached payment schedule.\n\n"},
			map[string]interface{}{"insert": "3. Term\n", "attributes": map[string]interface{}{"bold": true}},
			map[string]interface{}{"insert": "This Agreement commences on {{start_date}} and continues until {{end_date}}, unless earlier terminated.\n\n"},
			map[string]interface{}{"insert": "4. Signatures\n\n", "attributes": map[string]interface{}{"bold": true}},
			map[string]interface{}{"insert": "Agency Representative: ________________________  Date: __________\n\nClient Representative: ________________________  Date: __________\n"},
		},
	}

	letters := []models.LetterTemplate{
		{
			BaseModel:   models.BaseModel{ID: seedLetterWelcomeID, CreatedAt: daysAgo(77), UpdatedAt: daysAgo(77)},
			CompanyID:   seedCompanyID,
			Name:        "Welcome Letter",
			Description: "Sent to new employees on their first day",
			Content:     mustJSON(welcomeContent),
			Variables:   mustJSON([]string{"company.name", "user.name", "start_date", "manager.name"}),
		},
		{
			BaseModel:   models.BaseModel{ID: seedLetterApprovalID, CreatedAt: daysAgo(73), UpdatedAt: daysAgo(73)},
			CompanyID:   seedCompanyID,
			Name:        "Project Approval Notice",
			Description: "Formal notification of project approval",
			Content:     mustJSON(approvalContent),
			Variables:   mustJSON([]string{"requester.name", "project.title", "project.budget", "project.timeline", "project.team_size", "approval_date"}),
		},
		{
			BaseModel:   models.BaseModel{ID: seedLetterContractID, CreatedAt: daysAgo(69), UpdatedAt: daysAgo(69)},
			CompanyID:   seedCompanyID,
			Name:        "Contract Template",
			Description: "Standard service agreement contract for client engagements",
			Content:     mustJSON(contractContent),
			Variables:   mustJSON([]string{"contract_date", "client.company_name", "service_description", "contract_value", "start_date", "end_date"}),
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
			Fields:      mustJSON(clientFields),
		},
		{
			BaseModel:   models.BaseModel{ID: seedModelAssetID, CreatedAt: daysAgo(64), UpdatedAt: daysAgo(64)},
			CompanyID:   seedCompanyID,
			Name:        "Asset",
			Description: "Tracks company hardware and digital assets",
			Fields:      mustJSON(assetFields),
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
			BaseModel:    models.BaseModel{ID: seedTicket1ID, CreatedAt: daysAgo(45), UpdatedAt: daysAgo(44)},
			CompanyID:    seedCompanyID,
			SubjectTitle: "Cannot access company dashboard",
			Status:       models.TicketStatusOpen,
			CreatorID:    seedUserSofiaID,
			AssignedToID: marcusIDp,
		},
		{
			BaseModel:    models.BaseModel{ID: seedTicket2ID, CreatedAt: daysAgo(40), UpdatedAt: daysAgo(38)},
			CompanyID:    seedCompanyID,
			SubjectTitle: "Flow editor crashes on save",
			Status:       models.TicketStatusInProgress,
			CreatorID:    seedUserJamesID,
			AssignedToID: jamesIDp,
		},
		{
			BaseModel:    models.BaseModel{ID: seedTicket3ID, CreatedAt: daysAgo(38), UpdatedAt: daysAgo(37)},
			CompanyID:    seedCompanyID,
			SubjectTitle: "Request: Add bulk user import feature",
			Status:       models.TicketStatusOpen,
			CreatorID:    seedUserEmilyID,
		},
		{
			BaseModel:    models.BaseModel{ID: seedTicket4ID, CreatedAt: daysAgo(55), UpdatedAt: daysAgo(20)},
			CompanyID:    seedCompanyID,
			SubjectTitle: "Performance issues in ticket list view",
			Status:       models.TicketStatusClosed,
			CreatorID:    seedUserMarcusID,
			AssignedToID: jamesIDp,
		},
		{
			BaseModel:    models.BaseModel{ID: seedTicket5ID, CreatedAt: daysAgo(30), UpdatedAt: daysAgo(28)},
			CompanyID:    seedCompanyID,
			SubjectTitle: "Form submission not saving data",
			Status:       models.TicketStatusInProgress,
			CreatorID:    seedUserSofiaID,
			AssignedToID: jamesIDp,
		},
		{
			BaseModel:    models.BaseModel{ID: seedTicket6ID, CreatedAt: daysAgo(25), UpdatedAt: daysAgo(24)},
			CompanyID:    seedCompanyID,
			SubjectTitle: "Integration with Slack notifications",
			Status:       models.TicketStatusOpen,
			CreatorID:    seedUserMarcusID,
		},
		{
			BaseModel:    models.BaseModel{ID: seedTicket7ID, CreatedAt: daysAgo(60), UpdatedAt: daysAgo(15)},
			CompanyID:    seedCompanyID,
			SubjectTitle: "User role permissions not applying correctly",
			Status:       models.TicketStatusClosed,
			CreatorID:    seedUserEmilyID,
			AssignedToID: marcusIDp,
		},
		{
			BaseModel:    models.BaseModel{ID: seedTicket8ID, CreatedAt: daysAgo(10), UpdatedAt: daysAgo(9)},
			CompanyID:    seedCompanyID,
			SubjectTitle: "Generate letter template not working",
			Status:       models.TicketStatusInProgress,
			CreatorID:    seedUserSofiaID,
			AssignedToID: jamesIDp,
		},
	}
	if err := db.Create(&tickets).Error; err != nil {
		return fmt.Errorf("seed: create tickets: %w", err)
	}

	emptyAttach := mustJSON([]interface{}{})
	messages := []models.TicketMessage{
		// Ticket 1 – Cannot access company dashboard (3 messages)
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000001-0001-0000-0000-000000000001"), CreatedAt: daysAgo(45), UpdatedAt: daysAgo(45)}, TicketID: seedTicket1ID, SenderID: seedUserSofiaID, Content: "Hi team, I've been unable to access the company dashboard since this morning. When I navigate to it I get a blank white screen. I've tried refreshing and clearing cache but the issue persists. My role is Support Agent.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000001-0001-0000-0000-000000000002"), CreatedAt: daysAgo(44), UpdatedAt: daysAgo(44)}, TicketID: seedTicket1ID, SenderID: seedUserMarcusID, Content: "Thanks for reporting this, Sofia. I can reproduce the issue from my end too for the support agent role. It looks like a recent permission change might be blocking dashboard access. I'll investigate and loop in James if it's a backend issue.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000001-0001-0000-0000-000000000003"), CreatedAt: daysAgo(44), UpdatedAt: daysAgo(44)}, TicketID: seedTicket1ID, SenderID: seedUserSofiaID, Content: "Thank you Marcus. Just to confirm – the issue is only happening on the dashboard page. All other pages like Tickets and Forms load fine for me.", Attachments: emptyAttach},

		// Ticket 2 – Flow editor crashes on save (4 messages)
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000002-0001-0000-0000-000000000001"), CreatedAt: daysAgo(40), UpdatedAt: daysAgo(40)}, TicketID: seedTicket2ID, SenderID: seedUserJamesID, Content: "I've found a critical bug in the flow editor. When you have more than 8 nodes and try to save the graph, the browser throws a 413 Payload Too Large error and the save fails. The console shows the request body is exceeding the nginx limit.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000002-0001-0000-0000-000000000002"), CreatedAt: daysAgo(39), UpdatedAt: daysAgo(39)}, TicketID: seedTicket2ID, SenderID: seedUserAlexandraID, Content: "This is a blocker for the onboarding flow we're building. James, can you look into increasing the payload limit? Also check if we can chunk the save request.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000002-0001-0000-0000-000000000003"), CreatedAt: daysAgo(38), UpdatedAt: daysAgo(38)}, TicketID: seedTicket2ID, SenderID: seedUserJamesID, Content: "I've identified two fixes: (1) increase nginx client_max_body_size to 10mb, and (2) add server-side pagination to the graph load endpoint. I'm implementing both now. ETA: today.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000002-0001-0000-0000-000000000004"), CreatedAt: daysAgo(38), UpdatedAt: daysAgo(38)}, TicketID: seedTicket2ID, SenderID: seedUserJamesID, Content: "Fix deployed to staging. nginx limit increased and the save endpoint now handles large payloads. Testing confirmed flows with 15+ nodes save correctly. Will deploy to production after QA sign-off.", Attachments: emptyAttach},

		// Ticket 3 – Bulk user import (2 messages)
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000003-0001-0000-0000-000000000001"), CreatedAt: daysAgo(38), UpdatedAt: daysAgo(38)}, TicketID: seedTicket3ID, SenderID: seedUserEmilyID, Content: "Feature request: We need a way to bulk-import users from a CSV file. We have a new client with 150 employees to onboard and creating them one-by-one is not feasible. The CSV should support: full_name, email, role, department.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000003-0001-0000-0000-000000000002"), CreatedAt: daysAgo(37), UpdatedAt: daysAgo(37)}, TicketID: seedTicket3ID, SenderID: seedUserMarcusID, Content: "Great idea Emily. I'm adding this to our Q2 roadmap. We'll design the CSV schema to include: full_name, email, role_name, and an optional password (if omitted we'll send a set-password email). James will own the implementation.", Attachments: emptyAttach},

		// Ticket 4 – Performance issues (5 messages)
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000004-0001-0000-0000-000000000001"), CreatedAt: daysAgo(55), UpdatedAt: daysAgo(55)}, TicketID: seedTicket4ID, SenderID: seedUserMarcusID, Content: "The ticket list page is very slow when there are more than 200 tickets. Initial load takes 8+ seconds. The browser dev tools show the API response is ~4MB of JSON.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000004-0001-0000-0000-000000000002"), CreatedAt: daysAgo(52), UpdatedAt: daysAgo(52)}, TicketID: seedTicket4ID, SenderID: seedUserJamesID, Content: "I've looked at the query. The tickets endpoint is doing a full table scan and loading all message relations eagerly. I'll add pagination (default 50/page), add a DB index on company_id+status, and change messages to lazy-load.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000004-0001-0000-0000-000000000003"), CreatedAt: daysAgo(50), UpdatedAt: daysAgo(50)}, TicketID: seedTicket4ID, SenderID: seedUserMarcusID, Content: "Any ETA? This is really impacting the support team's productivity.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000004-0001-0000-0000-000000000004"), CreatedAt: daysAgo(22), UpdatedAt: daysAgo(22)}, TicketID: seedTicket4ID, SenderID: seedUserJamesID, Content: "Deployed fix: added pagination, DB indexes, and lazy-load for messages. List load time is now under 300ms for 500+ tickets in load testing.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000004-0001-0000-0000-000000000005"), CreatedAt: daysAgo(20), UpdatedAt: daysAgo(20)}, TicketID: seedTicket4ID, SenderID: seedUserMarcusID, Content: "Confirmed – ticket list is lightning fast now. Closing this ticket. Great work James!", Attachments: emptyAttach},

		// Ticket 5 – Form submission not saving (3 messages)
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000005-0001-0000-0000-000000000001"), CreatedAt: daysAgo(30), UpdatedAt: daysAgo(30)}, TicketID: seedTicket5ID, SenderID: seedUserSofiaID, Content: "When I complete a form within a flow instance and click Submit, I get a success toast but when I reload the instance the form data is missing. Happened with the Employee Onboarding form on 3 separate instances.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000005-0001-0000-0000-000000000002"), CreatedAt: daysAgo(29), UpdatedAt: daysAgo(29)}, TicketID: seedTicket5ID, SenderID: seedUserJamesID, Content: "Reproducing now. The issue looks like a race condition – the frontend sends the form submission and immediately advances the instance step before the DB write completes. I need to make the advance call wait for the submission to be confirmed.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000005-0001-0000-0000-000000000003"), CreatedAt: daysAgo(28), UpdatedAt: daysAgo(28)}, TicketID: seedTicket5ID, SenderID: seedUserSofiaID, Content: "Thanks James. Can you let me know when the fix is deployed so I can retest? I'll hold off on using forms in flows until then.", Attachments: emptyAttach},

		// Ticket 6 – Slack integration (2 messages)
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000006-0001-0000-0000-000000000001"), CreatedAt: daysAgo(25), UpdatedAt: daysAgo(25)}, TicketID: seedTicket6ID, SenderID: seedUserMarcusID, Content: "Would love to have Slack notifications when a ticket is assigned or a flow instance reaches a step requiring action. This would massively improve response times for the support team.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000006-0001-0000-0000-000000000002"), CreatedAt: daysAgo(24), UpdatedAt: daysAgo(24)}, TicketID: seedTicket6ID, SenderID: seedUserAlexandraID, Content: "Agreed – a webhook/integration system is on our roadmap. I've added Slack as the first integration target for Q3. Marcus, can you document the specific event triggers you need (ticket assigned, step pending, instance completed)?", Attachments: emptyAttach},

		// Ticket 7 – Role permissions (4 messages)
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000007-0001-0000-0000-000000000001"), CreatedAt: daysAgo(60), UpdatedAt: daysAgo(60)}, TicketID: seedTicket7ID, SenderID: seedUserEmilyID, Content: "The Viewer role isn't restricting access properly. Users with the Viewer role can still click the 'Create Ticket' button and the button is visible in the UI. I thought Viewers should be read-only.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000007-0001-0000-0000-000000000002"), CreatedAt: daysAgo(58), UpdatedAt: daysAgo(58)}, TicketID: seedTicket7ID, SenderID: seedUserMarcusID, Content: "Confirmed. The backend is correctly rejecting the create request (403 Forbidden), but the frontend isn't reading the permissions from the JWT claims to conditionally hide the button. This is a UI issue.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000007-0001-0000-0000-000000000003"), CreatedAt: daysAgo(17), UpdatedAt: daysAgo(17)}, TicketID: seedTicket7ID, SenderID: seedUserMarcusID, Content: "Fix deployed: the frontend now reads the `permissions` object from user context and conditionally renders action buttons. All create/edit/delete buttons are hidden for Viewers across all resource types.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000007-0001-0000-0000-000000000004"), CreatedAt: daysAgo(15), UpdatedAt: daysAgo(15)}, TicketID: seedTicket7ID, SenderID: seedUserEmilyID, Content: "Tested with a Viewer account – all create/edit/delete buttons are properly hidden. Closing this ticket.", Attachments: emptyAttach},

		// Ticket 8 – Letter generation (3 messages)
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000008-0001-0000-0000-000000000001"), CreatedAt: daysAgo(10), UpdatedAt: daysAgo(10)}, TicketID: seedTicket8ID, SenderID: seedUserSofiaID, Content: "When I try to generate a letter from the Welcome Letter template, I click 'Generate' and the page just spins indefinitely. No error message is shown. This is blocking us from sending onboarding letters.", Attachments: emptyAttach},
		{BaseModel: models.BaseModel{ID: uuid.MustParse("bb000008-0001-0000-0000-000000000002"), CreatedAt: daysAgo(9), UpdatedAt: daysAgo(9)}, TicketID: seedTicket8ID, SenderID: seedUserJamesID, Content: "Found the issue. The letter generation endpoint is trying to parse the Quill delta JSON using an incorrect schema – it's treating it as a plain string. The variable substitution then fails silently and the response hangs. Fix incoming.", Attachments: emptyAttach},
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
