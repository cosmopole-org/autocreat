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
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

type FlowService struct {
	repo *repository.FlowRepository
	db   *gorm.DB
}

func NewFlowService(repo *repository.FlowRepository, db *gorm.DB) *FlowService {
	return &FlowService{repo: repo, db: db}
}

// ---------- Flow CRUD ----------

func (s *FlowService) Create(ctx context.Context, companyID uuid.UUID, req dto.CreateFlowRequest) (*models.Flow, error) {
	flow := &models.Flow{
		CompanyID:   companyID,
		Name:        req.Name,
		Description: req.Description,
		IsActive:    req.IsActive,
	}
	if err := s.repo.Create(ctx, flow); err != nil {
		return nil, err
	}
	return flow, nil
}

func (s *FlowService) List(ctx context.Context, companyID uuid.UUID) ([]models.Flow, error) {
	return s.repo.FindByCompany(ctx, companyID)
}

func (s *FlowService) GetByID(ctx context.Context, id uuid.UUID) (*models.Flow, error) {
	return s.repo.FindByID(ctx, id)
}

func (s *FlowService) Update(ctx context.Context, id uuid.UUID, req dto.UpdateFlowRequest) (*models.Flow, error) {
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
	if req.IsActive != nil {
		flow.IsActive = *req.IsActive
	}
	return flow, s.repo.Update(ctx, flow)
}

func (s *FlowService) Delete(ctx context.Context, id uuid.UUID) error {
	return s.repo.Delete(ctx, id)
}

// ---------- Nodes ----------

func (s *FlowService) CreateNode(ctx context.Context, flowID uuid.UUID, req dto.CreateNodeRequest) (*models.FlowNode, error) {
	props, _ := json.Marshal(req.Properties)
	node := &models.FlowNode{
		FlowID:         flowID,
		NodeType:       req.NodeType,
		Name:           req.Name,
		PositionX:      req.PositionX,
		PositionY:      req.PositionY,
		AssignedRoleID: req.AssignedRoleID,
		AssignedFormID: req.AssignedFormID,
		Properties:     datatypes.JSON(props),
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
	if req.Name != "" {
		node.Name = req.Name
	}
	if req.PositionX != nil {
		node.PositionX = *req.PositionX
	}
	if req.PositionY != nil {
		node.PositionY = *req.PositionY
	}
	if req.AssignedRoleID != nil {
		node.AssignedRoleID = req.AssignedRoleID
	}
	if req.AssignedFormID != nil {
		node.AssignedFormID = req.AssignedFormID
	}
	if req.Properties != nil {
		props, _ := json.Marshal(req.Properties)
		node.Properties = datatypes.JSON(props)
	}
	return node, s.repo.UpdateNode(ctx, node)
}

func (s *FlowService) DeleteNode(ctx context.Context, nodeID uuid.UUID) error {
	return s.repo.DeleteNode(ctx, nodeID)
}

// ---------- Edges ----------

func (s *FlowService) CreateEdge(ctx context.Context, flowID uuid.UUID, req dto.CreateEdgeRequest) (*models.FlowEdge, error) {
	cond, _ := json.Marshal(req.Condition)
	edge := &models.FlowEdge{
		FlowID:       flowID,
		SourceNodeID: req.SourceNodeID,
		TargetNodeID: req.TargetNodeID,
		Label:        req.Label,
		Condition:    datatypes.JSON(cond),
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

func (s *FlowService) SaveGraph(ctx context.Context, flowID uuid.UUID, req dto.SaveGraphRequest) error {
	return s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Where("flow_id = ?", flowID).Delete(&models.FlowEdge{}).Error; err != nil {
			return err
		}
		if err := tx.Where("flow_id = ?", flowID).Delete(&models.FlowNode{}).Error; err != nil {
			return err
		}
		for _, nr := range req.Nodes {
			props, _ := json.Marshal(nr.Properties)
			node := &models.FlowNode{
				FlowID:         flowID,
				NodeType:       nr.NodeType,
				Name:           nr.Name,
				PositionX:      nr.PositionX,
				PositionY:      nr.PositionY,
				AssignedRoleID: nr.AssignedRoleID,
				AssignedFormID: nr.AssignedFormID,
				Properties:     datatypes.JSON(props),
			}
			if err := tx.Create(node).Error; err != nil {
				return err
			}
		}
		for _, er := range req.Edges {
			cond, _ := json.Marshal(er.Condition)
			edge := &models.FlowEdge{
				FlowID:       flowID,
				SourceNodeID: er.SourceNodeID,
				TargetNodeID: er.TargetNodeID,
				Label:        er.Label,
				Condition:    datatypes.JSON(cond),
			}
			if err := tx.Create(edge).Error; err != nil {
				return err
			}
		}
		return nil
	})
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
		if nodes[i].NodeType == models.NodeTypeStart {
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

	// Mark current step complete.
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
		return instance, s.repo.UpdateInstance(ctx, instance)
	}

	nextNode, err := s.repo.FindNodeByID(ctx, *nextNodeID)
	if err != nil {
		return nil, err
	}

	instance.CurrentNodeID = nextNodeID
	if nextNode.NodeType == models.NodeTypeEnd {
		instance.Status = models.InstanceStatusCompleted
	}
	if err := s.repo.UpdateInstance(ctx, instance); err != nil {
		return nil, err
	}

	if nextNode.NodeType != models.NodeTypeEnd {
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

	return instance, s.repo.UpdateInstance(ctx, instance)
}

func (s *FlowService) GetMyTasks(ctx context.Context, companyID, roleID uuid.UUID) ([]models.FlowInstanceStep, error) {
	return s.repo.FindPendingStepsForRole(ctx, companyID, roleID)
}
