package dto

import (
	"encoding/json"
	"time"

	"github.com/autocreat/server/internal/models"
	"github.com/google/uuid"
)

// ---------- Flow ----------

type CreateFlowRequest struct {
	Name        string `json:"name"        binding:"required"`
	Description string `json:"description"`
	IsActive    bool   `json:"is_active"`
}

type UpdateFlowRequest struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	IsActive    *bool  `json:"is_active"`
}

// ---------- FlowNode ----------

type CreateNodeRequest struct {
	NodeType       models.NodeType `json:"node_type"        binding:"required"`
	Name           string          `json:"name"             binding:"required"`
	PositionX      float64         `json:"position_x"`
	PositionY      float64         `json:"position_y"`
	AssignedRoleID *uuid.UUID      `json:"assigned_role_id"`
	AssignedFormID *uuid.UUID      `json:"assigned_form_id"`
	Properties     json.RawMessage `json:"properties"`
}

type UpdateNodeRequest struct {
	Name           string          `json:"name"`
	PositionX      *float64        `json:"position_x"`
	PositionY      *float64        `json:"position_y"`
	AssignedRoleID *uuid.UUID      `json:"assigned_role_id"`
	AssignedFormID *uuid.UUID      `json:"assigned_form_id"`
	Properties     json.RawMessage `json:"properties"`
}

// ---------- FlowEdge ----------

type CreateEdgeRequest struct {
	SourceNodeID uuid.UUID       `json:"source_node_id" binding:"required"`
	TargetNodeID uuid.UUID       `json:"target_node_id" binding:"required"`
	Label        string          `json:"label"`
	Condition    json.RawMessage `json:"condition"`
}

// ---------- SaveGraph ----------

type SaveGraphRequest struct {
	Nodes []CreateNodeRequest `json:"nodes"`
	Edges []CreateEdgeRequest `json:"edges"`
}

// ---------- FlowAssignment ----------

type CreateAssignmentRequest struct {
	StartNodeID uuid.UUID `json:"start_node_id" binding:"required"`
	RoleID      uuid.UUID `json:"role_id"       binding:"required"`
	IsActive    bool      `json:"is_active"`
}

// ---------- FlowInstance ----------

type StartFlowRequest struct {
	FlowID uuid.UUID `json:"flow_id" binding:"required"`
}

type AdvanceFlowRequest struct {
	FormData json.RawMessage `json:"form_data"`
}

type RejectFlowRequest struct {
	Comment          string     `json:"comment"`
	RejectToNodeID   *uuid.UUID `json:"reject_to_node_id"`
}

// ---------- Responses ----------

type FlowResponse struct {
	ID          uuid.UUID `json:"id"`
	CompanyID   uuid.UUID `json:"company_id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	IsActive    bool      `json:"is_active"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type FlowInstanceResponse struct {
	ID            uuid.UUID              `json:"id"`
	FlowID        uuid.UUID              `json:"flow_id"`
	CompanyID     uuid.UUID              `json:"company_id"`
	CurrentNodeID *uuid.UUID             `json:"current_node_id"`
	Status        models.InstanceStatus  `json:"status"`
	StartedByID   uuid.UUID              `json:"started_by_id"`
	CreatedAt     time.Time              `json:"created_at"`
	UpdatedAt     time.Time              `json:"updated_at"`
}
