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
	Website     string `json:"website"`
	Industry    string `json:"industry"`
}

// UpdateCompanyRequest allows updating mutable company fields.
type UpdateCompanyRequest struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	Logo        string `json:"logo"`
	Website     string `json:"website"`
	Industry    string `json:"industry"`
}

// CompanyResponse is the public-facing company object.
// Uses camelCase to match Flutter's Company.fromJson.
type CompanyResponse struct {
	ID          uuid.UUID `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Logo        string    `json:"logo"`
	Website     string    `json:"website"`
	Industry    string    `json:"industry"`
	OwnerID     uuid.UUID `json:"ownerId"`
	Status      string    `json:"status"`
	MemberCount int64     `json:"memberCount"`
	FlowCount   int64     `json:"flowCount"`
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt"`
}

// AddMemberRequest adds a user to a company with an optional role.
type AddMemberRequest struct {
	UserID uuid.UUID `json:"userId" binding:"required"`
	RoleID uuid.UUID `json:"roleId" binding:"required"`
}
