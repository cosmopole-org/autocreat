package models

import (
	"github.com/google/uuid"
	"gorm.io/datatypes"
)

// LetterTemplate is a reusable document template with variable placeholders.
type LetterTemplate struct {
	BaseModel
	CompanyID   uuid.UUID      `gorm:"type:uuid;not null;index" json:"company_id"`
	Name        string         `gorm:"not null" json:"name"`
	Description string         `json:"description"`
	// Content stores the Quill delta JSON.
	Content     datatypes.JSON `gorm:"type:jsonb" json:"content"`
	// Variables is a JSON array of variable names used in the template.
	Variables   datatypes.JSON `gorm:"type:jsonb" json:"variables"`
}

// GeneratedLetter is a concrete letter produced from a template for a flow instance.
type GeneratedLetter struct {
	BaseModel
	TemplateID     uuid.UUID      `gorm:"type:uuid;not null;index" json:"template_id"`
	FlowInstanceID *uuid.UUID     `gorm:"type:uuid" json:"flow_instance_id"`
	// Data holds the variable values used to generate the letter.
	Data             datatypes.JSON `gorm:"type:jsonb" json:"data"`
	GeneratedContent string         `gorm:"type:text" json:"generated_content"`
	CreatedByID      uuid.UUID      `gorm:"type:uuid;not null" json:"created_by_id"`

	Template    *LetterTemplate `gorm:"foreignKey:TemplateID" json:"template,omitempty"`
	CreatedBy   *User           `gorm:"foreignKey:CreatedByID" json:"created_by,omitempty"`
}
