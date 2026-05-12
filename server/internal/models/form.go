package models

import (
	"github.com/google/uuid"
	"gorm.io/datatypes"
)

// FormDefinition is the schema of a form used in flow nodes.
type FormDefinition struct {
	BaseModel
	CompanyID   uuid.UUID      `gorm:"type:uuid;not null;index" json:"company_id"`
	Name        string         `gorm:"not null" json:"name"`
	Description string         `json:"description"`
	// Fields is a JSON array of FormField objects.
	Fields      datatypes.JSON `gorm:"type:jsonb" json:"fields"`
}

// FormSubmission stores a user's filled-in form data for a specific flow step.
type FormSubmission struct {
	BaseModel
	FlowInstanceID uuid.UUID      `gorm:"type:uuid;not null;index" json:"flow_instance_id"`
	FlowNodeID     uuid.UUID      `gorm:"type:uuid;not null" json:"flow_node_id"`
	SubmittedByID  uuid.UUID      `gorm:"type:uuid;not null" json:"submitted_by_id"`
	// Data is the raw JSON submitted by the user.
	Data           datatypes.JSON `gorm:"type:jsonb" json:"data"`

	SubmittedBy *User `gorm:"foreignKey:SubmittedByID" json:"submitted_by,omitempty"`
}
