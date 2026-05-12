package models

import (
	"time"

	"github.com/google/uuid"
)

// User represents an application user that belongs to a company.
type User struct {
	BaseModel
	Email        string     `gorm:"uniqueIndex;not null" json:"email"`
	PasswordHash string     `gorm:"not null" json:"-"`
	FullName     string     `gorm:"not null" json:"full_name"`
	CompanyID    *uuid.UUID `gorm:"type:uuid;index" json:"company_id"`
	RoleID       *uuid.UUID `gorm:"type:uuid;index" json:"role_id"`
	Avatar       string     `json:"avatar"`
	IsActive     bool       `gorm:"default:true" json:"is_active"`
	IsOwner      bool       `gorm:"default:false" json:"is_owner"`

	// Associations
	Company *Company `gorm:"foreignKey:CompanyID" json:"company,omitempty"`
	Role    *Role    `gorm:"foreignKey:RoleID" json:"role,omitempty"`
}

// Session stores refresh tokens for authenticated users.
type Session struct {
	ID           uuid.UUID `gorm:"type:uuid;primaryKey" json:"id"`
	UserID       uuid.UUID `gorm:"type:uuid;not null;index" json:"user_id"`
	RefreshToken string    `gorm:"not null;uniqueIndex" json:"-"`
	ExpiresAt    time.Time `gorm:"not null" json:"expires_at"`
	CreatedAt    time.Time `json:"created_at"`

	User User `gorm:"foreignKey:UserID" json:"-"`
}
