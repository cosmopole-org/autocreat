// Package demo provides hardcoded demo-mode responses and a Gin middleware
// that intercepts requests when the authenticated user is the demo account,
// returning realistic but non-persistent data.
package demo

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// Fixed demo timestamps (relative to a fixed anchor so they look natural).
var (
	now     = time.Now().UTC()
	t90     = now.AddDate(0, 0, -90).Format(time.RFC3339)
	t85     = now.AddDate(0, 0, -85).Format(time.RFC3339)
	t80     = now.AddDate(0, 0, -80).Format(time.RFC3339)
	t78     = now.AddDate(0, 0, -78).Format(time.RFC3339)
	t75     = now.AddDate(0, 0, -75).Format(time.RFC3339)
	t72     = now.AddDate(0, 0, -72).Format(time.RFC3339)
	t68     = now.AddDate(0, 0, -68).Format(time.RFC3339)
	t66     = now.AddDate(0, 0, -66).Format(time.RFC3339)
	t60     = now.AddDate(0, 0, -60).Format(time.RFC3339)
	t55     = now.AddDate(0, 0, -55).Format(time.RFC3339)
	t45     = now.AddDate(0, 0, -45).Format(time.RFC3339)
	t40     = now.AddDate(0, 0, -40).Format(time.RFC3339)
	t38     = now.AddDate(0, 0, -38).Format(time.RFC3339)
	t35     = now.AddDate(0, 0, -35).Format(time.RFC3339)
	t30     = now.AddDate(0, 0, -30).Format(time.RFC3339)
	t25     = now.AddDate(0, 0, -25).Format(time.RFC3339)
	t20     = now.AddDate(0, 0, -20).Format(time.RFC3339)
	t15     = now.AddDate(0, 0, -15).Format(time.RFC3339)
	t10     = now.AddDate(0, 0, -10).Format(time.RFC3339)
	t7      = now.AddDate(0, 0, -7).Format(time.RFC3339)
	t3      = now.AddDate(0, 0, -3).Format(time.RFC3339)
	t1      = now.AddDate(0, 0, -1).Format(time.RFC3339)
	_       = t7 // keep compiler happy if unused below
	_       = t3
	_       = t1
)

// ---------- IDs (must match seed.go) ----------

const (
	demoCompanyID   = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"

	demoRoleAdminID   = "b0000001-0000-0000-0000-000000000001"
	demoRoleOpsID     = "b0000001-0000-0000-0000-000000000002"
	demoRoleSupportID = "b0000001-0000-0000-0000-000000000003"
	demoRoleDevID     = "b0000001-0000-0000-0000-000000000004"
	demoRoleViewerID  = "b0000001-0000-0000-0000-000000000005"

	demoUserAlexandraID = "c0000001-0000-0000-0000-000000000001"
	demoUserMarcusID    = "c0000001-0000-0000-0000-000000000002"
	demoUserSofiaID     = "c0000001-0000-0000-0000-000000000003"
	demoUserJamesID     = "c0000001-0000-0000-0000-000000000004"
	demoUserEmilyID     = "c0000001-0000-0000-0000-000000000005"
	demoUserDemoID      = "c0000001-0000-0000-0000-000000000006"

	demoFormOnboardingID = "d0000001-0000-0000-0000-000000000001"
	demoFormProjectID    = "d0000001-0000-0000-0000-000000000002"
	demoFormBugID        = "d0000001-0000-0000-0000-000000000003"
	demoFormFeedbackID   = "d0000001-0000-0000-0000-000000000004"

	demoFlowOnboardingID = "e0000001-0000-0000-0000-000000000001"
	demoFlowBugID        = "e0000001-0000-0000-0000-000000000002"
	demoFlowProjectID    = "e0000001-0000-0000-0000-000000000003"

	demoLetterWelcomeID  = "f0000001-0000-0000-0000-000000000001"
	demoLetterApprovalID = "f0000001-0000-0000-0000-000000000002"
	demoLetterContractID = "f0000001-0000-0000-0000-000000000003"

	demoModelClientID = "f1000001-0000-0000-0000-000000000001"
	demoModelAssetID  = "f1000001-0000-0000-0000-000000000002"

	demoTicket1ID = "a2000001-0000-0000-0000-000000000001"
	demoTicket2ID = "a2000001-0000-0000-0000-000000000002"
	demoTicket3ID = "a2000001-0000-0000-0000-000000000003"
	demoTicket4ID = "a2000001-0000-0000-0000-000000000004"
	demoTicket5ID = "a2000001-0000-0000-0000-000000000005"
	demoTicket6ID = "a2000001-0000-0000-0000-000000000006"
	demoTicket7ID = "a2000001-0000-0000-0000-000000000007"
	demoTicket8ID = "a2000001-0000-0000-0000-000000000008"

	demoInstanceBugID     = "a3000001-0000-0000-0000-000000000001"
	demoInstanceOnbID     = "a3000001-0000-0000-0000-000000000002"
	demoInstanceProjectID = "a3000001-0000-0000-0000-000000000003"
)

// ---------- Exported demo variables ----------

// DemoCompany is the demo company record.
var DemoCompany = map[string]interface{}{
	"id":          demoCompanyID,
	"name":        "Horizon Digital Agency",
	"description": "Full-service digital transformation and automation agency serving enterprise clients worldwide",
	"logo":        "",
	"owner_id":    demoUserAlexandraID,
	"created_at":  t90,
	"updated_at":  t90,
}

// DemoUser is the currently-authenticated demo user.
var DemoUser = map[string]interface{}{
	"id":         demoUserDemoID,
	"email":      "demo@autocreat.io",
	"full_name":  "Demo User",
	"company_id": demoCompanyID,
	"role_id":    demoRoleAdminID,
	"avatar":     "",
	"is_active":  true,
	"is_owner":   false,
	"created_at": t60,
	"updated_at": t60,
}

// DemoStats matches StatsResponse.
var DemoStats = map[string]interface{}{
	"total_users":            6,
	"total_flows":            3,
	"active_instances":       2,
	"total_tickets":          8,
	"open_tickets":           4,
	"total_forms":            4,
	"total_models":           2,
	"total_letter_templates": 3,
}

// DemoRoles contains the 5 demo roles.
var DemoRoles = []map[string]interface{}{
	{
		"id":          demoRoleAdminID,
		"company_id":  demoCompanyID,
		"name":        "Administrator",
		"description": "Full access to all resources and settings",
		"color":       "#6366f1",
		"permissions": map[string]interface{}{
			"companies": map[string]bool{"create": true, "read": true, "update": true, "delete": true},
			"users":     map[string]bool{"create": true, "read": true, "update": true, "delete": true},
			"roles":     map[string]bool{"create": true, "read": true, "update": true, "delete": true},
			"flows":     map[string]bool{"create": true, "read": true, "update": true, "delete": true},
			"forms":     map[string]bool{"create": true, "read": true, "update": true, "delete": true},
			"models":    map[string]bool{"create": true, "read": true, "update": true, "delete": true},
			"letters":   map[string]bool{"create": true, "read": true, "update": true, "delete": true},
			"tickets":   map[string]bool{"create": true, "read": true, "update": true, "delete": true},
			"instances": map[string]bool{"create": true, "read": true, "update": true, "delete": true},
		},
		"created_at": t90,
		"updated_at": t90,
	},
	{
		"id":          demoRoleOpsID,
		"company_id":  demoCompanyID,
		"name":        "Operations Manager",
		"description": "Manages day-to-day operations across most resources",
		"color":       "#10b981",
		"permissions": map[string]interface{}{
			"companies": map[string]bool{"read": true},
			"users":     map[string]bool{"create": true, "read": true, "update": true},
			"roles":     map[string]bool{"read": true},
			"flows":     map[string]bool{"create": true, "read": true, "update": true},
			"forms":     map[string]bool{"create": true, "read": true, "update": true},
			"models":    map[string]bool{"create": true, "read": true, "update": true},
			"letters":   map[string]bool{"create": true, "read": true, "update": true},
			"tickets":   map[string]bool{"create": true, "read": true, "update": true, "delete": true},
			"instances": map[string]bool{"create": true, "read": true, "update": true},
		},
		"created_at": t90,
		"updated_at": t90,
	},
	{
		"id":          demoRoleSupportID,
		"company_id":  demoCompanyID,
		"name":        "Support Agent",
		"description": "Handles tickets and has read access to most resources",
		"color":       "#f59e0b",
		"permissions": map[string]interface{}{
			"companies": map[string]bool{"read": true},
			"users":     map[string]bool{"read": true},
			"roles":     map[string]bool{"read": true},
			"flows":     map[string]bool{"read": true},
			"forms":     map[string]bool{"read": true},
			"models":    map[string]bool{"read": true},
			"letters":   map[string]bool{"read": true},
			"tickets":   map[string]bool{"create": true, "read": true, "update": true, "delete": true},
			"instances": map[string]bool{"read": true},
		},
		"created_at": t90,
		"updated_at": t90,
	},
	{
		"id":          demoRoleDevID,
		"company_id":  demoCompanyID,
		"name":        "Developer",
		"description": "Full access to flows, forms and model definitions",
		"color":       "#3b82f6",
		"permissions": map[string]interface{}{
			"companies": map[string]bool{"read": true},
			"users":     map[string]bool{"read": true},
			"roles":     map[string]bool{"read": true},
			"flows":     map[string]bool{"create": true, "read": true, "update": true, "delete": true},
			"forms":     map[string]bool{"create": true, "read": true, "update": true, "delete": true},
			"models":    map[string]bool{"create": true, "read": true, "update": true, "delete": true},
			"letters":   map[string]bool{"create": true, "read": true, "update": true},
			"tickets":   map[string]bool{"create": true, "read": true, "update": true},
			"instances": map[string]bool{"create": true, "read": true, "update": true},
		},
		"created_at": t90,
		"updated_at": t90,
	},
	{
		"id":          demoRoleViewerID,
		"company_id":  demoCompanyID,
		"name":        "Viewer",
		"description": "Read-only access to all resources",
		"color":       "#6b7280",
		"permissions": map[string]interface{}{
			"companies": map[string]bool{"read": true},
			"users":     map[string]bool{"read": true},
			"roles":     map[string]bool{"read": true},
			"flows":     map[string]bool{"read": true},
			"forms":     map[string]bool{"read": true},
			"models":    map[string]bool{"read": true},
			"letters":   map[string]bool{"read": true},
			"tickets":   map[string]bool{"read": true},
			"instances": map[string]bool{"read": true},
		},
		"created_at": t90,
		"updated_at": t90,
	},
}

// DemoUsers contains the 6 demo users.
var DemoUsers = []map[string]interface{}{
	{
		"id": demoUserAlexandraID, "email": "admin@horizondigital.com",
		"full_name": "Alexandra Chen", "company_id": demoCompanyID,
		"role_id": demoRoleAdminID, "avatar": "", "is_active": true, "is_owner": true,
		"created_at": t90, "updated_at": t90,
		"role": map[string]interface{}{"id": demoRoleAdminID, "name": "Administrator", "color": "#6366f1"},
	},
	{
		"id": demoUserMarcusID, "email": "marcus@horizondigital.com",
		"full_name": "Marcus Thompson", "company_id": demoCompanyID,
		"role_id": demoRoleOpsID, "avatar": "", "is_active": true, "is_owner": false,
		"created_at": t85, "updated_at": t85,
		"role": map[string]interface{}{"id": demoRoleOpsID, "name": "Operations Manager", "color": "#10b981"},
	},
	{
		"id": demoUserSofiaID, "email": "sofia@horizondigital.com",
		"full_name": "Sofia Rodriguez", "company_id": demoCompanyID,
		"role_id": demoRoleSupportID, "avatar": "", "is_active": true, "is_owner": false,
		"created_at": t80, "updated_at": t80,
		"role": map[string]interface{}{"id": demoRoleSupportID, "name": "Support Agent", "color": "#f59e0b"},
	},
	{
		"id": demoUserJamesID, "email": "james@horizondigital.com",
		"full_name": "James Park", "company_id": demoCompanyID,
		"role_id": demoRoleDevID, "avatar": "", "is_active": true, "is_owner": false,
		"created_at": t78, "updated_at": t78,
		"role": map[string]interface{}{"id": demoRoleDevID, "name": "Developer", "color": "#3b82f6"},
	},
	{
		"id": demoUserEmilyID, "email": "emily@horizondigital.com",
		"full_name": "Emily Watson", "company_id": demoCompanyID,
		"role_id": demoRoleSupportID, "avatar": "", "is_active": true, "is_owner": false,
		"created_at": t75, "updated_at": t75,
		"role": map[string]interface{}{"id": demoRoleSupportID, "name": "Support Agent", "color": "#f59e0b"},
	},
	{
		"id": demoUserDemoID, "email": "demo@autocreat.io",
		"full_name": "Demo User", "company_id": demoCompanyID,
		"role_id": demoRoleAdminID, "avatar": "", "is_active": true, "is_owner": false,
		"created_at": t60, "updated_at": t60,
		"role": map[string]interface{}{"id": demoRoleAdminID, "name": "Administrator", "color": "#6366f1"},
	},
}

// DemoForms contains the 4 demo form definitions.
var DemoForms = []map[string]interface{}{
	{
		"id": demoFormOnboardingID, "company_id": demoCompanyID,
		"name":        "Employee Onboarding Form",
		"description": "Collects essential information for new employee onboarding",
		"fields": []map[string]interface{}{
			{"id": "ff-onb-001", "name": "full_name", "label": "Full Name", "field_type": "text", "required": true, "placeholder": "Enter your full name"},
			{"id": "ff-onb-002", "name": "department", "label": "Department", "field_type": "select", "required": true, "options": []string{"Engineering", "HR", "Sales", "Marketing", "Operations"}},
			{"id": "ff-onb-003", "name": "start_date", "label": "Start Date", "field_type": "date", "required": true},
			{"id": "ff-onb-004", "name": "remote_work", "label": "Remote Work", "field_type": "checkbox", "help_text": "Check if the employee will work remotely"},
			{"id": "ff-onb-005", "name": "equipment_needs", "label": "Equipment Needs", "field_type": "multiselect", "options": []string{"Laptop", "Monitor", "Headset", "Keyboard", "Mouse"}},
			{"id": "ff-onb-006", "name": "emergency_contact", "label": "Emergency Contact", "field_type": "text", "placeholder": "Name and phone number"},
			{"id": "ff-onb-007", "name": "notes", "label": "Notes", "field_type": "textarea", "placeholder": "Any additional notes…"},
		},
		"created_at": t80, "updated_at": t80,
	},
	{
		"id": demoFormProjectID, "company_id": demoCompanyID,
		"name":        "Project Approval Request",
		"description": "Formal request form for new project approvals",
		"fields": []map[string]interface{}{
			{"id": "ff-proj-001", "name": "project_title", "label": "Project Title", "field_type": "text", "required": true, "placeholder": "Enter project title"},
			{"id": "ff-proj-002", "name": "budget_estimate", "label": "Budget Estimate ($)", "field_type": "number", "required": true, "placeholder": "0"},
			{"id": "ff-proj-003", "name": "timeline", "label": "Timeline", "field_type": "select", "required": true, "options": []string{"1 week", "2 weeks", "1 month", "3 months", "6 months"}},
			{"id": "ff-proj-004", "name": "team_size", "label": "Team Size", "field_type": "number", "placeholder": "Number of people"},
			{"id": "ff-proj-005", "name": "risk_level", "label": "Risk Level", "field_type": "radio", "required": true, "options": []string{"Low", "Medium", "High"}},
			{"id": "ff-proj-006", "name": "description", "label": "Description", "field_type": "textarea", "required": true, "placeholder": "Describe the project…"},
			{"id": "ff-proj-007", "name": "attachments_required", "label": "Attachments Required", "field_type": "checkbox"},
		},
		"created_at": t75, "updated_at": t75,
	},
	{
		"id": demoFormBugID, "company_id": demoCompanyID,
		"name":        "Bug Report Form",
		"description": "Structured form for reporting software bugs",
		"fields": []map[string]interface{}{
			{"id": "ff-bug-001", "name": "bug_title", "label": "Bug Title", "field_type": "text", "required": true, "placeholder": "Brief description of the bug"},
			{"id": "ff-bug-002", "name": "severity", "label": "Severity", "field_type": "select", "required": true, "options": []string{"Critical", "High", "Medium", "Low"}},
			{"id": "ff-bug-003", "name": "module", "label": "Affected Module", "field_type": "select", "options": []string{"Frontend", "Backend", "Database", "API", "Mobile"}},
			{"id": "ff-bug-004", "name": "steps_to_reproduce", "label": "Steps to Reproduce", "field_type": "textarea", "required": true},
			{"id": "ff-bug-005", "name": "expected_behavior", "label": "Expected Behavior", "field_type": "textarea"},
			{"id": "ff-bug-006", "name": "actual_behavior", "label": "Actual Behavior", "field_type": "textarea"},
			{"id": "ff-bug-007", "name": "browser_os", "label": "Browser / OS", "field_type": "text", "placeholder": "Chrome 120 / macOS Sonoma"},
			{"id": "ff-bug-008", "name": "screenshot_url", "label": "Screenshot URL", "field_type": "text"},
		},
		"created_at": t72, "updated_at": t72,
	},
	{
		"id": demoFormFeedbackID, "company_id": demoCompanyID,
		"name":        "Client Feedback Survey",
		"description": "Post-engagement client satisfaction survey",
		"fields": []map[string]interface{}{
			{"id": "ff-fb-001", "name": "client_name", "label": "Client Name", "field_type": "text"},
			{"id": "ff-fb-002", "name": "rating", "label": "Overall Rating", "field_type": "radio", "required": true, "options": []string{"1 star", "2 stars", "3 stars", "4 stars", "5 stars"}},
			{"id": "ff-fb-003", "name": "service_quality", "label": "Service Quality", "field_type": "select", "options": []string{"Excellent", "Good", "Average", "Poor"}},
			{"id": "ff-fb-004", "name": "response_time", "label": "Response Time", "field_type": "select", "options": []string{"Excellent", "Good", "Average", "Poor"}},
			{"id": "ff-fb-005", "name": "would_recommend", "label": "Would Recommend", "field_type": "checkbox"},
			{"id": "ff-fb-006", "name": "comments", "label": "Comments", "field_type": "textarea"},
			{"id": "ff-fb-007", "name": "contact_permission", "label": "May we contact you?", "field_type": "checkbox"},
		},
		"created_at": t68, "updated_at": t68,
	},
}

// DemoFlows contains the 3 demo flows with nodes and edges.
var DemoFlows = []map[string]interface{}{
	{
		"id": demoFlowOnboardingID, "company_id": demoCompanyID,
		"name":        "Employee Onboarding Process",
		"description": "End-to-end onboarding workflow for new hires",
		"is_active":   true,
		"created_at":  t78, "updated_at": t78,
		"nodes": []map[string]interface{}{
			{"id": "e1000001-0000-0000-0000-000000000001", "flow_id": demoFlowOnboardingID, "node_type": "START", "name": "Start", "position_x": 100, "position_y": 300},
			{"id": "e1000001-0000-0000-0000-000000000002", "flow_id": demoFlowOnboardingID, "node_type": "STEP", "name": "HR Review", "position_x": 320, "position_y": 300, "assigned_role_id": demoRoleOpsID, "assigned_form_id": demoFormOnboardingID},
			{"id": "e1000001-0000-0000-0000-000000000003", "flow_id": demoFlowOnboardingID, "node_type": "STEP", "name": "IT Setup", "position_x": 540, "position_y": 300, "assigned_role_id": demoRoleDevID},
			{"id": "e1000001-0000-0000-0000-000000000004", "flow_id": demoFlowOnboardingID, "node_type": "DECISION", "name": "Manager Approval", "position_x": 760, "position_y": 300, "assigned_role_id": demoRoleOpsID},
			{"id": "e1000001-0000-0000-0000-000000000005", "flow_id": demoFlowOnboardingID, "node_type": "STEP", "name": "Welcome Meeting", "position_x": 980, "position_y": 200, "assigned_role_id": demoRoleOpsID},
			{"id": "e1000001-0000-0000-0000-000000000006", "flow_id": demoFlowOnboardingID, "node_type": "END", "name": "Onboarding Complete", "position_x": 1200, "position_y": 300},
		},
		"edges": []map[string]interface{}{
			{"id": "ee000001-0001-0000-0000-000000000001", "flow_id": demoFlowOnboardingID, "source_node_id": "e1000001-0000-0000-0000-000000000001", "target_node_id": "e1000001-0000-0000-0000-000000000002", "label": "Begin"},
			{"id": "ee000001-0001-0000-0000-000000000002", "flow_id": demoFlowOnboardingID, "source_node_id": "e1000001-0000-0000-0000-000000000002", "target_node_id": "e1000001-0000-0000-0000-000000000003", "label": "Approved"},
			{"id": "ee000001-0001-0000-0000-000000000003", "flow_id": demoFlowOnboardingID, "source_node_id": "e1000001-0000-0000-0000-000000000003", "target_node_id": "e1000001-0000-0000-0000-000000000004", "label": "Setup Done"},
			{"id": "ee000001-0001-0000-0000-000000000004", "flow_id": demoFlowOnboardingID, "source_node_id": "e1000001-0000-0000-0000-000000000004", "target_node_id": "e1000001-0000-0000-0000-000000000005", "label": "Yes"},
			{"id": "ee000001-0001-0000-0000-000000000005", "flow_id": demoFlowOnboardingID, "source_node_id": "e1000001-0000-0000-0000-000000000004", "target_node_id": "e1000001-0000-0000-0000-000000000002", "label": "No"},
			{"id": "ee000001-0001-0000-0000-000000000006", "flow_id": demoFlowOnboardingID, "source_node_id": "e1000001-0000-0000-0000-000000000005", "target_node_id": "e1000001-0000-0000-0000-000000000006", "label": "Done"},
		},
	},
	{
		"id": demoFlowBugID, "company_id": demoCompanyID,
		"name":        "Bug Resolution Workflow",
		"description": "Structured process for triaging and fixing reported bugs",
		"is_active":   true,
		"created_at":  t72, "updated_at": t72,
		"nodes": []map[string]interface{}{
			{"id": "e2000001-0000-0000-0000-000000000001", "flow_id": demoFlowBugID, "node_type": "START", "name": "Start", "position_x": 100, "position_y": 300},
			{"id": "e2000001-0000-0000-0000-000000000002", "flow_id": demoFlowBugID, "node_type": "STEP", "name": "Triage", "position_x": 320, "position_y": 300, "assigned_role_id": demoRoleSupportID, "assigned_form_id": demoFormBugID},
			{"id": "e2000001-0000-0000-0000-000000000003", "flow_id": demoFlowBugID, "node_type": "STEP", "name": "Developer Fix", "position_x": 540, "position_y": 300, "assigned_role_id": demoRoleDevID},
			{"id": "e2000001-0000-0000-0000-000000000004", "flow_id": demoFlowBugID, "node_type": "DECISION", "name": "QA Review", "position_x": 760, "position_y": 300},
			{"id": "e2000001-0000-0000-0000-000000000005", "flow_id": demoFlowBugID, "node_type": "END", "name": "Resolved", "position_x": 980, "position_y": 300},
		},
		"edges": []map[string]interface{}{
			{"id": "ee000002-0001-0000-0000-000000000001", "flow_id": demoFlowBugID, "source_node_id": "e2000001-0000-0000-0000-000000000001", "target_node_id": "e2000001-0000-0000-0000-000000000002", "label": "Report Filed"},
			{"id": "ee000002-0001-0000-0000-000000000002", "flow_id": demoFlowBugID, "source_node_id": "e2000001-0000-0000-0000-000000000002", "target_node_id": "e2000001-0000-0000-0000-000000000003", "label": "Confirmed"},
			{"id": "ee000002-0001-0000-0000-000000000003", "flow_id": demoFlowBugID, "source_node_id": "e2000001-0000-0000-0000-000000000003", "target_node_id": "e2000001-0000-0000-0000-000000000004", "label": "Fixed"},
			{"id": "ee000002-0001-0000-0000-000000000004", "flow_id": demoFlowBugID, "source_node_id": "e2000001-0000-0000-0000-000000000004", "target_node_id": "e2000001-0000-0000-0000-000000000005", "label": "Passed"},
			{"id": "ee000002-0001-0000-0000-000000000005", "flow_id": demoFlowBugID, "source_node_id": "e2000001-0000-0000-0000-000000000004", "target_node_id": "e2000001-0000-0000-0000-000000000003", "label": "Failed"},
		},
	},
	{
		"id": demoFlowProjectID, "company_id": demoCompanyID,
		"name":        "Client Project Approval",
		"description": "Multi-stage approval pipeline for new client projects",
		"is_active":   true,
		"created_at":  t68, "updated_at": t68,
		"nodes": []map[string]interface{}{
			{"id": "e3000001-0000-0000-0000-000000000001", "flow_id": demoFlowProjectID, "node_type": "START", "name": "Start", "position_x": 100, "position_y": 300},
			{"id": "e3000001-0000-0000-0000-000000000002", "flow_id": demoFlowProjectID, "node_type": "STEP", "name": "Initial Review", "position_x": 320, "position_y": 300, "assigned_role_id": demoRoleOpsID, "assigned_form_id": demoFormProjectID},
			{"id": "e3000001-0000-0000-0000-000000000003", "flow_id": demoFlowProjectID, "node_type": "DECISION", "name": "Director Approval", "position_x": 540, "position_y": 300, "assigned_role_id": demoRoleAdminID},
			{"id": "e3000001-0000-0000-0000-000000000004", "flow_id": demoFlowProjectID, "node_type": "STEP", "name": "Contract Sent", "position_x": 760, "position_y": 200, "assigned_role_id": demoRoleOpsID},
			{"id": "e3000001-0000-0000-0000-000000000005", "flow_id": demoFlowProjectID, "node_type": "END", "name": "Project Approved", "position_x": 980, "position_y": 200},
			{"id": "e3000001-0000-0000-0000-000000000006", "flow_id": demoFlowProjectID, "node_type": "END", "name": "Project Rejected", "position_x": 760, "position_y": 400},
		},
		"edges": []map[string]interface{}{
			{"id": "ee000003-0001-0000-0000-000000000001", "flow_id": demoFlowProjectID, "source_node_id": "e3000001-0000-0000-0000-000000000001", "target_node_id": "e3000001-0000-0000-0000-000000000002", "label": "Request Submitted"},
			{"id": "ee000003-0001-0000-0000-000000000002", "flow_id": demoFlowProjectID, "source_node_id": "e3000001-0000-0000-0000-000000000002", "target_node_id": "e3000001-0000-0000-0000-000000000003", "label": "Review Complete"},
			{"id": "ee000003-0001-0000-0000-000000000003", "flow_id": demoFlowProjectID, "source_node_id": "e3000001-0000-0000-0000-000000000003", "target_node_id": "e3000001-0000-0000-0000-000000000004", "label": "Approved"},
			{"id": "ee000003-0001-0000-0000-000000000004", "flow_id": demoFlowProjectID, "source_node_id": "e3000001-0000-0000-0000-000000000003", "target_node_id": "e3000001-0000-0000-0000-000000000006", "label": "Rejected"},
			{"id": "ee000003-0001-0000-0000-000000000005", "flow_id": demoFlowProjectID, "source_node_id": "e3000001-0000-0000-0000-000000000004", "target_node_id": "e3000001-0000-0000-0000-000000000005", "label": "Done"},
		},
	},
}

// DemoLetters contains the 3 demo letter templates.
var DemoLetters = []map[string]interface{}{
	{
		"id": demoLetterWelcomeID, "company_id": demoCompanyID,
		"name":        "Welcome Letter",
		"description": "Sent to new employees on their first day",
		"variables":   []string{"company.name", "user.name", "start_date", "manager.name"},
		"content": map[string]interface{}{
			"ops": []map[string]interface{}{
				{"insert": "Welcome to "},
				{"insert": "{{company.name}}!", "attributes": map[string]interface{}{"bold": true}},
				{"insert": "\n\nDear {{user.name}},\n\nWe are absolutely thrilled to have you join our team at Horizon Digital Agency. Your start date is confirmed as {{start_date}}. Please report to the main office at 9:00 AM.\n\nWarm regards,\nAlexandra Chen\nCEO, Horizon Digital Agency\n"},
			},
		},
		"created_at": t78, "updated_at": t78,
	},
	{
		"id": demoLetterApprovalID, "company_id": demoCompanyID,
		"name":        "Project Approval Notice",
		"description": "Formal notification of project approval",
		"variables":   []string{"requester.name", "project.title", "project.budget", "project.timeline", "approval_date"},
		"content": map[string]interface{}{
			"ops": []map[string]interface{}{
				{"insert": "Project Approval Notice\n", "attributes": map[string]interface{}{"bold": true}},
				{"insert": "\nDear {{requester.name}},\n\nWe are pleased to inform you that your project \"{{project.title}}\" has been approved with a budget of ${{project.budget}} and timeline of {{project.timeline}}.\n\nApproved on {{approval_date}}.\n\nBest regards,\nMarcus Thompson\nOperations Manager\n"},
			},
		},
		"created_at": t72, "updated_at": t72,
	},
	{
		"id": demoLetterContractID, "company_id": demoCompanyID,
		"name":        "Contract Template",
		"description": "Standard service agreement contract for client engagements",
		"variables":   []string{"contract_date", "client.company_name", "service_description", "contract_value", "start_date", "end_date"},
		"content": map[string]interface{}{
			"ops": []map[string]interface{}{
				{"insert": "Service Agreement\n", "attributes": map[string]interface{}{"bold": true}},
				{"insert": "\nThis Service Agreement is entered into as of {{contract_date}} between Horizon Digital Agency and {{client.company_name}}.\n\nScope: {{service_description}}\nCompensation: ${{contract_value}}\nTerm: {{start_date}} to {{end_date}}\n\nAgency: ________________________  Date: __________\n\nClient: ________________________  Date: __________\n"},
			},
		},
		"created_at": t68, "updated_at": t68,
	},
}

// DemoModels contains the 2 demo model definitions.
var DemoModels = []map[string]interface{}{
	{
		"id": demoModelClientID, "company_id": demoCompanyID,
		"name":        "Client",
		"description": "CRM-style client/customer records",
		"fields": []map[string]interface{}{
			{"id": "mf-cl-001", "name": "company_name", "label": "Company Name", "type": "text", "required": true},
			{"id": "mf-cl-002", "name": "industry", "label": "Industry", "type": "text"},
			{"id": "mf-cl-003", "name": "contact_email", "label": "Contact Email", "type": "email"},
			{"id": "mf-cl-004", "name": "annual_revenue", "label": "Annual Revenue ($)", "type": "number"},
			{"id": "mf-cl-005", "name": "contract_value", "label": "Contract Value ($)", "type": "number"},
			{"id": "mf-cl-006", "name": "status", "label": "Status", "type": "text"},
			{"id": "mf-cl-007", "name": "notes", "label": "Notes", "type": "text"},
		},
		"created_at": t66, "updated_at": t66,
	},
	{
		"id": demoModelAssetID, "company_id": demoCompanyID,
		"name":        "Asset",
		"description": "Tracks company hardware and digital assets",
		"fields": []map[string]interface{}{
			{"id": "mf-as-001", "name": "asset_name", "label": "Asset Name", "type": "text", "required": true},
			{"id": "mf-as-002", "name": "asset_type", "label": "Asset Type", "type": "text"},
			{"id": "mf-as-003", "name": "serial_number", "label": "Serial Number", "type": "text"},
			{"id": "mf-as-004", "name": "assigned_to", "label": "Assigned To", "type": "text"},
			{"id": "mf-as-005", "name": "purchase_date", "label": "Purchase Date", "type": "date"},
			{"id": "mf-as-006", "name": "warranty_expiry", "label": "Warranty Expiry", "type": "date"},
			{"id": "mf-as-007", "name": "value", "label": "Value ($)", "type": "number"},
			{"id": "mf-as-008", "name": "location", "label": "Location", "type": "text"},
		},
		"created_at": t66, "updated_at": t66,
	},
}

// userStub returns a minimal user object for embedding in tickets/messages.
func userStub(id, fullName, email, roleID, roleName, roleColor string) map[string]interface{} {
	return map[string]interface{}{
		"id":         id,
		"full_name":  fullName,
		"email":      email,
		"role_id":    roleID,
		"company_id": demoCompanyID,
		"avatar":     "",
		"is_active":  true,
		"role":       map[string]interface{}{"id": roleID, "name": roleName, "color": roleColor},
	}
}

var (
	sofiaStub     = userStub(demoUserSofiaID, "Sofia Rodriguez", "sofia@horizondigital.com", demoRoleSupportID, "Support Agent", "#f59e0b")
	marcusStub    = userStub(demoUserMarcusID, "Marcus Thompson", "marcus@horizondigital.com", demoRoleOpsID, "Operations Manager", "#10b981")
	jamesStub     = userStub(demoUserJamesID, "James Park", "james@horizondigital.com", demoRoleDevID, "Developer", "#3b82f6")
	alexandraStub = userStub(demoUserAlexandraID, "Alexandra Chen", "admin@horizondigital.com", demoRoleAdminID, "Administrator", "#6366f1")
	emilyStub     = userStub(demoUserEmilyID, "Emily Watson", "emily@horizondigital.com", demoRoleSupportID, "Support Agent", "#f59e0b")
)

func msg(id, ticketID string, sender map[string]interface{}, senderID, content, createdAt string) map[string]interface{} {
	return map[string]interface{}{
		"id":          id,
		"ticket_id":   ticketID,
		"sender_id":   senderID,
		"content":     content,
		"attachments": []interface{}{},
		"created_at":  createdAt,
		"updated_at":  createdAt,
		"sender":      sender,
	}
}

// DemoTickets contains the 8 demo tickets with messages.
var DemoTickets = []map[string]interface{}{
	{
		"id": demoTicket1ID, "company_id": demoCompanyID,
		"subject_title": "Cannot access company dashboard",
		"status":        "OPEN",
		"creator_id":    demoUserSofiaID,
		"assigned_to_id": demoUserMarcusID,
		"created_at":    t45, "updated_at": t45,
		"creator":     sofiaStub,
		"assigned_to": marcusStub,
		"messages": []map[string]interface{}{
			msg("bb000001-0001-0000-0000-000000000001", demoTicket1ID, sofiaStub, demoUserSofiaID, "Hi team, I've been unable to access the company dashboard since this morning. When I navigate to it I get a blank white screen. I've tried refreshing and clearing cache but the issue persists. My role is Support Agent.", t45),
			msg("bb000001-0001-0000-0000-000000000002", demoTicket1ID, marcusStub, demoUserMarcusID, "Thanks for reporting this, Sofia. I can reproduce the issue from my end too for the support agent role. It looks like a recent permission change might be blocking dashboard access. I'll investigate and loop in James if it's a backend issue.", now.AddDate(0, 0, -44).Format(time.RFC3339)),
			msg("bb000001-0001-0000-0000-000000000003", demoTicket1ID, sofiaStub, demoUserSofiaID, "Thank you Marcus. Just to confirm – the issue is only happening on the dashboard page. All other pages like Tickets and Forms load fine for me.", now.AddDate(0, 0, -44).Format(time.RFC3339)),
		},
	},
	{
		"id": demoTicket2ID, "company_id": demoCompanyID,
		"subject_title":  "Flow editor crashes on save",
		"status":         "IN_PROGRESS",
		"creator_id":     demoUserJamesID,
		"assigned_to_id": demoUserJamesID,
		"created_at":     t40, "updated_at": t38,
		"creator":     jamesStub,
		"assigned_to": jamesStub,
		"messages": []map[string]interface{}{
			msg("bb000002-0001-0000-0000-000000000001", demoTicket2ID, jamesStub, demoUserJamesID, "I've found a critical bug in the flow editor. When you have more than 8 nodes and try to save the graph, the browser throws a 413 Payload Too Large error and the save fails. The console shows the request body is exceeding the nginx limit.", t40),
			msg("bb000002-0001-0000-0000-000000000002", demoTicket2ID, alexandraStub, demoUserAlexandraID, "This is a blocker for the onboarding flow we're building. James, can you look into increasing the payload limit? Also check if we can chunk the save request.", now.AddDate(0, 0, -39).Format(time.RFC3339)),
			msg("bb000002-0001-0000-0000-000000000003", demoTicket2ID, jamesStub, demoUserJamesID, "I've identified two fixes: (1) increase nginx client_max_body_size to 10mb, and (2) add server-side pagination to the graph load endpoint. I'm implementing both now. ETA: today.", t38),
			msg("bb000002-0001-0000-0000-000000000004", demoTicket2ID, jamesStub, demoUserJamesID, "Fix deployed to staging. nginx limit increased and the save endpoint now handles large payloads. Testing confirmed flows with 15+ nodes save correctly. Will deploy to production after QA sign-off.", t38),
		},
	},
	{
		"id": demoTicket3ID, "company_id": demoCompanyID,
		"subject_title":  "Request: Add bulk user import feature",
		"status":         "OPEN",
		"creator_id":     demoUserEmilyID,
		"assigned_to_id": nil,
		"created_at":     t38, "updated_at": now.AddDate(0, 0, -37).Format(time.RFC3339),
		"creator":     emilyStub,
		"assigned_to": nil,
		"messages": []map[string]interface{}{
			msg("bb000003-0001-0000-0000-000000000001", demoTicket3ID, emilyStub, demoUserEmilyID, "Feature request: We need a way to bulk-import users from a CSV file. We have a new client with 150 employees to onboard and creating them one-by-one is not feasible. The CSV should support: full_name, email, role, department.", t38),
			msg("bb000003-0001-0000-0000-000000000002", demoTicket3ID, marcusStub, demoUserMarcusID, "Great idea Emily. I'm adding this to our Q2 roadmap. We'll design the CSV schema to include: full_name, email, role_name, and an optional password (if omitted we'll send a set-password email). James will own the implementation.", now.AddDate(0, 0, -37).Format(time.RFC3339)),
		},
	},
	{
		"id": demoTicket4ID, "company_id": demoCompanyID,
		"subject_title":  "Performance issues in ticket list view",
		"status":         "CLOSED",
		"creator_id":     demoUserMarcusID,
		"assigned_to_id": demoUserJamesID,
		"created_at":     t55, "updated_at": t20,
		"creator":     marcusStub,
		"assigned_to": jamesStub,
		"messages": []map[string]interface{}{
			msg("bb000004-0001-0000-0000-000000000001", demoTicket4ID, marcusStub, demoUserMarcusID, "The ticket list page is very slow when there are more than 200 tickets. Initial load takes 8+ seconds. The browser dev tools show the API response is ~4MB of JSON.", t55),
			msg("bb000004-0001-0000-0000-000000000002", demoTicket4ID, jamesStub, demoUserJamesID, "I've looked at the query. The tickets endpoint is doing a full table scan and loading all message relations eagerly. I'll add pagination (default 50/page), add a DB index on company_id+status, and change messages to lazy-load.", now.AddDate(0, 0, -52).Format(time.RFC3339)),
			msg("bb000004-0001-0000-0000-000000000003", demoTicket4ID, marcusStub, demoUserMarcusID, "Any ETA? This is really impacting the support team's productivity.", now.AddDate(0, 0, -50).Format(time.RFC3339)),
			msg("bb000004-0001-0000-0000-000000000004", demoTicket4ID, jamesStub, demoUserJamesID, "Deployed fix: added pagination, DB indexes, and lazy-load for messages. List load time is now under 300ms for 500+ tickets in load testing.", now.AddDate(0, 0, -22).Format(time.RFC3339)),
			msg("bb000004-0001-0000-0000-000000000005", demoTicket4ID, marcusStub, demoUserMarcusID, "Confirmed – ticket list is lightning fast now. Closing this ticket. Great work James!", t20),
		},
	},
	{
		"id": demoTicket5ID, "company_id": demoCompanyID,
		"subject_title":  "Form submission not saving data",
		"status":         "IN_PROGRESS",
		"creator_id":     demoUserSofiaID,
		"assigned_to_id": demoUserJamesID,
		"created_at":     t30, "updated_at": now.AddDate(0, 0, -28).Format(time.RFC3339),
		"creator":     sofiaStub,
		"assigned_to": jamesStub,
		"messages": []map[string]interface{}{
			msg("bb000005-0001-0000-0000-000000000001", demoTicket5ID, sofiaStub, demoUserSofiaID, "When I complete a form within a flow instance and click Submit, I get a success toast but when I reload the instance the form data is missing. Happened with the Employee Onboarding form on 3 separate instances.", t30),
			msg("bb000005-0001-0000-0000-000000000002", demoTicket5ID, jamesStub, demoUserJamesID, "Reproducing now. The issue looks like a race condition – the frontend sends the form submission and immediately advances the instance step before the DB write completes. I need to make the advance call wait for the submission to be confirmed.", now.AddDate(0, 0, -29).Format(time.RFC3339)),
			msg("bb000005-0001-0000-0000-000000000003", demoTicket5ID, sofiaStub, demoUserSofiaID, "Thanks James. Can you let me know when the fix is deployed so I can retest? I'll hold off on using forms in flows until then.", now.AddDate(0, 0, -28).Format(time.RFC3339)),
		},
	},
	{
		"id": demoTicket6ID, "company_id": demoCompanyID,
		"subject_title":  "Integration with Slack notifications",
		"status":         "OPEN",
		"creator_id":     demoUserMarcusID,
		"assigned_to_id": nil,
		"created_at":     t25, "updated_at": now.AddDate(0, 0, -24).Format(time.RFC3339),
		"creator":     marcusStub,
		"assigned_to": nil,
		"messages": []map[string]interface{}{
			msg("bb000006-0001-0000-0000-000000000001", demoTicket6ID, marcusStub, demoUserMarcusID, "Would love to have Slack notifications when a ticket is assigned or a flow instance reaches a step requiring action. This would massively improve response times for the support team.", t25),
			msg("bb000006-0001-0000-0000-000000000002", demoTicket6ID, alexandraStub, demoUserAlexandraID, "Agreed – a webhook/integration system is on our roadmap. I've added Slack as the first integration target for Q3. Marcus, can you document the specific event triggers you need (ticket assigned, step pending, instance completed)?", now.AddDate(0, 0, -24).Format(time.RFC3339)),
		},
	},
	{
		"id": demoTicket7ID, "company_id": demoCompanyID,
		"subject_title":  "User role permissions not applying correctly",
		"status":         "CLOSED",
		"creator_id":     demoUserEmilyID,
		"assigned_to_id": demoUserMarcusID,
		"created_at":     t60, "updated_at": t15,
		"creator":     emilyStub,
		"assigned_to": marcusStub,
		"messages": []map[string]interface{}{
			msg("bb000007-0001-0000-0000-000000000001", demoTicket7ID, emilyStub, demoUserEmilyID, "The Viewer role isn't restricting access properly. Users with the Viewer role can still click the 'Create Ticket' button and the button is visible in the UI. I thought Viewers should be read-only.", t60),
			msg("bb000007-0001-0000-0000-000000000002", demoTicket7ID, marcusStub, demoUserMarcusID, "Confirmed. The backend is correctly rejecting the create request (403 Forbidden), but the frontend isn't reading the permissions from the JWT claims to conditionally hide the button. This is a UI issue.", now.AddDate(0, 0, -58).Format(time.RFC3339)),
			msg("bb000007-0001-0000-0000-000000000003", demoTicket7ID, marcusStub, demoUserMarcusID, "Fix deployed: the frontend now reads the `permissions` object from user context and conditionally renders action buttons. All create/edit/delete buttons are hidden for Viewers across all resource types.", now.AddDate(0, 0, -17).Format(time.RFC3339)),
			msg("bb000007-0001-0000-0000-000000000004", demoTicket7ID, emilyStub, demoUserEmilyID, "Tested with a Viewer account – all create/edit/delete buttons are properly hidden. Closing this ticket.", t15),
		},
	},
	{
		"id": demoTicket8ID, "company_id": demoCompanyID,
		"subject_title":  "Generate letter template not working",
		"status":         "IN_PROGRESS",
		"creator_id":     demoUserSofiaID,
		"assigned_to_id": demoUserJamesID,
		"created_at":     t10, "updated_at": now.AddDate(0, 0, -9).Format(time.RFC3339),
		"creator":     sofiaStub,
		"assigned_to": jamesStub,
		"messages": []map[string]interface{}{
			msg("bb000008-0001-0000-0000-000000000001", demoTicket8ID, sofiaStub, demoUserSofiaID, "When I try to generate a letter from the Welcome Letter template, I click 'Generate' and the page just spins indefinitely. No error message is shown. This is blocking us from sending onboarding letters.", t10),
			msg("bb000008-0001-0000-0000-000000000002", demoTicket8ID, jamesStub, demoUserJamesID, "Found the issue. The letter generation endpoint is trying to parse the Quill delta JSON using an incorrect schema – it's treating it as a plain string. The variable substitution then fails silently and the response hangs. Fix incoming.", now.AddDate(0, 0, -9).Format(time.RFC3339)),
			msg("bb000008-0001-0000-0000-000000000003", demoTicket8ID, sofiaStub, demoUserSofiaID, "Thanks James – any idea on ETA? We have 3 new employees starting next week and need to get their welcome letters out.", now.AddDate(0, 0, -9).Format(time.RFC3339)),
		},
	},
}

// DemoInstances contains the 3 demo flow instances.
var DemoInstances = []map[string]interface{}{
	{
		"id": demoInstanceBugID, "company_id": demoCompanyID,
		"flow_id":         demoFlowBugID,
		"current_node_id": "e2000001-0000-0000-0000-000000000003",
		"status":          "ACTIVE",
		"started_by_id":   demoUserSofiaID,
		"created_at":      t35, "updated_at": now.AddDate(0, 0, -33).Format(time.RFC3339),
		"started_by": sofiaStub,
		"flow": map[string]interface{}{
			"id": demoFlowBugID, "name": "Bug Resolution Workflow",
		},
		"steps": []map[string]interface{}{
			{"id": "is-bug-001", "flow_instance_id": demoInstanceBugID, "node_id": "e2000001-0000-0000-0000-000000000002", "status": "COMPLETED", "assigned_to_role_id": demoRoleSupportID, "completed_at": now.AddDate(0, 0, -34).Format(time.RFC3339)},
			{"id": "is-bug-002", "flow_instance_id": demoInstanceBugID, "node_id": "e2000001-0000-0000-0000-000000000003", "status": "PENDING", "assigned_to_role_id": demoRoleDevID},
		},
	},
	{
		"id": demoInstanceOnbID, "company_id": demoCompanyID,
		"flow_id":         demoFlowOnboardingID,
		"current_node_id": "e1000001-0000-0000-0000-000000000006",
		"status":          "COMPLETED",
		"started_by_id":   demoUserAlexandraID,
		"created_at":      now.AddDate(0, 0, -70).Format(time.RFC3339), "updated_at": now.AddDate(0, 0, -50).Format(time.RFC3339),
		"started_by": alexandraStub,
		"flow": map[string]interface{}{
			"id": demoFlowOnboardingID, "name": "Employee Onboarding Process",
		},
		"steps": []map[string]interface{}{
			{"id": "is-onb-001", "flow_instance_id": demoInstanceOnbID, "node_id": "e1000001-0000-0000-0000-000000000002", "status": "COMPLETED", "assigned_to_role_id": demoRoleOpsID, "completed_at": now.AddDate(0, 0, -68).Format(time.RFC3339)},
			{"id": "is-onb-002", "flow_instance_id": demoInstanceOnbID, "node_id": "e1000001-0000-0000-0000-000000000003", "status": "COMPLETED", "assigned_to_role_id": demoRoleDevID, "completed_at": now.AddDate(0, 0, -65).Format(time.RFC3339)},
			{"id": "is-onb-003", "flow_instance_id": demoInstanceOnbID, "node_id": "e1000001-0000-0000-0000-000000000004", "status": "COMPLETED", "assigned_to_role_id": demoRoleOpsID, "completed_at": now.AddDate(0, 0, -62).Format(time.RFC3339)},
			{"id": "is-onb-004", "flow_instance_id": demoInstanceOnbID, "node_id": "e1000001-0000-0000-0000-000000000005", "status": "COMPLETED", "assigned_to_role_id": demoRoleOpsID, "completed_at": now.AddDate(0, 0, -58).Format(time.RFC3339)},
		},
	},
	{
		"id": demoInstanceProjectID, "company_id": demoCompanyID,
		"flow_id":         demoFlowProjectID,
		"current_node_id": "e3000001-0000-0000-0000-000000000003",
		"status":          "ACTIVE",
		"started_by_id":   demoUserMarcusID,
		"created_at":      t20, "updated_at": now.AddDate(0, 0, -18).Format(time.RFC3339),
		"started_by": marcusStub,
		"flow": map[string]interface{}{
			"id": demoFlowProjectID, "name": "Client Project Approval",
		},
		"steps": []map[string]interface{}{
			{"id": "is-proj-001", "flow_instance_id": demoInstanceProjectID, "node_id": "e3000001-0000-0000-0000-000000000002", "status": "COMPLETED", "assigned_to_role_id": demoRoleOpsID, "completed_at": now.AddDate(0, 0, -19).Format(time.RFC3339)},
			{"id": "is-proj-002", "flow_instance_id": demoInstanceProjectID, "node_id": "e3000001-0000-0000-0000-000000000003", "status": "PENDING", "assigned_to_role_id": demoRoleAdminID},
		},
	},
}

// ---------- Handle + Middleware ----------

// Handle inspects the Gin route template and, if it matches a known demo endpoint,
// writes the appropriate JSON response and returns true.
// If the route is not handled, it returns false and the real handler should run.
func Handle(c *gin.Context) bool {
	path := c.FullPath()
	method := c.Request.Method

	// Write-operations in demo mode: return a friendly notice.
	if method == http.MethodPost || method == http.MethodPut || method == http.MethodPatch || method == http.MethodDelete {
		// Special case: allow posting messages so the UI doesn't break.
		if path == "/api/v1/companies/:cid/tickets/:id/messages" {
			c.JSON(http.StatusCreated, map[string]interface{}{
				"id":          "demo-msg-" + c.Param("id"),
				"ticket_id":   c.Param("id"),
				"sender_id":   demoUserDemoID,
				"content":     "Demo mode: this message was not persisted.",
				"attachments": []interface{}{},
				"created_at":  now.Format(time.RFC3339),
				"updated_at":  now.Format(time.RFC3339),
				"sender":      DemoUser,
			})
			return true
		}
		c.JSON(http.StatusOK, gin.H{"message": "Demo mode: changes not persisted"})
		return true
	}

	switch path {
	// Stats
	case "/api/v1/companies/:cid/stats":
		c.JSON(http.StatusOK, DemoStats)
		return true

	// Users
	case "/api/v1/companies/:cid/users":
		c.JSON(http.StatusOK, gin.H{"users": DemoUsers, "total": 6})
		return true
	case "/api/v1/companies/:cid/users/:id":
		id := c.Param("id")
		for _, u := range DemoUsers {
			if u["id"] == id {
				c.JSON(http.StatusOK, u)
				return true
			}
		}
		c.JSON(http.StatusOK, DemoUsers[0])
		return true

	// Roles
	case "/api/v1/companies/:cid/roles":
		c.JSON(http.StatusOK, gin.H{"roles": DemoRoles, "total": 5})
		return true

	// Flows
	case "/api/v1/companies/:cid/flows":
		c.JSON(http.StatusOK, gin.H{"flows": DemoFlows, "total": 3})
		return true
	case "/api/v1/companies/:cid/flows/:id",
		"/api/v1/companies/:cid/flows/:id/nodes",
		"/api/v1/companies/:cid/flows/:id/edges",
		"/api/v1/companies/:cid/flows/:id/assignments":
		id := c.Param("id")
		for _, f := range DemoFlows {
			if f["id"] == id {
				c.JSON(http.StatusOK, f)
				return true
			}
		}
		c.JSON(http.StatusOK, DemoFlows[0])
		return true

	// Flow graph save (PUT)
	case "/api/v1/companies/:cid/flows/:id/graph":
		c.JSON(http.StatusOK, gin.H{"message": "Demo mode: changes not persisted"})
		return true

	// Forms
	case "/api/v1/companies/:cid/forms":
		c.JSON(http.StatusOK, gin.H{"forms": DemoForms, "total": 4})
		return true
	case "/api/v1/companies/:cid/forms/:id":
		id := c.Param("id")
		for _, f := range DemoForms {
			if f["id"] == id {
				c.JSON(http.StatusOK, f)
				return true
			}
		}
		c.JSON(http.StatusOK, DemoForms[0])
		return true

	// Letters
	case "/api/v1/companies/:cid/letters":
		c.JSON(http.StatusOK, gin.H{"templates": DemoLetters, "total": 3})
		return true
	case "/api/v1/companies/:cid/letters/:id",
		"/api/v1/companies/:cid/letters/:id/generate":
		id := c.Param("id")
		for _, l := range DemoLetters {
			if l["id"] == id {
				c.JSON(http.StatusOK, l)
				return true
			}
		}
		c.JSON(http.StatusOK, DemoLetters[0])
		return true

	// Models
	case "/api/v1/companies/:cid/models":
		c.JSON(http.StatusOK, gin.H{"models": DemoModels, "total": 2})
		return true
	case "/api/v1/companies/:cid/models/:id":
		id := c.Param("id")
		for _, m := range DemoModels {
			if m["id"] == id {
				c.JSON(http.StatusOK, m)
				return true
			}
		}
		c.JSON(http.StatusOK, DemoModels[0])
		return true
	case "/api/v1/companies/:cid/models/:id/entities",
		"/api/v1/companies/:cid/models/:id/entities/:eid":
		c.JSON(http.StatusOK, gin.H{"entities": []interface{}{}, "total": 0})
		return true

	// Tickets
	case "/api/v1/companies/:cid/tickets":
		c.JSON(http.StatusOK, gin.H{"tickets": DemoTickets, "total": 8})
		return true
	case "/api/v1/companies/:cid/tickets/:id":
		id := c.Param("id")
		for _, t := range DemoTickets {
			if t["id"] == id {
				c.JSON(http.StatusOK, t)
				return true
			}
		}
		c.JSON(http.StatusOK, DemoTickets[0])
		return true
	case "/api/v1/companies/:cid/tickets/:id/messages":
		// GET messages for a ticket
		id := c.Param("id")
		for _, t := range DemoTickets {
			if t["id"] == id {
				c.JSON(http.StatusOK, gin.H{"messages": t["messages"]})
				return true
			}
		}
		c.JSON(http.StatusOK, gin.H{"messages": []interface{}{}})
		return true

	// Instances
	case "/api/v1/companies/:cid/instances":
		c.JSON(http.StatusOK, gin.H{"instances": DemoInstances, "total": 3})
		return true
	case "/api/v1/companies/:cid/instances/:id":
		id := c.Param("id")
		for _, inst := range DemoInstances {
			if inst["id"] == id {
				c.JSON(http.StatusOK, inst)
				return true
			}
		}
		c.JSON(http.StatusOK, DemoInstances[0])
		return true
	case "/api/v1/companies/:cid/instances/my-tasks":
		c.JSON(http.StatusOK, gin.H{"tasks": []interface{}{}, "total": 0})
		return true

	// Companies
	case "/api/v1/companies":
		c.JSON(http.StatusOK, []interface{}{DemoCompany})
		return true
	case "/api/v1/companies/:id":
		c.JSON(http.StatusOK, DemoCompany)
		return true
	case "/api/v1/companies/:id/members":
		c.JSON(http.StatusOK, gin.H{"members": DemoUsers, "total": 6})
		return true
	}

	// Not handled – let the real handler run.
	return false
}

// Middleware returns a Gin middleware that intercepts requests from the demo
// user (identified by the "is_demo" context key set during JWT validation) and
// returns hardcoded demo data instead of hitting the database.
func Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		if c.GetBool("is_demo") {
			if Handle(c) {
				c.Abort()
				return
			}
		}
		c.Next()
	}
}
