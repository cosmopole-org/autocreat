package models

import (
	"github.com/google/uuid"
)

// FormDefinition is the schema of a form used in flow nodes.
type FormDefinition struct {
	BaseModel
	CompanyID   uuid.UUID  `gorm:"type:uuid;not null;index" json:"companyId"`
	ModelID     *uuid.UUID `gorm:"type:uuid" json:"modelId"`
	Name        string     `gorm:"not null" json:"name"`
	Description string     `json:"description"`
	Status      string     `gorm:"not null;default:'draft'" json:"status"`
	Fields      string     `gorm:"type:jsonb;default:'[]'" json:"fields"`
}

// FormSubmission stores a user's filled-in form data for a specific flow step.
type FormSubmission struct {
	BaseModel
	FlowInstanceID uuid.UUID `gorm:"type:uuid;not null;index" json:"flowInstanceId"`
	FlowNodeID     uuid.UUID `gorm:"type:uuid;not null" json:"flowNodeId"`
	SubmittedByID  uuid.UUID `gorm:"type:uuid;not null" json:"submittedById"`
	Data           string    `gorm:"type:jsonb;default:'{}'" json:"data"`

	SubmittedBy *User `gorm:"foreignKey:SubmittedByID" json:"-"`
}
