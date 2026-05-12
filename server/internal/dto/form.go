package dto

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// FormField describes a single field within a form definition.
type FormField struct {
	ID              string          `json:"id"`
	Type            string          `json:"type"`
	Label           string          `json:"label"`
	Placeholder     string          `json:"placeholder"`
	Required        bool            `json:"required"`
	ValidationRules json.RawMessage `json:"validation_rules,omitempty"`
	ModelBinding    string          `json:"model_binding,omitempty"`
	Options         json.RawMessage `json:"options,omitempty"`
	Properties      json.RawMessage `json:"properties,omitempty"`
}

type CreateFormRequest struct {
	Name        string      `json:"name"        binding:"required"`
	Description string      `json:"description"`
	Fields      []FormField `json:"fields"`
}

type UpdateFormRequest struct {
	Name        string      `json:"name"`
	Description string      `json:"description"`
	Fields      []FormField `json:"fields"`
}

type FormResponse struct {
	ID          uuid.UUID       `json:"id"`
	CompanyID   uuid.UUID       `json:"company_id"`
	Name        string          `json:"name"`
	Description string          `json:"description"`
	Fields      json.RawMessage `json:"fields"`
	CreatedAt   time.Time       `json:"created_at"`
	UpdatedAt   time.Time       `json:"updated_at"`
}

type SubmitFormRequest struct {
	Data json.RawMessage `json:"data" binding:"required"`
}
