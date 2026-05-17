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
	Status      string `json:"status"`
	CompanyID   string `json:"companyId"` // used by flat routes
}

type UpdateFlowRequest struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	Status      string `json:"status"`
}

// ---------- FlowNode (matches Flutter FlowNode model) ----------

// BranchCondition matches Flutter's BranchCondition model.
type BranchCondition struct {
	ID          string `json:"id"`
	Label       string `json:"label"`
	Condition   string `json:"condition"`
	TargetNodeID string `json:"targetNodeId"`
	IsDefault   bool   `json:"isDefault"`
}

// NodeRequest is a flow node as sent from Flutter's FlowNode.toJson.
type NodeRequest struct {
	ID             string            `json:"id"`
	Label          string            `json:"label"   binding:"required"`
	Type           models.NodeType   `json:"type"    binding:"required"`
	X              float64           `json:"x"`
	Y              float64           `json:"y"`
	Width          float64           `json:"width"`
	Height         float64           `json:"height"`
	AssignedRoleID *uuid.UUID        `json:"assignedRoleId"`
	AssignedFormID *uuid.UUID        `json:"assignedFormId"`
	Description    string            `json:"description"`
	Branches       []BranchCondition `json:"branches"`
	Metadata       map[string]interface{} `json:"metadata"`
}

// EdgeRequest is a flow edge as sent from Flutter's FlowEdge.toJson.
type EdgeRequest struct {
	ID           string `json:"id"`
	SourceNodeID string `json:"sourceNodeId" binding:"required"`
	TargetNodeID string `json:"targetNodeId" binding:"required"`
	Label        string `json:"label"`
	ConditionID  string `json:"conditionId"`
}

// ---------- SaveGraph ----------

type SaveGraphRequest struct {
	Nodes []NodeRequest `json:"nodes"`
	Edges []EdgeRequest `json:"edges"`
}

// ---------- Legacy node/edge requests (company-scoped routes) ----------

type CreateNodeRequest struct {
	Label          string            `json:"label"          binding:"required"`
	Type           models.NodeType   `json:"type"           binding:"required"`
	X              float64           `json:"x"`
	Y              float64           `json:"y"`
	Width          float64           `json:"width"`
	Height         float64           `json:"height"`
	AssignedRoleID *uuid.UUID        `json:"assignedRoleId"`
	AssignedFormID *uuid.UUID        `json:"assignedFormId"`
	Description    string            `json:"description"`
	Branches       []BranchCondition `json:"branches"`
}

type UpdateNodeRequest struct {
	Label          string            `json:"label"`
	X              *float64          `json:"x"`
	Y              *float64          `json:"y"`
	Width          *float64          `json:"width"`
	Height         *float64          `json:"height"`
	AssignedRoleID *uuid.UUID        `json:"assignedRoleId"`
	AssignedFormID *uuid.UUID        `json:"assignedFormId"`
	Description    string            `json:"description"`
	Branches       []BranchCondition `json:"branches"`
}

type CreateEdgeRequest struct {
	SourceNodeID uuid.UUID `json:"sourceNodeId" binding:"required"`
	TargetNodeID uuid.UUID `json:"targetNodeId" binding:"required"`
	Label        string    `json:"label"`
	ConditionID  string    `json:"conditionId"`
}

// ---------- FlowAssignment ----------

type CreateAssignmentRequest struct {
	StartNodeID uuid.UUID `json:"startNodeId" binding:"required"`
	RoleID      uuid.UUID `json:"roleId"      binding:"required"`
	IsActive    bool      `json:"isActive"`
}

// ---------- FlowInstance ----------

type StartFlowRequest struct {
	FlowID uuid.UUID `json:"flowId" binding:"required"`
}

type AdvanceFlowRequest struct {
	FormData json.RawMessage `json:"formData"`
}

type RejectFlowRequest struct {
	Comment          string     `json:"comment"`
	RejectToNodeID   *uuid.UUID `json:"rejectToNodeId"`
}

// ---------- Responses ----------

// FlowNodeResponse matches Flutter's FlowNode shape.
type FlowNodeResponse struct {
	ID             uuid.UUID         `json:"id"`
	Label          string            `json:"label"`
	Type           models.NodeType   `json:"type"`
	X              float64           `json:"x"`
	Y              float64           `json:"y"`
	Width          float64           `json:"width"`
	Height         float64           `json:"height"`
	AssignedRoleID *uuid.UUID        `json:"assignedRoleId"`
	AssignedFormID *uuid.UUID        `json:"assignedFormId"`
	Description    string            `json:"description"`
	Branches       []BranchCondition `json:"branches"`
	Metadata       map[string]interface{} `json:"metadata"`
}

// FlowEdgeResponse matches Flutter's FlowEdge shape.
type FlowEdgeResponse struct {
	ID           uuid.UUID `json:"id"`
	SourceNodeID uuid.UUID `json:"sourceNodeId"`
	TargetNodeID uuid.UUID `json:"targetNodeId"`
	Label        string    `json:"label"`
	ConditionID  string    `json:"conditionId"`
}

// FlowResponse embeds nodes and edges to match Flutter's Flow model.
type FlowResponse struct {
	ID          uuid.UUID          `json:"id"`
	CompanyID   uuid.UUID          `json:"companyId"`
	Name        string             `json:"name"`
	Description string             `json:"description"`
	Status      string             `json:"status"`
	Nodes       []FlowNodeResponse `json:"nodes"`
	Edges       []FlowEdgeResponse `json:"edges"`
	Settings    map[string]interface{} `json:"settings"`
	CreatedAt   time.Time          `json:"createdAt"`
	UpdatedAt   time.Time          `json:"updatedAt"`
}

type FlowInstanceResponse struct {
	ID            uuid.UUID              `json:"id"`
	FlowID        uuid.UUID              `json:"flowId"`
	CompanyID     uuid.UUID              `json:"companyId"`
	CurrentNodeID *uuid.UUID             `json:"currentNodeId"`
	Status        models.InstanceStatus  `json:"status"`
	StartedByID   uuid.UUID              `json:"startedById"`
	CreatedAt     time.Time              `json:"createdAt"`
	UpdatedAt     time.Time             `json:"updatedAt"`
}

// NodeFromModel converts a DB FlowNode to a FlowNodeResponse.
func NodeFromModel(n models.FlowNode) FlowNodeResponse {
	var branches []BranchCondition
	if n.Branches != "" && n.Branches != "[]" {
		_ = json.Unmarshal([]byte(n.Branches), &branches)
	}
	if branches == nil {
		branches = []BranchCondition{}
	}
	var metadata map[string]interface{}
	if n.Metadata != "" && n.Metadata != "{}" {
		_ = json.Unmarshal([]byte(n.Metadata), &metadata)
	}
	width := n.Width
	if width == 0 {
		width = 160
	}
	height := n.Height
	if height == 0 {
		height = 60
	}
	return FlowNodeResponse{
		ID:             n.ID,
		Label:          n.Label,
		Type:           n.Type,
		X:              n.X,
		Y:              n.Y,
		Width:          width,
		Height:         height,
		AssignedRoleID: n.AssignedRoleID,
		AssignedFormID: n.AssignedFormID,
		Description:    n.Description,
		Branches:       branches,
		Metadata:       metadata,
	}
}

// EdgeFromModel converts a DB FlowEdge to a FlowEdgeResponse.
func EdgeFromModel(e models.FlowEdge) FlowEdgeResponse {
	return FlowEdgeResponse{
		ID:           e.ID,
		SourceNodeID: e.SourceNodeID,
		TargetNodeID: e.TargetNodeID,
		Label:        e.Label,
		ConditionID:  e.ConditionID,
	}
}
