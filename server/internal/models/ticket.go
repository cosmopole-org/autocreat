package models

import (
	"time"

	"github.com/google/uuid"
)

// TicketStatus enumerates the lifecycle states of a ticket.
type TicketStatus string

const (
	TicketStatusOpen       TicketStatus = "open"
	TicketStatusInProgress TicketStatus = "inProgress"
	TicketStatusResolved   TicketStatus = "resolved"
	TicketStatusClosed     TicketStatus = "closed"
)

// TicketPriority enumerates ticket urgency levels.
type TicketPriority string

const (
	TicketPriorityLow    TicketPriority = "low"
	TicketPriorityMedium TicketPriority = "medium"
	TicketPriorityHigh   TicketPriority = "high"
	TicketPriorityUrgent TicketPriority = "urgent"
)

// Ticket represents a support or work item within a company.
type Ticket struct {
	BaseModel
	CompanyID   uuid.UUID      `gorm:"type:uuid;not null;index" json:"companyId"`
	Title       string         `gorm:"not null" json:"title"`
	Description string         `gorm:"type:text" json:"description"`
	FlowID      *uuid.UUID     `gorm:"type:uuid" json:"flowId"`
	FlowNodeID  *uuid.UUID     `gorm:"type:uuid" json:"flowNodeId"`
	Status      TicketStatus   `gorm:"not null;default:'open'" json:"status"`
	Priority    TicketPriority `gorm:"not null;default:'medium'" json:"priority"`
	Tags        string         `gorm:"type:jsonb;default:'[]'" json:"tags"`
	CreatorID   uuid.UUID      `gorm:"type:uuid;not null" json:"creatorId"`
	AssigneeID  *uuid.UUID     `gorm:"type:uuid" json:"assigneeId"`
	IsRead      bool           `gorm:"default:false" json:"isRead"`
	DueDate     *time.Time     `json:"dueDate"`
	ResolvedAt  *time.Time     `json:"resolvedAt"`

	Creator  *User           `gorm:"foreignKey:CreatorID" json:"-"`
	Assignee *User           `gorm:"foreignKey:AssigneeID" json:"-"`
	Messages []TicketMessage `gorm:"foreignKey:TicketID" json:"messages,omitempty"`
}

// TicketMessage is a single message within a ticket thread.
type TicketMessage struct {
	BaseModel
	TicketID    uuid.UUID `gorm:"type:uuid;not null;index" json:"ticketId"`
	SenderID    uuid.UUID `gorm:"type:uuid;not null" json:"senderId"`
	Content     string    `gorm:"type:text;not null" json:"content"`
	Attachments string    `gorm:"type:jsonb;default:'[]'" json:"attachments"`
	IsSystem    bool      `gorm:"default:false" json:"isSystem"`

	Sender *User `gorm:"foreignKey:SenderID" json:"-"`
}
