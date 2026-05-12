package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
)

// Company is the top-level organizational unit.
type Company struct {
	BaseModel
	Name        string     `gorm:"not null" json:"name"`
	Description string     `json:"description"`
	Logo        string     `json:"logo"`
	OwnerID     uuid.UUID  `gorm:"type:uuid;not null" json:"owner_id"`

	Owner   *User           `gorm:"foreignKey:OwnerID" json:"owner,omitempty"`
	Members []CompanyMember `gorm:"foreignKey:CompanyID" json:"members,omitempty"`
	Roles   []Role          `gorm:"foreignKey:CompanyID" json:"roles,omitempty"`
}

// CompanyMember tracks which users belong to which company with which role.
type CompanyMember struct {
	CompanyID uuid.UUID `gorm:"type:uuid;primaryKey" json:"company_id"`
	UserID    uuid.UUID `gorm:"type:uuid;primaryKey" json:"user_id"`
	RoleID    uuid.UUID `gorm:"type:uuid" json:"role_id"`
	JoinedAt  time.Time `gorm:"autoCreateTime" json:"joined_at"`

	Company Company `gorm:"foreignKey:CompanyID" json:"-"`
	User    User    `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Role    Role    `gorm:"foreignKey:RoleID" json:"role,omitempty"`
}

// Role defines a set of permissions within a company.
type Role struct {
	BaseModel
	CompanyID   uuid.UUID      `gorm:"type:uuid;not null;index" json:"company_id"`
	Name        string         `gorm:"not null" json:"name"`
	Description string         `json:"description"`
	Color       string         `json:"color"`
	Permissions datatypes.JSON `gorm:"type:jsonb" json:"permissions"`
}
