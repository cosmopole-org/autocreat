package dto

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// ModelField describes a single field within a model definition.
type ModelField struct {
	ID           string `json:"id"`
	Name         string `json:"name"`
	Type         string `json:"type"`
	Required     bool   `json:"required"`
	DefaultValue string `json:"default_value,omitempty"`
	Reference    string `json:"reference,omitempty"`
}

type CreateModelRequest struct {
	Name        string       `json:"name"        binding:"required"`
	Description string       `json:"description"`
	Fields      []ModelField `json:"fields"`
}

type UpdateModelRequest struct {
	Name        string       `json:"name"`
	Description string       `json:"description"`
	Fields      []ModelField `json:"fields"`
}

type ModelResponse struct {
	ID          uuid.UUID       `json:"id"`
	CompanyID   uuid.UUID       `json:"company_id"`
	Name        string          `json:"name"`
	Description string          `json:"description"`
	Fields      json.RawMessage `json:"fields"`
	CreatedAt   time.Time       `json:"created_at"`
	UpdatedAt   time.Time       `json:"updated_at"`
}

type CreateEntityRequest struct {
	Data json.RawMessage `json:"data" binding:"required"`
}

type UpdateEntityRequest struct {
	Data json.RawMessage `json:"data" binding:"required"`
}

type EntityResponse struct {
	ID                uuid.UUID       `json:"id"`
	ModelDefinitionID uuid.UUID       `json:"model_definition_id"`
	CompanyID         uuid.UUID       `json:"company_id"`
	Data              json.RawMessage `json:"data"`
	CreatedByID       uuid.UUID       `json:"created_by_id"`
	CreatedAt         time.Time       `json:"created_at"`
	UpdatedAt         time.Time       `json:"updated_at"`
}
