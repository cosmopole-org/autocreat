package dto

import (
	"time"

	"github.com/google/uuid"
)

// ModelField describes a single field within a model definition.
// Shape matches Flutter's ModelField model.
type ModelField struct {
	ID               string `json:"id"`
	Name             string `json:"name"`
	Type             string `json:"type"`
	Required         bool   `json:"required"`
	Unique           bool   `json:"unique"`
	DefaultValue     interface{} `json:"defaultValue"`
	ReferenceModelID string `json:"referenceModelId"`
	Description      string `json:"description"`
	Order            *int   `json:"order"`
}

type CreateModelRequest struct {
	Name        string       `json:"name"        binding:"required"`
	Description string       `json:"description"`
	Fields      []ModelField `json:"fields"`
	CompanyID   string       `json:"companyId"` // used by flat routes
}

type UpdateModelRequest struct {
	Name        string       `json:"name"`
	Description string       `json:"description"`
	Fields      []ModelField `json:"fields"`
}

type ModelResponse struct {
	ID          uuid.UUID    `json:"id"`
	CompanyID   uuid.UUID    `json:"companyId"`
	Name        string       `json:"name"`
	Description string       `json:"description"`
	Fields      interface{}  `json:"fields"`
	CreatedAt   time.Time    `json:"createdAt"`
	UpdatedAt   time.Time    `json:"updatedAt"`
}

type CreateEntityRequest struct {
	Data interface{} `json:"data" binding:"required"`
}

type UpdateEntityRequest struct {
	Data interface{} `json:"data" binding:"required"`
}

type EntityResponse struct {
	ID                uuid.UUID   `json:"id"`
	ModelDefinitionID uuid.UUID   `json:"modelDefinitionId"`
	CompanyID         uuid.UUID   `json:"companyId"`
	Data              interface{} `json:"data"`
	CreatedByID       uuid.UUID   `json:"createdById"`
	CreatedAt         time.Time   `json:"createdAt"`
	UpdatedAt         time.Time   `json:"updatedAt"`
}
