package dto

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// Permission describes access rights for a resource.
type Permission struct {
	Resource   string          `json:"resource"`
	Actions    []string        `json:"actions"` // create, read, update, delete
	Conditions json.RawMessage `json:"conditions,omitempty"`
}

// CreateRoleRequest is the payload for creating a company role.
type CreateRoleRequest struct {
	Name        string       `json:"name"        binding:"required"`
	Description string       `json:"description"`
	Color       string       `json:"color"`
	Permissions []Permission `json:"permissions"`
}

// UpdateRoleRequest allows modifying a role's definition.
type UpdateRoleRequest struct {
	Name        string       `json:"name"`
	Description string       `json:"description"`
	Color       string       `json:"color"`
	Permissions []Permission `json:"permissions"`
}

// RoleResponse is the public role representation.
type RoleResponse struct {
	ID          uuid.UUID       `json:"id"`
	CompanyID   uuid.UUID       `json:"company_id"`
	Name        string          `json:"name"`
	Description string          `json:"description"`
	Color       string          `json:"color"`
	Permissions json.RawMessage `json:"permissions"`
	CreatedAt   time.Time       `json:"created_at"`
	UpdatedAt   time.Time       `json:"updated_at"`
}
