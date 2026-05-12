package dto

import (
	"time"

	"github.com/google/uuid"
)

// UserResponse is the public-facing representation of a user.
type UserResponse struct {
	ID        uuid.UUID  `json:"id"`
	Email     string     `json:"email"`
	FullName  string     `json:"full_name"`
	CompanyID *uuid.UUID `json:"company_id"`
	RoleID    *uuid.UUID `json:"role_id"`
	Avatar    string     `json:"avatar"`
	IsActive  bool       `json:"is_active"`
	IsOwner   bool       `json:"is_owner"`
	CreatedAt time.Time  `json:"created_at"`
}

// CreateUserRequest is used by admins to create a user inside a company.
type CreateUserRequest struct {
	Email    string     `json:"email"     binding:"required,email"`
	Password string     `json:"password"  binding:"required,min=8"`
	FullName string     `json:"full_name" binding:"required"`
	RoleID   *uuid.UUID `json:"role_id"`
	Avatar   string     `json:"avatar"`
}

// UpdateUserRequest allows updating mutable user fields.
type UpdateUserRequest struct {
	FullName string     `json:"full_name"`
	RoleID   *uuid.UUID `json:"role_id"`
	Avatar   string     `json:"avatar"`
	IsActive *bool      `json:"is_active"`
}
