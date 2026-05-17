package dto

import (
	"time"

	"github.com/autocreat/server/internal/models"
	"github.com/google/uuid"
)

type CreateTicketRequest struct {
	Title       string                `json:"title"       binding:"required"`
	Description string                `json:"description"`
	FlowID      *uuid.UUID            `json:"flowId"`
	FlowNodeID  *uuid.UUID            `json:"flowNodeId"`
	AssigneeID  *uuid.UUID            `json:"assigneeId"`
	Priority    models.TicketPriority `json:"priority"`
	Tags        []string              `json:"tags"`
	DueDate     *time.Time            `json:"dueDate"`
	CompanyID   string                `json:"companyId"` // used by flat routes
}

type UpdateTicketRequest struct {
	Title       string                `json:"title"`
	Description string                `json:"description"`
	AssigneeID  *uuid.UUID            `json:"assigneeId"`
	Priority    models.TicketPriority `json:"priority"`
	Tags        []string              `json:"tags"`
	DueDate     *time.Time            `json:"dueDate"`
	IsRead      *bool                 `json:"isRead"`
}

type UpdateTicketStatusRequest struct {
	Status models.TicketStatus `json:"status" binding:"required"`
}

type SendTicketMessageRequest struct {
	Content     string   `json:"content"     binding:"required"`
	Attachments []string `json:"attachments"`
}

// TicketMessageResponse matches Flutter's TicketMessage model.
type TicketMessageResponse struct {
	ID          uuid.UUID  `json:"id"`
	TicketID    uuid.UUID  `json:"ticketId"`
	SenderID    uuid.UUID  `json:"senderId"`
	SenderName  string     `json:"senderName"`
	SenderAvatar string    `json:"senderAvatar"`
	Content     string     `json:"content"`
	Attachments []string   `json:"attachments"`
	IsSystem    bool       `json:"isSystem"`
	CreatedAt   time.Time  `json:"createdAt"`
}

// TicketResponse matches Flutter's Ticket model.
type TicketResponse struct {
	ID           uuid.UUID              `json:"id"`
	Title        string                 `json:"title"`
	Description  string                 `json:"description"`
	CompanyID    uuid.UUID              `json:"companyId"`
	FlowID       *uuid.UUID             `json:"flowId"`
	FlowNodeID   *uuid.UUID             `json:"flowNodeId"`
	CreatorID    uuid.UUID              `json:"creatorId"`
	CreatorName  string                 `json:"creatorName"`
	AssigneeID   *uuid.UUID             `json:"assigneeId"`
	AssigneeName string                 `json:"assigneeName"`
	Status       models.TicketStatus    `json:"status"`
	Priority     models.TicketPriority  `json:"priority"`
	Tags         []string               `json:"tags"`
	Messages     []TicketMessageResponse `json:"messages"`
	MessageCount int                    `json:"messageCount"`
	IsRead       bool                   `json:"isRead"`
	DueDate      *time.Time             `json:"dueDate"`
	ResolvedAt   *time.Time             `json:"resolvedAt"`
	CreatedAt    time.Time              `json:"createdAt"`
	UpdatedAt    time.Time              `json:"updatedAt"`
}
