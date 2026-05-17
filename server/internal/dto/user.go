package dto

import (
	"time"

	"github.com/google/uuid"
)

// UserResponse is the public-facing representation of a user.
// Uses camelCase JSON keys to match Flutter's User.fromJson.
type UserResponse struct {
	ID          uuid.UUID   `json:"id"`
	Email       string      `json:"email"`
	FirstName   string      `json:"firstName"`
	LastName    string      `json:"lastName"`
	Avatar      string      `json:"avatar"`
	Phone       string      `json:"phone"`
	Role        string      `json:"role"`
	IsActive    bool        `json:"isActive"`
	CompanyID   *uuid.UUID  `json:"companyId"`
	RoleID      *uuid.UUID  `json:"roleId"`
	Permissions []string    `json:"permissions"`
	CreatedAt   time.Time   `json:"createdAt"`
	UpdatedAt   time.Time   `json:"updatedAt"`
}

// CreateUserRequest is used by admins to create a user inside a company.
type CreateUserRequest struct {
	Email     string     `json:"email"      binding:"required,email"`
	Password  string     `json:"password"   binding:"required,min=8"`
	FirstName string     `json:"firstName"  binding:"required"`
	LastName  string     `json:"lastName"   binding:"required"`
	Phone     string     `json:"phone"`
	Avatar    string     `json:"avatar"`
	RoleID    *uuid.UUID `json:"roleId"`
}

// UpdateUserRequest allows updating mutable user fields.
type UpdateUserRequest struct {
	FirstName string     `json:"firstName"`
	LastName  string     `json:"lastName"`
	Phone     string     `json:"phone"`
	Avatar    string     `json:"avatar"`
	RoleID    *uuid.UUID `json:"roleId"`
	IsActive  *bool      `json:"isActive"`
}

// AssignRoleRequest changes a user's role.
type AssignRoleRequest struct {
	RoleID string `json:"roleId" binding:"required"`
}
