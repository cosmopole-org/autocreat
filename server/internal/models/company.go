package models

import (
	"time"

	"github.com/google/uuid"
)

// CompanyStatus enumerates valid company lifecycle states.
type CompanyStatus string

const (
	CompanyStatusActive    CompanyStatus = "active"
	CompanyStatusInactive  CompanyStatus = "inactive"
	CompanyStatusSuspended CompanyStatus = "suspended"
)

// Company is the top-level organizational unit.
type Company struct {
	BaseModel
	Name        string        `gorm:"not null" json:"name"`
	Description string        `json:"description"`
	Logo        string        `json:"logo"`
	Website     string        `json:"website"`
	Industry    string        `json:"industry"`
	Status      CompanyStatus `gorm:"not null;default:'active'" json:"status"`
	OwnerID     uuid.UUID     `gorm:"type:uuid;not null" json:"ownerId"`

	Owner   *User           `gorm:"foreignKey:OwnerID" json:"-"`
	Members []CompanyMember `gorm:"foreignKey:CompanyID" json:"-"`
	Roles   []Role          `gorm:"foreignKey:CompanyID" json:"-"`
}

// CompanyMember tracks which users belong to which company with which role.
type CompanyMember struct {
	CompanyID uuid.UUID `gorm:"type:uuid;primaryKey" json:"companyId"`
	UserID    uuid.UUID `gorm:"type:uuid;primaryKey" json:"userId"`
	RoleID    uuid.UUID `gorm:"type:uuid" json:"roleId"`
	JoinedAt  time.Time `gorm:"autoCreateTime" json:"joinedAt"`

	Company Company `gorm:"foreignKey:CompanyID" json:"-"`
	User    User    `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Role    Role    `gorm:"foreignKey:RoleID" json:"role,omitempty"`
}

// Role defines a set of permissions within a company.
type Role struct {
	BaseModel
	CompanyID   uuid.UUID  `gorm:"type:uuid;not null;index" json:"companyId"`
	Name        string     `gorm:"not null" json:"name"`
	Description string     `json:"description"`
	Level       string     `gorm:"not null;default:'member'" json:"level"`
	IsActive    bool       `gorm:"default:true" json:"isActive"`
	Permissions string     `gorm:"type:jsonb;default:'[]'" json:"permissions"`
	RuleSets    string     `gorm:"type:jsonb;default:'[]'" json:"ruleSets"`
}
