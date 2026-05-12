package dto

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

type CreateLetterTemplateRequest struct {
	Name        string          `json:"name"        binding:"required"`
	Description string          `json:"description"`
	Content     json.RawMessage `json:"content"`
	Variables   json.RawMessage `json:"variables"`
}

type UpdateLetterTemplateRequest struct {
	Name        string          `json:"name"`
	Description string          `json:"description"`
	Content     json.RawMessage `json:"content"`
	Variables   json.RawMessage `json:"variables"`
}

type LetterTemplateResponse struct {
	ID          uuid.UUID       `json:"id"`
	CompanyID   uuid.UUID       `json:"company_id"`
	Name        string          `json:"name"`
	Description string          `json:"description"`
	Content     json.RawMessage `json:"content"`
	Variables   json.RawMessage `json:"variables"`
	CreatedAt   time.Time       `json:"created_at"`
	UpdatedAt   time.Time       `json:"updated_at"`
}

type GenerateLetterRequest struct {
	Data           json.RawMessage `json:"data"             binding:"required"`
	FlowInstanceID *uuid.UUID      `json:"flow_instance_id"`
}

type GeneratedLetterResponse struct {
	ID               uuid.UUID       `json:"id"`
	TemplateID       uuid.UUID       `json:"template_id"`
	FlowInstanceID   *uuid.UUID      `json:"flow_instance_id"`
	Data             json.RawMessage `json:"data"`
	GeneratedContent string          `json:"generated_content"`
	CreatedByID      uuid.UUID       `json:"created_by_id"`
	CreatedAt        time.Time       `json:"created_at"`
}
