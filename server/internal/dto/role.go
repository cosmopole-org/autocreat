package dto

import (
	"time"

	"github.com/google/uuid"
)

// Permission describes access rights for a resource.
// Shape matches Flutter's Permission.fromJson.
type Permission struct {
	Resource      string   `json:"resource"`
	CanCreate     bool     `json:"canCreate"`
	CanRead       bool     `json:"canRead"`
	CanUpdate     bool     `json:"canUpdate"`
	CanDelete     bool     `json:"canDelete"`
	CustomActions []string `json:"customActions"`
}

// RuleSet defines conditional access rules.
type RuleSet struct {
	ID          string                   `json:"id"`
	Name        string                   `json:"name"`
	Description string                   `json:"description"`
	Conditions  []map[string]interface{} `json:"conditions"`
	Action      string                   `json:"action"`
}

// CreateRoleRequest is the payload for creating a company role.
type CreateRoleRequest struct {
	Name        string       `json:"name"        binding:"required"`
	Description string       `json:"description"`
	Level       string       `json:"level"`
	Permissions []Permission `json:"permissions"`
	RuleSets    []RuleSet    `json:"ruleSets"`
	IsActive    *bool        `json:"isActive"`
}

// UpdateRoleRequest allows modifying a role's definition.
type UpdateRoleRequest struct {
	Name        string       `json:"name"`
	Description string       `json:"description"`
	Level       string       `json:"level"`
	Permissions []Permission `json:"permissions"`
	RuleSets    []RuleSet    `json:"ruleSets"`
	IsActive    *bool        `json:"isActive"`
}

// RoleResponse is the public role representation.
// Uses camelCase to match Flutter's Role.fromJson.
type RoleResponse struct {
	ID          uuid.UUID    `json:"id"`
	CompanyID   uuid.UUID    `json:"companyId"`
	Name        string       `json:"name"`
	Description string       `json:"description"`
	Level       string       `json:"level"`
	IsActive    bool         `json:"isActive"`
	Permissions []Permission `json:"permissions"`
	RuleSets    []RuleSet    `json:"ruleSets"`
	MemberCount int64        `json:"memberCount"`
	CreatedAt   time.Time    `json:"createdAt"`
	UpdatedAt   time.Time    `json:"updatedAt"`
}
