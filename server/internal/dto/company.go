package dto

import (
	"time"

	"github.com/google/uuid"
)

// CreateCompanyRequest is the payload for creating a new company.
type CreateCompanyRequest struct {
	Name        string `json:"name"        binding:"required"`
	Description string `json:"description"`
	Logo        string `json:"logo"`
}

// UpdateCompanyRequest allows updating mutable company fields.
type UpdateCompanyRequest struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	Logo        string `json:"logo"`
}

// CompanyResponse is the public-facing company object.
type CompanyResponse struct {
	ID          uuid.UUID `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Logo        string    `json:"logo"`
	OwnerID     uuid.UUID `json:"owner_id"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// AddMemberRequest adds a user to a company with an optional role.
type AddMemberRequest struct {
	UserID uuid.UUID `json:"user_id" binding:"required"`
	RoleID uuid.UUID `json:"role_id" binding:"required"`
}
