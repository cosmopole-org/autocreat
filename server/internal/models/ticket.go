package models

import (
	"github.com/google/uuid"
	"gorm.io/datatypes"
)

// TicketStatus enumerates the lifecycle states of a ticket.
type TicketStatus string

const (
	TicketStatusOpen       TicketStatus = "OPEN"
	TicketStatusInProgress TicketStatus = "IN_PROGRESS"
	TicketStatusClosed     TicketStatus = "CLOSED"
)

// Ticket represents a support or work item within a company.
type Ticket struct {
	BaseModel
	CompanyID      uuid.UUID    `gorm:"type:uuid;not null;index" json:"company_id"`
	SubjectTitle   string       `gorm:"not null" json:"subject_title"`
	Status         TicketStatus `gorm:"not null;default:'OPEN'" json:"status"`
	CreatorID      uuid.UUID    `gorm:"type:uuid;not null" json:"creator_id"`
	AssignedToID   *uuid.UUID   `gorm:"type:uuid" json:"assigned_to_id"`
	FlowInstanceID *uuid.UUID   `gorm:"type:uuid" json:"flow_instance_id"`

	Creator    *User           `gorm:"foreignKey:CreatorID" json:"creator,omitempty"`
	AssignedTo *User           `gorm:"foreignKey:AssignedToID" json:"assigned_to,omitempty"`
	Messages   []TicketMessage `gorm:"foreignKey:TicketID" json:"messages,omitempty"`
}

// TicketMessage is a single message within a ticket thread.
type TicketMessage struct {
	BaseModel
	TicketID    uuid.UUID      `gorm:"type:uuid;not null;index" json:"ticket_id"`
	SenderID    uuid.UUID      `gorm:"type:uuid;not null" json:"sender_id"`
	Content     string         `gorm:"type:text;not null" json:"content"`
	// Attachments is a JSON array of file URLs or metadata.
	Attachments datatypes.JSON `gorm:"type:jsonb" json:"attachments"`

	Sender *User `gorm:"foreignKey:SenderID" json:"sender,omitempty"`
}
