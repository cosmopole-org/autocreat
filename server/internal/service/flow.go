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

		// Broadcast flow.assignments_updated to every user that holds a role assigned to a node.
		nodes, nerr := s.repo.FindNodesByFlow(ctx, flowID)
		if nerr == nil {
			// Collect unique role IDs and the node IDs mapped to each role.
			roleNodeMap := make(map[uuid.UUID][]uuid.UUID)
			for _, n := range nodes {
				if n.AssignedRoleID != nil {
					roleNodeMap[*n.AssignedRoleID] = append(roleNodeMap[*n.AssignedRoleID], n.ID)
				}
			}
			for roleID, nodeIDs := range roleNodeMap {
				payload := map[string]interface{}{
					"flowId":    flowID,
					"companyId": flow.CompanyID,
					"roleId":    roleID,
					"nodeIds":   nodeIDs,
				}
				roleUsers, rerr := s.repo.FindUsersByRole(ctx, roleID)
				if rerr == nil {
					for _, u := range roleUsers {
						s.hub.BroadcastToUser(u.ID, "flow.assignments_updated", payload)
					}
				}
			}
		}
	}

	return s.GetByID(ctx, flowID)
}

// ---------- Assignments ----------

func (s *FlowService) CreateAssignment(ctx context.Context, flowID uuid.UUID, req dto.CreateAssignmentRequest) (*models.FlowAssignment, error) {
	a := &models.FlowAssignment{
		FlowID:      flowID,
		StartNodeID: req.StartNodeID,
		RoleID:      req.RoleID,
		IsActive:    true, // always active on creation; use the update/delete endpoint to deactivate
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

// AdvanceInstance marks the current pending step as completed, persists the
// submitted form data, then creates the next pending step with the correct
// role/user assignment. The company-wide broadcast is sent only after the new
// step is committed, so re-fetching clients always see it.
func (s *FlowService) AdvanceInstance(ctx context.Context, instanceID, userID uuid.UUID, req dto.AdvanceFlowRequest) (*models.FlowInstance, error) {
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

	// Persist submitted form data before marking the step complete.
	var submissionID *uuid.UUID
	if len(req.FormData) > 0 {
		var check map[string]interface{}
		if json.Unmarshal(req.FormData, &check) == nil && len(check) > 0 {
			sub := &models.FormSubmission{
				FlowInstanceID: instance.ID,
				FlowNodeID:     *instance.CurrentNodeID,
				SubmittedByID:  userID,
				Data:           string(req.FormData),
			}
			if err := s.repo.CreateFormSubmission(ctx, sub); err == nil {
				submissionID = &sub.ID
			}
		}
	}

	// Mark current pending step as completed.
	now := time.Now()
	for i := range instance.Steps {
		st := &instance.Steps[i]
		if st.NodeID == *instance.CurrentNodeID && st.Status == models.StepStatusPending {
			st.Status = models.StepStatusCompleted
			st.CompletedAt = &now
			st.FormSubmissionID = submissionID
			if err := s.repo.UpdateInstanceStep(ctx, st); err != nil {
				return nil, err
			}
			break
		}
	}

	// No next node — instance is complete.
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

	// Create the next pending step (skip for END nodes).
	if nextNode.Type != models.NodeTypeEnd {
		newStep := &models.FlowInstanceStep{
			FlowInstanceID:   instance.ID,
			NodeID:           *nextNodeID,
			Status:           models.StepStatusPending,
			AssignedToRoleID: nextNode.AssignedRoleID,
		}

		// Specific user takes precedence; fall back to round-robin.
		if req.NextUserID != nil {
			newStep.AssignedToUserID = req.NextUserID
		} else if req.UseRoundRobin && nextNode.AssignedRoleID != nil {
			picked, err := s.pickRoundRobinUser(ctx, *nextNode.AssignedRoleID, instance.CompanyID)
			if err == nil && picked != nil {
				newStep.AssignedToUserID = picked
			}
		}

		if err := s.repo.CreateInstanceStep(ctx, newStep); err != nil {
			return nil, err
		}

		// Notify assigned user, or all users with the target role.
		taskPayload := map[string]interface{}{
			"instanceId": instance.ID,
			"stepId":     newStep.ID,
			"nodeId":     *nextNodeID,
			"flowId":     instance.FlowID,
			"companyId":  instance.CompanyID,
		}
		if newStep.AssignedToUserID != nil {
			s.hub.BroadcastToUser(*newStep.AssignedToUserID, "task.assigned", taskPayload)
		} else if nextNode.AssignedRoleID != nil {
			roleUsers, err := s.repo.FindUsersByRole(ctx, *nextNode.AssignedRoleID)
			if err == nil {
				for _, u := range roleUsers {
					s.hub.BroadcastToUser(u.ID, "task.assigned", taskPayload)
				}
			}
		}
	}

	// Broadcast after the new step is committed so clients see it immediately.
	s.hub.BroadcastToCompany(instance.CompanyID, "flow.instance_advanced", instance)

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
		if err := s.repo.CreateInstanceStep(ctx, newStep); err != nil {
			return nil, err
		}
		// Notify users of the rejection-target node's role.
		if node.AssignedRoleID != nil {
			taskPayload := map[string]interface{}{
				"instanceId": instance.ID,
				"stepId":     newStep.ID,
				"nodeId":     *req.RejectToNodeID,
				"flowId":     instance.FlowID,
				"companyId":  instance.CompanyID,
			}
			roleUsers, err := s.repo.FindUsersByRole(ctx, *node.AssignedRoleID)
			if err == nil {
				for _, u := range roleUsers {
					s.hub.BroadcastToUser(u.ID, "task.assigned", taskPayload)
				}
			}
		}
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

// GetMyTasksFull returns enriched task responses for the given user.
func (s *FlowService) GetMyTasksFull(ctx context.Context, companyID, userID uuid.UUID, roleID *uuid.UUID) ([]dto.MyTaskResponse, error) {
	steps, err := s.repo.FindPendingStepsForUser(ctx, companyID, userID, roleID)
	if err != nil {
		return nil, err
	}

	result := make([]dto.MyTaskResponse, 0, len(steps))
	for _, step := range steps {
		task, err := s.buildMyTaskResponse(ctx, companyID, step)
		if err != nil {
			continue
		}
		result = append(result, task)
	}
	return result, nil
}

// GetTaskDetail returns a single enriched task for a given instance and node.
func (s *FlowService) GetTaskDetail(ctx context.Context, companyID uuid.UUID, instanceID, nodeID uuid.UUID) (*dto.MyTaskResponse, error) {
	steps, err := s.repo.FindInstanceStepsWithDetails(ctx, instanceID)
	if err != nil {
		return nil, fmt.Errorf("load steps: %w", err)
	}
	for _, step := range steps {
		if step.NodeID == nodeID && step.Status == models.StepStatusPending {
			task, err := s.buildMyTaskResponse(ctx, companyID, step)
			if err != nil {
				return nil, err
			}
			return &task, nil
		}
	}
	return nil, fmt.Errorf("pending step not found for instance %s node %s", instanceID, nodeID)
}

// GetStartableFlows returns flows that the given role can initiate, with the
// form fields for the start node so the client can render the form immediately.
func (s *FlowService) GetStartableFlows(ctx context.Context, companyID uuid.UUID, roleID *uuid.UUID) ([]dto.StartableFlowResponse, error) {
	if roleID == nil {
		return []dto.StartableFlowResponse{}, nil
	}
	rows, err := s.repo.FindStartableFlowsByRole(ctx, companyID, *roleID)
	if err != nil {
		return nil, err
	}
	result := make([]dto.StartableFlowResponse, 0, len(rows))
	for _, row := range rows {
		r := dto.StartableFlowResponse{
			FlowID:          row.FlowID,
			FlowName:        row.FlowName,
			FlowDescription: row.FlowDescription,
			StartNodeID:     row.StartNodeID,
			StartNodeLabel:  row.StartNodeLabel,
			FormID:          row.AssignedFormID,
			FormName:        "",
			FormFields:      []map[string]interface{}{},
		}
		if row.AssignedFormID != nil {
			form, err := s.repo.FindFormByID(ctx, *row.AssignedFormID)
			if err == nil && form != nil {
				r.FormName = form.Name
				var fields []map[string]interface{}
				if form.Fields != "" && form.Fields != "[]" {
					_ = json.Unmarshal([]byte(form.Fields), &fields)
				}
				if fields != nil {
					r.FormFields = fields
				}
			}
		}
		result = append(result, r)
	}
	return result, nil
}

// GetCurrentUserRoleID looks up a user's current role from the DB.
// Used as a fallback when the JWT claim is missing (e.g. stale token).
func (s *FlowService) GetCurrentUserRoleID(ctx context.Context, userID uuid.UUID) *uuid.UUID {
	return s.repo.FindRoleIDForUser(ctx, userID)
}

// GetUsersForRole returns brief user info for all users with the given role.
func (s *FlowService) GetUsersForRole(ctx context.Context, roleID uuid.UUID) ([]dto.UserBriefResponse, error) {
	users, err := s.repo.FindUsersByRole(ctx, roleID)
	if err != nil {
		return nil, err
	}
	result := make([]dto.UserBriefResponse, len(users))
	for i, u := range users {
		result[i] = userToBrief(u)
	}
	return result, nil
}

// pickRoundRobinUser selects the user with the fewest completed steps in the company from the given role.
// If tied, the user with the lexicographically smallest ID wins.
func (s *FlowService) pickRoundRobinUser(ctx context.Context, roleID, companyID uuid.UUID) (*uuid.UUID, error) {
	users, err := s.repo.FindUsersByRole(ctx, roleID)
	if err != nil || len(users) == 0 {
		return nil, err
	}

	var chosen *models.User
	var chosenCount int64 = -1

	for i := range users {
		u := &users[i]
		count, err := s.repo.CountCompletedStepsByUser(ctx, u.ID, companyID)
		if err != nil {
			count = 0
		}
		if chosenCount == -1 || count < chosenCount ||
			(count == chosenCount && u.ID.String() < chosen.ID.String()) {
			chosen = u
			chosenCount = count
		}
	}

	if chosen == nil {
		return nil, nil
	}
	id := chosen.ID
	return &id, nil
}

// buildMyTaskResponse assembles a full MyTaskResponse for a single pending step.
func (s *FlowService) buildMyTaskResponse(ctx context.Context, companyID uuid.UUID, step models.FlowInstanceStep) (dto.MyTaskResponse, error) {
	task := dto.MyTaskResponse{
		StepID:           step.ID,
		InstanceID:       step.FlowInstanceID,
		NodeID:           step.NodeID,
		AssignedRoleID:   step.AssignedToRoleID,
		AssignedToUserID: step.AssignedToUserID,
		CompanyID:        companyID,
		CreatedAt:        step.CreatedAt,
		PreviousSteps:    []dto.StepHistoryItem{},
		NextNodeRoleUsers: []dto.UserBriefResponse{},
	}

	// Load instance
	instance, err := s.repo.FindInstanceByID(ctx, step.FlowInstanceID)
	if err != nil {
		return task, nil
	}
	task.InstanceCreatedAt = instance.CreatedAt
	task.FlowID = instance.FlowID

	// Load flow
	flow, err := s.repo.FindByIDWithGraph(ctx, instance.FlowID)
	if err == nil && flow != nil {
		task.FlowName = flow.Name
	}

	// Load node info
	node, err := s.repo.FindNodeByID(ctx, step.NodeID)
	if err == nil && node != nil {
		task.NodeLabel = node.Label
		task.NodeDescription = node.Description
		task.FormID = node.AssignedFormID
	}

	// Load role name
	if step.AssignedToRoleID != nil {
		role, err := s.repo.FindRoleByID(ctx, *step.AssignedToRoleID)
		if err == nil && role != nil {
			task.RoleName = role.Name
		}
	}

	// Load form fields
	if task.FormID != nil {
		form, err := s.repo.FindFormByID(ctx, *task.FormID)
		if err == nil && form != nil {
			task.FormName = form.Name
			var fields []map[string]interface{}
			if form.Fields != "" && form.Fields != "[]" {
				_ = json.Unmarshal([]byte(form.Fields), &fields)
			}
			if fields == nil {
				fields = []map[string]interface{}{}
			}
			task.FormFields = fields
		}
	}
	if task.FormFields == nil {
		task.FormFields = []map[string]interface{}{}
	}

	// Load started-by user
	startedBy, err := s.repo.FindUserByID(ctx, instance.StartedByID)
	if err == nil && startedBy != nil {
		brief := userToBrief(*startedBy)
		task.StartedByUser = &brief
	}

	// Load history of all steps for this instance
	allSteps, err := s.repo.FindInstanceStepsWithDetails(ctx, step.FlowInstanceID)
	if err == nil {
		for _, s2 := range allSteps {
			// only include completed/rejected steps (not the current pending step)
			if s2.ID == step.ID {
				continue
			}
			if s2.Status != models.StepStatusCompleted && s2.Status != models.StepStatusRejected {
				continue
			}
			histItem := dto.StepHistoryItem{
				StepID:      s2.ID,
				NodeID:      s2.NodeID,
				Status:      string(s2.Status),
				CompletedAt: s2.CompletedAt,
				RejectedAt:  s2.RejectedAt,
				Comment:     s2.RejectionComment,
				FormFields:  []map[string]interface{}{},
				FormData:    map[string]interface{}{},
			}

			// Node label/type for history
			histNode, err := s.repo.FindNodeByID(ctx, s2.NodeID)
			if err == nil && histNode != nil {
				histItem.NodeLabel = histNode.Label
				histItem.NodeType = string(histNode.Type)
			}

			// Role name for history step
			if s2.AssignedToRoleID != nil {
				role, err := s.repo.FindRoleByID(ctx, *s2.AssignedToRoleID)
				if err == nil && role != nil {
					histItem.RoleName = role.Name
				}
			}

			// Form submission data
			if s2.FormSubmissionID != nil {
				sub, err := s.repo.FindFormSubmissionByID(ctx, *s2.FormSubmissionID)
				if err == nil && sub != nil {
					var formData map[string]interface{}
					if sub.Data != "" && sub.Data != "{}" {
						_ = json.Unmarshal([]byte(sub.Data), &formData)
					}
					if formData != nil {
						histItem.FormData = formData
					}

					// Filled-by user
					filledBy, err := s.repo.FindUserByID(ctx, sub.SubmittedByID)
					if err == nil && filledBy != nil {
						brief := userToBrief(*filledBy)
						histItem.FilledByUser = &brief
					}
				}
			}

			// Form fields for history node
			if histNode != nil && histNode.AssignedFormID != nil {
				form, err := s.repo.FindFormByID(ctx, *histNode.AssignedFormID)
				if err == nil && form != nil {
					var fields []map[string]interface{}
					if form.Fields != "" && form.Fields != "[]" {
						_ = json.Unmarshal([]byte(form.Fields), &fields)
					}
					if fields != nil {
						histItem.FormFields = fields
					}
				}
			}

			task.PreviousSteps = append(task.PreviousSteps, histItem)
		}
	}

	// Load users for the next node's role (for assignment dropdown)
	if flow != nil && instance.CurrentNodeID != nil {
		edges, err := s.repo.FindEdgesByFlow(ctx, flow.ID)
		if err == nil {
			for _, e := range edges {
				if e.SourceNodeID == *instance.CurrentNodeID {
					nextNode, err := s.repo.FindNodeByID(ctx, e.TargetNodeID)
					if err == nil && nextNode != nil && nextNode.AssignedRoleID != nil {
						roleUsers, err := s.repo.FindUsersByRole(ctx, *nextNode.AssignedRoleID)
						if err == nil {
							for _, u := range roleUsers {
								task.NextNodeRoleUsers = append(task.NextNodeRoleUsers, userToBrief(u))
							}
						}
					}
					break
				}
			}
		}
	}

	return task, nil
}

// userToBrief converts a models.User to dto.UserBriefResponse.
func userToBrief(u models.User) dto.UserBriefResponse {
	return dto.UserBriefResponse{
		ID:        u.ID,
		FirstName: u.FirstName,
		LastName:  u.LastName,
		Email:     u.Email,
		Avatar:    u.Avatar,
	}
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
