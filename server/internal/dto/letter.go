package dto

import (
	"time"

	"github.com/google/uuid"
)

type CreateLetterRequest struct {
	Name         string      `json:"name"         binding:"required"`
	Description  string      `json:"description"`
	Content      string      `json:"content"`
	DeltaContent interface{} `json:"deltaContent"`
	Variables    []string    `json:"variables"`
	Status       string      `json:"status"`
	Category     string      `json:"category"`
	CompanyID    string      `json:"companyId"` // used by flat routes
}

type UpdateLetterRequest struct {
	Name         string      `json:"name"`
	Description  string      `json:"description"`
	Content      string      `json:"content"`
	DeltaContent interface{} `json:"deltaContent"`
	Variables    []string    `json:"variables"`
	Status       string      `json:"status"`
	Category     string      `json:"category"`
}

// LetterResponse matches Flutter's LetterTemplate model.
type LetterResponse struct {
	ID           uuid.UUID   `json:"id"`
	CompanyID    uuid.UUID   `json:"companyId"`
	Name         string      `json:"name"`
	Description  string      `json:"description"`
	Content      string      `json:"content"`
	DeltaContent interface{} `json:"deltaContent"`
	Variables    []string    `json:"variables"`
	Status       string      `json:"status"`
	Category     string      `json:"category"`
	CreatedAt    time.Time   `json:"createdAt"`
	UpdatedAt    time.Time   `json:"updatedAt"`
}

type GenerateLetterRequest struct {
	Data           interface{} `json:"data" binding:"required"`
	FlowInstanceID *uuid.UUID  `json:"flowInstanceId"`
}

type GeneratedLetterResponse struct {
	ID               uuid.UUID   `json:"id"`
	TemplateID       uuid.UUID   `json:"templateId"`
	FlowInstanceID   *uuid.UUID  `json:"flowInstanceId"`
	Data             interface{} `json:"data"`
	GeneratedContent string      `json:"generatedContent"`
	CreatedByID      uuid.UUID   `json:"createdById"`
	CreatedAt        time.Time   `json:"createdAt"`
}
