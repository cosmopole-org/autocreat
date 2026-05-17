package models

import (
	"github.com/google/uuid"
)

// ModelDefinition is the schema/blueprint of a dynamic data model.
type ModelDefinition struct {
	BaseModel
	CompanyID   uuid.UUID `gorm:"type:uuid;not null;index" json:"companyId"`
	Name        string    `gorm:"not null" json:"name"`
	Description string    `json:"description"`
	Fields      string    `gorm:"type:jsonb;default:'[]'" json:"fields"`
}

// ModelEntity is a single record belonging to a ModelDefinition.
type ModelEntity struct {
	BaseModel
	ModelDefinitionID uuid.UUID `gorm:"type:uuid;not null;index" json:"modelDefinitionId"`
	CompanyID         uuid.UUID `gorm:"type:uuid;not null;index" json:"companyId"`
	Data              string    `gorm:"type:jsonb;default:'{}'" json:"data"`
	CreatedByID       uuid.UUID `gorm:"type:uuid;not null" json:"createdById"`

	CreatedBy *User `gorm:"foreignKey:CreatedByID" json:"-"`
}
