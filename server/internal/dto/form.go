package dto

import (
	"time"

	"github.com/google/uuid"
)

// FormField describes a single field within a form definition.
// Shape matches Flutter's AppFormField model.
type FormField struct {
	ID                string      `json:"id"`
	Type              string      `json:"type"`
	Label             string      `json:"label"`
	Placeholder       string      `json:"placeholder"`
	HelpText          string      `json:"helpText"`
	Required          bool        `json:"required"`
	ReadOnly          bool        `json:"readOnly"`
	Hidden            bool        `json:"hidden"`
	DefaultValue      interface{} `json:"defaultValue"`
	Options           interface{} `json:"options"`
	Validation        interface{} `json:"validation"`
	ModelFieldBinding string      `json:"modelFieldBinding"`
	Order             *int        `json:"order"`
	Metadata          interface{} `json:"metadata"`
}

type CreateFormRequest struct {
	Name        string      `json:"name"        binding:"required"`
	Description string      `json:"description"`
	ModelID     string      `json:"modelId"`
	Status      string      `json:"status"`
	Fields      []FormField `json:"fields"`
	CompanyID   string      `json:"companyId"` // used by flat routes
}

type UpdateFormRequest struct {
	Name        string      `json:"name"`
	Description string      `json:"description"`
	ModelID     string      `json:"modelId"`
	Status      string      `json:"status"`
	Fields      []FormField `json:"fields"`
}

type FormResponse struct {
	ID          uuid.UUID   `json:"id"`
	CompanyID   uuid.UUID   `json:"companyId"`
	ModelID     *uuid.UUID  `json:"modelId"`
	Name        string      `json:"name"`
	Description string      `json:"description"`
	Status      string      `json:"status"`
	Fields      interface{} `json:"fields"`
	CreatedAt   time.Time   `json:"createdAt"`
	UpdatedAt   time.Time   `json:"updatedAt"`
}
