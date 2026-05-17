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
	FirstName    string     `gorm:"not null;default:''" json:"firstName"`
	LastName     string     `gorm:"not null;default:''" json:"lastName"`
	Phone        string     `gorm:"default:''" json:"phone"`
	CompanyID    *uuid.UUID `gorm:"type:uuid;index" json:"companyId"`
	RoleID       *uuid.UUID `gorm:"type:uuid;index" json:"roleId"`
	Avatar       string     `gorm:"default:''" json:"avatar"`
	IsActive     bool       `gorm:"default:true" json:"isActive"`
	IsOwner      bool       `gorm:"default:false" json:"isOwner"`

	// Associations
	Company *Company `gorm:"foreignKey:CompanyID" json:"-"`
	Role    *Role    `gorm:"foreignKey:RoleID" json:"-"`
}

// FullName returns the combined display name.
func (u *User) FullName() string {
	if u.FirstName == "" && u.LastName == "" {
		return u.Email
	}
	return u.FirstName + " " + u.LastName
}

// Session stores refresh tokens for authenticated users.
type Session struct {
	ID           uuid.UUID `gorm:"type:uuid;primaryKey" json:"id"`
	UserID       uuid.UUID `gorm:"type:uuid;not null;index" json:"userId"`
	RefreshToken string    `gorm:"not null;uniqueIndex" json:"-"`
	ExpiresAt    time.Time `gorm:"not null" json:"expiresAt"`
	CreatedAt    time.Time `json:"createdAt"`

	User User `gorm:"foreignKey:UserID" json:"-"`
}
