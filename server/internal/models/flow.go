package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
)

// NodeType enumerates the types of nodes in a flow graph.
type NodeType string

const (
	NodeTypeStart    NodeType = "START"
	NodeTypeStep     NodeType = "STEP"
	NodeTypeDecision NodeType = "DECISION"
	NodeTypeEnd      NodeType = "END"
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
	CompanyID   uuid.UUID `gorm:"type:uuid;not null;index" json:"company_id"`
	Name        string    `gorm:"not null" json:"name"`
	Description string    `json:"description"`
	IsActive    bool      `gorm:"default:true" json:"is_active"`

	Nodes       []FlowNode       `gorm:"foreignKey:FlowID" json:"nodes,omitempty"`
	Edges       []FlowEdge       `gorm:"foreignKey:FlowID" json:"edges,omitempty"`
	Assignments []FlowAssignment `gorm:"foreignKey:FlowID" json:"assignments,omitempty"`
}

// FlowNode is a single node (step, decision, etc.) in a flow graph.
type FlowNode struct {
	BaseModel
	FlowID         uuid.UUID      `gorm:"type:uuid;not null;index" json:"flow_id"`
	NodeType       NodeType       `gorm:"not null" json:"node_type"`
	Name           string         `gorm:"not null" json:"name"`
	PositionX      float64        `json:"position_x"`
	PositionY      float64        `json:"position_y"`
	AssignedRoleID *uuid.UUID     `gorm:"type:uuid" json:"assigned_role_id"`
	AssignedFormID *uuid.UUID     `gorm:"type:uuid" json:"assigned_form_id"`
	Properties     datatypes.JSON `gorm:"type:jsonb" json:"properties"`
}

// FlowEdge connects two FlowNodes with an optional condition.
type FlowEdge struct {
	BaseModel
	FlowID       uuid.UUID      `gorm:"type:uuid;not null;index" json:"flow_id"`
	SourceNodeID uuid.UUID      `gorm:"type:uuid;not null" json:"source_node_id"`
	TargetNodeID uuid.UUID      `gorm:"type:uuid;not null" json:"target_node_id"`
	Label        string         `json:"label"`
	Condition    datatypes.JSON `gorm:"type:jsonb" json:"condition"`
}

// FlowAssignment defines which roles can start a particular flow.
type FlowAssignment struct {
	BaseModel
	FlowID      uuid.UUID `gorm:"type:uuid;not null;index" json:"flow_id"`
	StartNodeID uuid.UUID `gorm:"type:uuid;not null" json:"start_node_id"`
	RoleID      uuid.UUID `gorm:"type:uuid;not null" json:"role_id"`
	IsActive    bool      `gorm:"default:true" json:"is_active"`
}

// FlowInstance is a running execution of a Flow.
type FlowInstance struct {
	BaseModel
	FlowID        uuid.UUID      `gorm:"type:uuid;not null;index" json:"flow_id"`
	CurrentNodeID *uuid.UUID     `gorm:"type:uuid" json:"current_node_id"`
	Status        InstanceStatus `gorm:"not null;default:'ACTIVE'" json:"status"`
	StartedByID   uuid.UUID      `gorm:"type:uuid;not null" json:"started_by_id"`
	CompanyID     uuid.UUID      `gorm:"type:uuid;not null;index" json:"company_id"`

	Flow      *Flow              `gorm:"foreignKey:FlowID" json:"flow,omitempty"`
	StartedBy *User              `gorm:"foreignKey:StartedByID" json:"started_by,omitempty"`
	Steps     []FlowInstanceStep `gorm:"foreignKey:FlowInstanceID" json:"steps,omitempty"`
}

// FlowInstanceStep records the history of each step taken in a flow instance.
type FlowInstanceStep struct {
	BaseModel
	FlowInstanceID   uuid.UUID  `gorm:"type:uuid;not null;index" json:"flow_instance_id"`
	NodeID           uuid.UUID  `gorm:"type:uuid;not null" json:"node_id"`
	Status           StepStatus `gorm:"not null;default:'PENDING'" json:"status"`
	AssignedToRoleID *uuid.UUID `gorm:"type:uuid" json:"assigned_to_role_id"`
	FormSubmissionID *uuid.UUID `gorm:"type:uuid" json:"form_submission_id"`
	CompletedAt      *time.Time `json:"completed_at"`
	RejectedAt       *time.Time `json:"rejected_at"`
	RejectionComment string     `json:"rejection_comment"`
	RejectedToNodeID *uuid.UUID `gorm:"type:uuid" json:"rejected_to_node_id"`
}
