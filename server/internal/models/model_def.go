package models

import (
	"github.com/google/uuid"
	"gorm.io/datatypes"
)

// ModelDefinition is the schema/blueprint of a dynamic data model.
type ModelDefinition struct {
	BaseModel
	CompanyID   uuid.UUID      `gorm:"type:uuid;not null;index" json:"company_id"`
	Name        string         `gorm:"not null" json:"name"`
	Description string         `json:"description"`
	// Fields is a JSON array of ModelField objects.
	Fields      datatypes.JSON `gorm:"type:jsonb" json:"fields"`
}

// ModelEntity is a single record belonging to a ModelDefinition.
type ModelEntity struct {
	BaseModel
	ModelDefinitionID uuid.UUID      `gorm:"type:uuid;not null;index" json:"model_definition_id"`
	CompanyID         uuid.UUID      `gorm:"type:uuid;not null;index" json:"company_id"`
	// Data holds the actual field values as JSON.
	Data              datatypes.JSON `gorm:"type:jsonb" json:"data"`
	CreatedByID       uuid.UUID      `gorm:"type:uuid;not null" json:"created_by_id"`

	CreatedBy *User `gorm:"foreignKey:CreatedByID" json:"created_by,omitempty"`
}
