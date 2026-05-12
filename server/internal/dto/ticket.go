package dto

import (
	"encoding/json"
	"time"

	"github.com/autocreat/server/internal/models"
	"github.com/google/uuid"
)

type CreateTicketRequest struct {
	SubjectTitle   string     `json:"subject_title"    binding:"required"`
	AssignedToID   *uuid.UUID `json:"assigned_to_id"`
	FlowInstanceID *uuid.UUID `json:"flow_instance_id"`
}

type UpdateTicketStatusRequest struct {
	Status models.TicketStatus `json:"status" binding:"required"`
}

type SendTicketMessageRequest struct {
	Content     string          `json:"content"     binding:"required"`
	Attachments json.RawMessage `json:"attachments"`
}

type TicketResponse struct {
	ID             uuid.UUID           `json:"id"`
	CompanyID      uuid.UUID           `json:"company_id"`
	SubjectTitle   string              `json:"subject_title"`
	Status         models.TicketStatus `json:"status"`
	CreatorID      uuid.UUID           `json:"creator_id"`
	AssignedToID   *uuid.UUID          `json:"assigned_to_id"`
	FlowInstanceID *uuid.UUID          `json:"flow_instance_id"`
	CreatedAt      time.Time           `json:"created_at"`
	UpdatedAt      time.Time           `json:"updated_at"`
}

type TicketMessageResponse struct {
	ID          uuid.UUID       `json:"id"`
	TicketID    uuid.UUID       `json:"ticket_id"`
	SenderID    uuid.UUID       `json:"sender_id"`
	Content     string          `json:"content"`
	Attachments json.RawMessage `json:"attachments"`
	CreatedAt   time.Time       `json:"created_at"`
}
