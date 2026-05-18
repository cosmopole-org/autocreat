package service

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/autocreat/server/internal/dto"
	"github.com/autocreat/server/internal/models"
	"github.com/autocreat/server/internal/repository"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type FlowService struct {
	repo *repository.FlowRepository
	db   *gorm.DB
	hub  *Hub
}

func NewFlowService(repo *repository.FlowRepository, db *gorm.DB, hub *Hub) *FlowService {
	return &FlowService{repo: repo, db: db, hub: hub}
}

// ---------- Flow CRUD ----------

func (s *FlowService) Create(ctx context.Context, companyID uuid.UUID, req dto.CreateFlowRequest) (*dto.FlowResponse, error) {
	status := req.Status
	if status == "" {
		status = "draft"
	}
	flow := &models.Flow{
		CompanyID:   companyID,
		Name:        req.Name,
		Description: req.Description,
		Status:      status,
		Settings:    "{}",
	}
	if err := s.repo.Create(ctx, flow); err != nil {
		return nil, err
	}
	if len(req.Nodes) > 0 || len(req.Edges) > 0 {
		if _, err := s.SaveGraph(ctx, flow.ID, dto.SaveGraphRequest{
			Nodes: req.Nodes,
			Edges: req.Edges,
		}); err != nil {
			return nil, err
		}
	}
	s.hub.BroadcastToCompany(flow.CompanyID, "flow.created", map[string]interface{}{"id": flow.ID})
	resp := s.toFlowResponse(ctx, flow)
	return &resp, nil
}

func (s *FlowService) List(ctx context.Context, companyID uuid.UUID) ([]dto.FlowResponse, error) {
	flows, err := s.repo.FindByCompany(ctx, companyID)
	if err != nil {
		return nil, err
	}
	result := make([]dto.FlowResponse, len(flows))
	for i, f := range flows {
		result[i] = s.toFlowResponse(ctx, &f)
	}
	return result, nil
}

func (s *FlowService) GetByID(ctx context.Context, id uuid.UUID) (*dto.FlowResponse, error) {
	flow, err := s.repo.FindByIDWithGraph(ctx, id)
	if err != nil {
		return nil, err
	}
	resp := s.toFlowResponse(ctx, flow)
	return &resp, nil
}

func (s *FlowService) Update(ctx context.Context, id uuid.UUID, req dto.UpdateFlowRequest) (*dto.FlowResponse, error) {
	flow, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if req.Name != "" {
		flow.Name = req.Name
	}
	if req.Description != "" {
		flow.Description = req.Description
	}
	if req.Status != "" {
		flow.Status = req.Status
	}
	if err := s.repo.Update(ctx, flow); err != nil {
		return nil, err
	}
	return s.GetByID(ctx, id)
}

func (s *FlowService) Delete(ctx context.Context, id uuid.UUID) error {
	return s.repo.Delete(ctx, id)
}

// ---------- Nodes ----------

func (s *FlowService) CreateNode(ctx context.Context, flowID uuid.UUID, req dto.CreateNodeRequest) (*models.FlowNode, error) {
	branchJSON, _ := json.Marshal(req.Branches)
	node := &models.FlowNode{
		FlowID:         flowID,
		Label:          req.Label,
		Type:           req.Type,
		X:              req.X,
		Y:              req.Y,
		Width:          req.Width,
		Height:         req.Height,
		AssignedRoleID: req.AssignedRoleID,
		AssignedFormID: req.AssignedFormID,
		Description:    req.Description,
		Branches:       string(branchJSON),
		Metadata:       "{}",
	}
	if node.Width == 0 {
		node.Width = 160
	}
	if node.Height == 0 {
		node.Height = 60
	}
	if err := s.repo.CreateNode(ctx, node); err != nil {
		return nil, err
	}
	return node, nil
}

func (s *FlowService) ListNodes(ctx context.Context, flowID uuid.UUID) ([]models.FlowNode, error) {
	return s.repo.FindNodesByFlow(ctx, flowID)
}

func (s *FlowService) UpdateNode(ctx context.Context, nodeID uuid.UUID, req dto.UpdateNodeRequest) (*models.FlowNode, error) {
	node, err := s.repo.FindNodeByID(ctx, nodeID)
	if err != nil {
		return nil, err
	}
	if req.Label != "" {
		node.Label = req.Label
	}
	if req.X != nil {
		node.X = *req.X
	}
	if req.Y != nil {
		node.Y = *req.Y
	}
	if req.Width != nil {
		node.Width = *req.Width
	}
	if req.Height != nil {
		node.Height = *req.Height
	}
	if req.AssignedRoleID != nil {
		node.AssignedRoleID = req.AssignedRoleID
	}
	if req.AssignedFormID != nil {
		node.AssignedFormID = req.AssignedFormID
	}
	if req.Description != "" {
		node.Description = req.Description
	}
	if req.Branches != nil {
		branchJSON, _ := json.Marshal(req.Branches)
		node.Branches = string(branchJSON)
	}
	return node, s.repo.UpdateNode(ctx, node)
}

func (s *FlowService) DeleteNode(ctx context.Context, nodeID uuid.UUID) error {
	return s.repo.DeleteNode(ctx, nodeID)
}

// ---------- Edges ----------

func (s *FlowService) CreateEdge(ctx context.Context, flowID uuid.UUID, req dto.CreateEdgeRequest) (*models.FlowEdge, error) {
	edge := &models.FlowEdge{
		FlowID:       flowID,
		SourceNodeID: req.SourceNodeID,
		TargetNodeID: req.TargetNodeID,
		Label:        req.Label,
		ConditionID:  req.ConditionID,
	}
	if err := s.repo.CreateEdge(ctx, edge); err != nil {
		return nil, err
	}
	return edge, nil
}

func (s *FlowService) ListEdges(ctx context.Context, flowID uuid.UUID) ([]models.FlowEdge, error) {
	return s.repo.FindEdgesByFlow(ctx, flowID)
}

func (s *FlowService) DeleteEdge(ctx context.Context, edgeID uuid.UUID) error {
	return s.repo.DeleteEdge(ctx, edgeID)
}

// ---------- SaveGraph (atomic replace) ----------

func (s *FlowService) SaveGraph(ctx context.Context, flowID uuid.UUID, req dto.SaveGraphRequest) (*dto.FlowResponse, error) {
	err := s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Where("flow_id = ?", flowID).Delete(&models.FlowEdge{}).Error; err != nil {
			return err
		}
		if err := tx.Where("flow_id = ?", flowID).Delete(&models.FlowNode{}).Error; err != nil {
			return err
		}
		for _, nr := range req.Nodes {
			branchJSON, _ := json.Marshal(nr.Branches)
			metaJSON, _ := json.Marshal(nr.Metadata)
			width := nr.Width
			if width == 0 {
				width = 160
			}
			height := nr.Height
			if height == 0 {
				height = 60
			}
			node := &models.FlowNode{
				FlowID:         flowID,
				Label:          nr.Label,
				Type:           nr.Type,
				X:              nr.X,
				Y:              nr.Y,
				Width:          width,
				Height:         height,
				AssignedRoleID: nr.AssignedRoleID,
				AssignedFormID: nr.AssignedFormID,
				Description:    nr.Description,
				Branches:       string(branchJSON),
				Metadata:       string(metaJSON),
			}
			// Preserve client-supplied ID if it looks like a UUID; otherwise generate.
			if id, err := uuid.Parse(nr.ID); err == nil {
				node.ID = id
			}
			if err := tx.Create(node).Error; err != nil {
				return err
			}
		}
		for _, er := range req.Edges {
			sourceID, err1 := uuid.Parse(er.SourceNodeID)
			targetID, err2 := uuid.Parse(er.TargetNodeID)
			if err1 != nil || err2 != nil {
				continue
			}
			edge := &models.FlowEdge{
				FlowID:       flowID,
				SourceNodeID: sourceID,
				TargetNodeID: targetID,
				Label:        er.Label,
				ConditionID:  er.ConditionID,
			}
			if id, err := uuid.Parse(er.ID); err == nil {
				edge.ID = id
			}
			if err := tx.Create(edge).Error; err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	if flow, ferr := s.repo.FindByID(ctx, flowID); ferr == nil && flow != nil {
		s.hub.BroadcastToCompany(flow.CompanyID, "flow.graph_saved", map[string]interface{}{"flowId": flowID})
	}

	return s.GetByID(ctx, flowID)
}

// ---------- Assignments ----------

func (s *FlowService) CreateAssignment(ctx context.Context, flowID uuid.UUID, req dto.CreateAssignmentRequest) (*models.FlowAssignment, error) {
	a := &models.FlowAssignment{
		FlowID:      flowID,
		StartNodeID: req.StartNodeID,
		RoleID:      req.RoleID,
		IsActive:    req.IsActive,
	}
	if err := s.repo.CreateAssignment(ctx, a); err != nil {
		return nil, err
	}
	return a, nil
}

func (s *FlowService) ListAssignments(ctx context.Context, flowID uuid.UUID) ([]models.FlowAssignment, error) {
	return s.repo.FindAssignmentsByFlow(ctx, flowID)
}

func (s *FlowService) DeleteAssignment(ctx context.Context, id uuid.UUID) error {
	return s.repo.DeleteAssignment(ctx, id)
}

// ---------- Flow Instances ----------

func (s *FlowService) StartInstance(ctx context.Context, companyID, userID uuid.UUID, req dto.StartFlowRequest) (*models.FlowInstance, error) {
	nodes, err := s.repo.FindNodesByFlow(ctx, req.FlowID)
	if err != nil {
		return nil, fmt.Errorf("load nodes: %w", err)
	}

	var startNode *models.FlowNode
	for i := range nodes {
		if nodes[i].Type == models.NodeTypeStart {
			startNode = &nodes[i]
			break
		}
	}
	if startNode == nil {
		return nil, fmt.Errorf("flow has no START node")
	}

	instance := &models.FlowInstance{
		FlowID:        req.FlowID,
		CompanyID:     companyID,
		CurrentNodeID: &startNode.ID,
		Status:        models.InstanceStatusActive,
		StartedByID:   userID,
	}
	if err := s.repo.CreateInstance(ctx, instance); err != nil {
		return nil, err
	}
	s.hub.BroadcastToCompany(instance.CompanyID, "flow.instance_started", instance)

	step := &models.FlowInstanceStep{
		FlowInstanceID:   instance.ID,
		NodeID:           startNode.ID,
		Status:           models.StepStatusPending,
		AssignedToRoleID: startNode.AssignedRoleID,
	}
	return instance, s.repo.CreateInstanceStep(ctx, step)
}

func (s *FlowService) GetInstance(ctx context.Context, id uuid.UUID) (*models.FlowInstance, error) {
	return s.repo.FindInstanceByID(ctx, id)
}

func (s *FlowService) ListInstances(ctx context.Context, companyID uuid.UUID) ([]models.FlowInstance, error) {
	return s.repo.FindInstancesByCompany(ctx, companyID)
}

func (s *FlowService) AdvanceInstance(ctx context.Context, instanceID uuid.UUID, req dto.AdvanceFlowRequest) (*models.FlowInstance, error) {
	instance, err := s.repo.FindInstanceByID(ctx, instanceID)
	if err != nil {
		return nil, err
	}
	if instance.Status != models.InstanceStatusActive {
		return nil, fmt.Errorf("instance is not active")
	}
	if instance.CurrentNodeID == nil {
		return nil, fmt.Errorf("no current node")
	}

	edges, err := s.repo.FindEdgesByFlow(ctx, instance.FlowID)
	if err != nil {
		return nil, err
	}

	var nextNodeID *uuid.UUID
	for _, e := range edges {
		if e.SourceNodeID == *instance.CurrentNodeID {
			id := e.TargetNodeID
			nextNodeID = &id
			break
		}
	}

	now := time.Now()
	for i := range instance.Steps {
		st := &instance.Steps[i]
		if st.NodeID == *instance.CurrentNodeID && st.Status == models.StepStatusPending {
			st.Status = models.StepStatusCompleted
			st.CompletedAt = &now
			if err := s.repo.UpdateInstanceStep(ctx, st); err != nil {
				return nil, err
			}
			break
		}
	}

	if nextNodeID == nil {
		instance.Status = models.InstanceStatusCompleted
		instance.CurrentNodeID = nil
		if err := s.repo.UpdateInstance(ctx, instance); err != nil {
			return nil, err
		}
		s.hub.BroadcastToCompany(instance.CompanyID, "flow.instance_advanced", instance)
		return instance, nil
	}

	nextNode, err := s.repo.FindNodeByID(ctx, *nextNodeID)
	if err != nil {
		return nil, err
	}

	instance.CurrentNodeID = nextNodeID
	if nextNode.Type == models.NodeTypeEnd {
		instance.Status = models.InstanceStatusCompleted
	}
	if err := s.repo.UpdateInstance(ctx, instance); err != nil {
		return nil, err
	}
	s.hub.BroadcastToCompany(instance.CompanyID, "flow.instance_advanced", instance)

	if nextNode.Type != models.NodeTypeEnd {
		newStep := &models.FlowInstanceStep{
			FlowInstanceID:   instance.ID,
			NodeID:           *nextNodeID,
			Status:           models.StepStatusPending,
			AssignedToRoleID: nextNode.AssignedRoleID,
		}
		if err := s.repo.CreateInstanceStep(ctx, newStep); err != nil {
			return nil, err
		}
	}

	return instance, nil
}

func (s *FlowService) RejectInstance(ctx context.Context, instanceID uuid.UUID, req dto.RejectFlowRequest) (*models.FlowInstance, error) {
	instance, err := s.repo.FindInstanceByID(ctx, instanceID)
	if err != nil {
		return nil, err
	}
	if instance.Status != models.InstanceStatusActive {
		return nil, fmt.Errorf("instance is not active")
	}
	if instance.CurrentNodeID == nil {
		return nil, fmt.Errorf("no current node")
	}

	now := time.Now()
	for i := range instance.Steps {
		st := &instance.Steps[i]
		if st.NodeID == *instance.CurrentNodeID && st.Status == models.StepStatusPending {
			st.Status = models.StepStatusRejected
			st.RejectedAt = &now
			st.RejectionComment = req.Comment
			st.RejectedToNodeID = req.RejectToNodeID
			if err := s.repo.UpdateInstanceStep(ctx, st); err != nil {
				return nil, err
			}
			break
		}
	}

	if req.RejectToNodeID != nil {
		instance.CurrentNodeID = req.RejectToNodeID
		node, err := s.repo.FindNodeByID(ctx, *req.RejectToNodeID)
		if err != nil {
			return nil, err
		}
		newStep := &models.FlowInstanceStep{
			FlowInstanceID:   instance.ID,
			NodeID:           *req.RejectToNodeID,
			Status:           models.StepStatusPending,
			AssignedToRoleID: node.AssignedRoleID,
		}
		_ = s.repo.CreateInstanceStep(ctx, newStep)
	} else {
		instance.Status = models.InstanceStatusRejected
	}

	if err := s.repo.UpdateInstance(ctx, instance); err != nil {
		return nil, err
	}
	s.hub.BroadcastToCompany(instance.CompanyID, "flow.instance_rejected", instance)
	return instance, nil
}

func (s *FlowService) GetMyTasks(ctx context.Context, companyID, roleID uuid.UUID) ([]models.FlowInstanceStep, error) {
	return s.repo.FindPendingStepsForRole(ctx, companyID, roleID)
}

// ---------- helpers ----------

func (s *FlowService) toFlowResponse(ctx context.Context, f *models.Flow) dto.FlowResponse {
	nodes, _ := s.repo.FindNodesByFlow(ctx, f.ID)
	edges, _ := s.repo.FindEdgesByFlow(ctx, f.ID)

	nodeResp := make([]dto.FlowNodeResponse, len(nodes))
	for i, n := range nodes {
		nodeResp[i] = dto.NodeFromModel(n)
	}
	edgeResp := make([]dto.FlowEdgeResponse, len(edges))
	for i, e := range edges {
		edgeResp[i] = dto.EdgeFromModel(e)
	}

	var settings map[string]interface{}
	if f.Settings != "" && f.Settings != "{}" {
		_ = json.Unmarshal([]byte(f.Settings), &settings)
	}
	if settings == nil {
		settings = map[string]interface{}{}
	}

	status := f.Status
	if status == "" {
		status = "draft"
	}

	return dto.FlowResponse{
		ID:          f.ID,
		CompanyID:   f.CompanyID,
		Name:        f.Name,
		Description: f.Description,
		Status:      status,
		Nodes:       nodeResp,
		Edges:       edgeResp,
		Settings:    settings,
		CreatedAt:   f.CreatedAt,
		UpdatedAt:   f.UpdatedAt,
	}
}
