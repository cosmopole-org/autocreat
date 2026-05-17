package models

import (
	"github.com/google/uuid"
)

// LetterTemplate is a reusable document template with variable placeholders.
type LetterTemplate struct {
	BaseModel
	CompanyID    uuid.UUID  `gorm:"type:uuid;not null;index" json:"companyId"`
	Name         string     `gorm:"not null" json:"name"`
	Description  string     `json:"description"`
	Content      string     `gorm:"type:text;default:''" json:"content"`
	DeltaContent string     `gorm:"type:jsonb;default:'{}'" json:"deltaContent"`
	Variables    string     `gorm:"type:jsonb;default:'[]'" json:"variables"`
	Status       string     `gorm:"not null;default:'draft'" json:"status"`
	Category     string     `json:"category"`
}

// GeneratedLetter is a concrete letter produced from a template for a flow instance.
type GeneratedLetter struct {
	BaseModel
	TemplateID       uuid.UUID  `gorm:"type:uuid;not null;index" json:"templateId"`
	FlowInstanceID   *uuid.UUID `gorm:"type:uuid" json:"flowInstanceId"`
	Data             string     `gorm:"type:jsonb;default:'{}'" json:"data"`
	GeneratedContent string     `gorm:"type:text" json:"generatedContent"`
	CreatedByID      uuid.UUID  `gorm:"type:uuid;not null" json:"createdById"`

	Template  *LetterTemplate `gorm:"foreignKey:TemplateID" json:"-"`
	CreatedBy *User           `gorm:"foreignKey:CreatedByID" json:"-"`
}
