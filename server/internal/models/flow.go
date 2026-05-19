package models

import (
	"time"

	"github.com/google/uuid"
)

// NodeType enumerates the types of nodes in a flow graph.
// Values match Flutter's NodeType enum (lowercase).
type NodeType string

const (
	NodeTypeStart    NodeType = "start"
	NodeTypeStep     NodeType = "step"
	NodeTypeDecision NodeType = "decision"
	NodeTypeEnd      NodeType = "end"
)

// InstanceStatus enumerates the possible states of a running flow instance.
type InstanceStatus string

const (
	InstanceStatusActive    InstanceStatus = "ACTIVE"
	InstanceStatusCompleted InstanceStatus = "COMPLETED"
	InstanceStatusRejected  InstanceStatus = "REJECTED"
	InstanceStatusCancelled InstanceStatus = "CANCELLED"
)

// StepStatus enumerates the states of a single step within a flow instance.
type StepStatus string

const (
	StepStatusPending   StepStatus = "PENDING"
	StepStatusCompleted StepStatus = "COMPLETED"
	StepStatusRejected  StepStatus = "REJECTED"
)

// Flow is the template/definition of a business process.
type Flow struct {
	BaseModel
	CompanyID   uuid.UUID  `gorm:"type:uuid;not null;index" json:"companyId"`
	Name        string     `gorm:"not null" json:"name"`
	Description string     `json:"description"`
	Status      string     `gorm:"not null;default:'draft'" json:"status"`
	Settings    string     `gorm:"type:jsonb;default:'{}'" json:"settings"`

	Nodes       []FlowNode       `gorm:"foreignKey:FlowID" json:"nodes,omitempty"`
	Edges       []FlowEdge       `gorm:"foreignKey:FlowID" json:"edges,omitempty"`
	Assignments []FlowAssignment `gorm:"foreignKey:FlowID" json:"-"`
}

// FlowNode is a single node (step, decision, etc.) in a flow graph.
type FlowNode struct {
	BaseModel
	FlowID         uuid.UUID  `gorm:"type:uuid;not null;index" json:"flowId"`
	Label          string     `gorm:"not null" json:"label"`
	Type           NodeType   `gorm:"not null" json:"type"`
	X              float64    `json:"x"`
	Y              float64    `json:"y"`
	Width          float64    `gorm:"default:160" json:"width"`
	Height         float64    `gorm:"default:60" json:"height"`
	AssignedRoleID *uuid.UUID `gorm:"type:uuid" json:"assignedRoleId"`
	AssignedFormID *uuid.UUID `gorm:"type:uuid" json:"assignedFormId"`
	Description    string     `json:"description"`
	Branches       string     `gorm:"type:jsonb;default:'[]'" json:"branches"`
	Metadata       string     `gorm:"type:jsonb;default:'{}'" json:"metadata"`
}

// FlowEdge connects two FlowNodes with an optional condition.
type FlowEdge struct {
	BaseModel
	FlowID       uuid.UUID  `gorm:"type:uuid;not null;index" json:"flowId"`
	SourceNodeID uuid.UUID  `gorm:"type:uuid;not null" json:"sourceNodeId"`
	TargetNodeID uuid.UUID  `gorm:"type:uuid;not null" json:"targetNodeId"`
	Label        string     `json:"label"`
	ConditionID  string     `json:"conditionId"`
}

// FlowAssignment defines which roles can start a particular flow.
type FlowAssignment struct {
	BaseModel
	FlowID      uuid.UUID `gorm:"type:uuid;not null;index" json:"flowId"`
	StartNodeID uuid.UUID `gorm:"type:uuid;not null" json:"startNodeId"`
	RoleID      uuid.UUID `gorm:"type:uuid;not null" json:"roleId"`
	IsActive    bool      `gorm:"default:true" json:"isActive"`
}

// FlowInstance is a running execution of a Flow.
type FlowInstance struct {
	BaseModel
	FlowID        uuid.UUID      `gorm:"type:uuid;not null;index" json:"flowId"`
	CurrentNodeID *uuid.UUID     `gorm:"type:uuid" json:"currentNodeId"`
	Status        InstanceStatus `gorm:"not null;default:'ACTIVE'" json:"status"`
	StartedByID   uuid.UUID      `gorm:"type:uuid;not null" json:"startedById"`
	CompanyID     uuid.UUID      `gorm:"type:uuid;not null;index" json:"companyId"`

	Flow      *Flow              `gorm:"foreignKey:FlowID" json:"flow,omitempty"`
	StartedBy *User              `gorm:"foreignKey:StartedByID" json:"startedBy,omitempty"`
	Steps     []FlowInstanceStep `gorm:"foreignKey:FlowInstanceID" json:"steps,omitempty"`
}

// FlowInstanceStep records the history of each step taken in a flow instance.
type FlowInstanceStep struct {
	BaseModel
	FlowInstanceID    uuid.UUID  `gorm:"type:uuid;not null;index" json:"flowInstanceId"`
	NodeID            uuid.UUID  `gorm:"type:uuid;not null" json:"nodeId"`
	Status            StepStatus `gorm:"not null;default:'PENDING'" json:"status"`
	AssignedToRoleID  *uuid.UUID `gorm:"type:uuid" json:"assignedToRoleId"`
	AssignedToUserID  *uuid.UUID `gorm:"type:uuid" json:"assignedToUserId"`
	FormSubmissionID  *uuid.UUID `gorm:"type:uuid" json:"formSubmissionId"`
	CompletedAt       *time.Time `json:"completedAt"`
	RejectedAt        *time.Time `json:"rejectedAt"`
	RejectionComment  string     `json:"rejectionComment"`
	RejectedToNodeID  *uuid.UUID `gorm:"type:uuid" json:"rejectedToNodeId"`
}
