package repository

import (
	"context"

	"github.com/autocreat/server/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type FlowRepository struct {
	db *gorm.DB
}

func NewFlowRepository(db *gorm.DB) *FlowRepository {
	return &FlowRepository{db: db}
}

// Flow CRUD

func (r *FlowRepository) Create(ctx context.Context, flow *models.Flow) error {
	return r.db.WithContext(ctx).Create(flow).Error
}

func (r *FlowRepository) FindByCompany(ctx context.Context, companyID uuid.UUID) ([]models.Flow, error) {
	var flows []models.Flow
	if err := r.db.WithContext(ctx).Where("company_id = ?", companyID).Find(&flows).Error; err != nil {
		return nil, err
	}
	return flows, nil
}

func (r *FlowRepository) FindByID(ctx context.Context, id uuid.UUID) (*models.Flow, error) {
	var flow models.Flow
	if err := r.db.WithContext(ctx).First(&flow, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &flow, nil
}

// FindByIDWithGraph loads the flow with nodes and edges preloaded.
func (r *FlowRepository) FindByIDWithGraph(ctx context.Context, id uuid.UUID) (*models.Flow, error) {
	var flow models.Flow
	if err := r.db.WithContext(ctx).
		Preload("Nodes").
		Preload("Edges").
		First(&flow, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &flow, nil
}

func (r *FlowRepository) Update(ctx context.Context, flow *models.Flow) error {
	return r.db.WithContext(ctx).Save(flow).Error
}

func (r *FlowRepository) Delete(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&models.Flow{}, "id = ?", id).Error
}

// FlowNode CRUD

func (r *FlowRepository) CreateNode(ctx context.Context, node *models.FlowNode) error {
	return r.db.WithContext(ctx).Create(node).Error
}

func (r *FlowRepository) FindNodesByFlow(ctx context.Context, flowID uuid.UUID) ([]models.FlowNode, error) {
	var nodes []models.FlowNode
	if err := r.db.WithContext(ctx).Where("flow_id = ?", flowID).Find(&nodes).Error; err != nil {
		return nil, err
	}
	return nodes, nil
}

func (r *FlowRepository) FindNodeByID(ctx context.Context, id uuid.UUID) (*models.FlowNode, error) {
	var node models.FlowNode
	if err := r.db.WithContext(ctx).First(&node, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &node, nil
}

func (r *FlowRepository) UpdateNode(ctx context.Context, node *models.FlowNode) error {
	return r.db.WithContext(ctx).Save(node).Error
}

func (r *FlowRepository) DeleteNode(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&models.FlowNode{}, "id = ?", id).Error
}

func (r *FlowRepository) DeleteNodesByFlow(ctx context.Context, flowID uuid.UUID) error {
	return r.db.WithContext(ctx).Where("flow_id = ?", flowID).Delete(&models.FlowNode{}).Error
}

// FlowEdge CRUD

func (r *FlowRepository) CreateEdge(ctx context.Context, edge *models.FlowEdge) error {
	return r.db.WithContext(ctx).Create(edge).Error
}

func (r *FlowRepository) FindEdgesByFlow(ctx context.Context, flowID uuid.UUID) ([]models.FlowEdge, error) {
	var edges []models.FlowEdge
	if err := r.db.WithContext(ctx).Where("flow_id = ?", flowID).Find(&edges).Error; err != nil {
		return nil, err
	}
	return edges, nil
}

func (r *FlowRepository) DeleteEdge(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&models.FlowEdge{}, "id = ?", id).Error
}

func (r *FlowRepository) DeleteEdgesByFlow(ctx context.Context, flowID uuid.UUID) error {
	return r.db.WithContext(ctx).Where("flow_id = ?", flowID).Delete(&models.FlowEdge{}).Error
}

// FlowAssignment CRUD

func (r *FlowRepository) CreateAssignment(ctx context.Context, a *models.FlowAssignment) error {
	return r.db.WithContext(ctx).Create(a).Error
}

func (r *FlowRepository) FindAssignmentsByFlow(ctx context.Context, flowID uuid.UUID) ([]models.FlowAssignment, error) {
	var assignments []models.FlowAssignment
	if err := r.db.WithContext(ctx).Where("flow_id = ?", flowID).Find(&assignments).Error; err != nil {
		return nil, err
	}
	return assignments, nil
}

func (r *FlowRepository) DeleteAssignment(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&models.FlowAssignment{}, "id = ?", id).Error
}

// FlowInstance

func (r *FlowRepository) CreateInstance(ctx context.Context, instance *models.FlowInstance) error {
	return r.db.WithContext(ctx).Create(instance).Error
}

func (r *FlowRepository) FindInstancesByCompany(ctx context.Context, companyID uuid.UUID) ([]models.FlowInstance, error) {
	var instances []models.FlowInstance
	if err := r.db.WithContext(ctx).Where("company_id = ?", companyID).
		Preload("Flow").Find(&instances).Error; err != nil {
		return nil, err
	}
	return instances, nil
}

func (r *FlowRepository) FindInstanceByID(ctx context.Context, id uuid.UUID) (*models.FlowInstance, error) {
	var instance models.FlowInstance
	if err := r.db.WithContext(ctx).Preload("Steps").Preload("Flow").
		First(&instance, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &instance, nil
}

func (r *FlowRepository) UpdateInstance(ctx context.Context, instance *models.FlowInstance) error {
	return r.db.WithContext(ctx).Save(instance).Error
}

func (r *FlowRepository) CreateInstanceStep(ctx context.Context, step *models.FlowInstanceStep) error {
	return r.db.WithContext(ctx).Create(step).Error
}

func (r *FlowRepository) UpdateInstanceStep(ctx context.Context, step *models.FlowInstanceStep) error {
	return r.db.WithContext(ctx).Save(step).Error
}

// FindPendingStepsForRole returns active flow instance steps assigned to the given role.
func (r *FlowRepository) FindPendingStepsForRole(ctx context.Context, companyID, roleID uuid.UUID) ([]models.FlowInstanceStep, error) {
	var steps []models.FlowInstanceStep
	err := r.db.WithContext(ctx).
		Joins("JOIN flow_instances ON flow_instances.id = flow_instance_steps.flow_instance_id").
		Where("flow_instances.company_id = ? AND flow_instances.status = 'ACTIVE' AND flow_instance_steps.assigned_to_role_id = ? AND flow_instance_steps.status = 'PENDING'",
			companyID, roleID).
		Find(&steps).Error
	return steps, err
}

// FindPendingStepsForUser returns active pending steps assigned to the specific user
// or to the user's role (where no specific user is assigned).
func (r *FlowRepository) FindPendingStepsForUser(ctx context.Context, companyID, userID uuid.UUID, roleID *uuid.UUID) ([]models.FlowInstanceStep, error) {
	var steps []models.FlowInstanceStep
	q := r.db.WithContext(ctx).
		Joins("JOIN flow_instances ON flow_instances.id = flow_instance_steps.flow_instance_id").
		Where("flow_instances.company_id = ? AND flow_instances.status = 'ACTIVE' AND flow_instance_steps.status = 'PENDING'", companyID)

	if roleID != nil {
		q = q.Where(
			"(flow_instance_steps.assigned_to_user_id = ? OR (flow_instance_steps.assigned_to_user_id IS NULL AND flow_instance_steps.assigned_to_role_id = ?))",
			userID, *roleID,
		)
	} else {
		q = q.Where("flow_instance_steps.assigned_to_user_id = ?", userID)
	}

	err := q.Find(&steps).Error
	return steps, err
}

// FindUsersByRole returns all active users that have the given roleID.
func (r *FlowRepository) FindUsersByRole(ctx context.Context, roleID uuid.UUID) ([]models.User, error) {
	var users []models.User
	err := r.db.WithContext(ctx).
		Where("role_id = ? AND is_active = true", roleID).
		Find(&users).Error
	return users, err
}

// FindInstanceStepsWithDetails returns all steps for a given instance ordered by creation time.
func (r *FlowRepository) FindInstanceStepsWithDetails(ctx context.Context, instanceID uuid.UUID) ([]models.FlowInstanceStep, error) {
	var steps []models.FlowInstanceStep
	err := r.db.WithContext(ctx).
		Where("flow_instance_id = ?", instanceID).
		Order("created_at ASC").
		Find(&steps).Error
	return steps, err
}

// FindFormByID fetches a form definition by ID.
func (r *FlowRepository) FindFormByID(ctx context.Context, formID uuid.UUID) (*models.FormDefinition, error) {
	var form models.FormDefinition
	if err := r.db.WithContext(ctx).First(&form, "id = ?", formID).Error; err != nil {
		return nil, err
	}
	return &form, nil
}

// FindFormSubmissionByID fetches a form submission by ID.
func (r *FlowRepository) FindFormSubmissionByID(ctx context.Context, id uuid.UUID) (*models.FormSubmission, error) {
	var sub models.FormSubmission
	if err := r.db.WithContext(ctx).First(&sub, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &sub, nil
}

// FindUserByID fetches a user by ID.
func (r *FlowRepository) FindUserByID(ctx context.Context, id uuid.UUID) (*models.User, error) {
	var user models.User
	if err := r.db.WithContext(ctx).First(&user, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

// FindRoleByID fetches a role by ID.
func (r *FlowRepository) FindRoleByID(ctx context.Context, id uuid.UUID) (*models.Role, error) {
	var role models.Role
	if err := r.db.WithContext(ctx).First(&role, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &role, nil
}

// StartableFlowInfo is an intermediate result from FindStartableFlowsByRole.
type StartableFlowInfo struct {
	FlowID          uuid.UUID
	FlowName        string
	FlowDescription string
	StartNodeID     uuid.UUID
	StartNodeLabel  string
	AssignedFormID  *uuid.UUID
}

// FindStartableFlowsByRole returns flows where the given role is either:
//   - assigned to the flow's START node directly (FlowNode.AssignedRoleID), or
//   - granted start permission via an active FlowAssignment.
func (r *FlowRepository) FindStartableFlowsByRole(ctx context.Context, companyID, roleID uuid.UUID) ([]StartableFlowInfo, error) {
	// Collect start_node_ids granted via active FlowAssignment records.
	var assignedNodeIDs []uuid.UUID
	r.db.WithContext(ctx).
		Model(&models.FlowAssignment{}).
		Select("start_node_id").
		Where("role_id = ? AND is_active = ?", roleID, true).
		Scan(&assignedNodeIDs)

	// Find START nodes in flows owned by this company that this role can start.
	var nodes []models.FlowNode
	q := r.db.WithContext(ctx).
		Joins("JOIN flows ON flows.id = flow_nodes.flow_id").
		Where("flows.company_id = ? AND flow_nodes.type = ?", companyID, models.NodeTypeStart)

	if len(assignedNodeIDs) > 0 {
		q = q.Where("flow_nodes.assigned_role_id = ? OR flow_nodes.id IN ?", roleID, assignedNodeIDs)
	} else {
		q = q.Where("flow_nodes.assigned_role_id = ?", roleID)
	}

	if err := q.Find(&nodes).Error; err != nil {
		return nil, err
	}

	result := make([]StartableFlowInfo, 0, len(nodes))
	for _, node := range nodes {
		flow, err := r.FindByID(ctx, node.FlowID)
		if err != nil {
			continue
		}
		result = append(result, StartableFlowInfo{
			FlowID:          flow.ID,
			FlowName:        flow.Name,
			FlowDescription: flow.Description,
			StartNodeID:     node.ID,
			StartNodeLabel:  node.Label,
			AssignedFormID:  node.AssignedFormID,
		})
	}
	return result, nil
}

// FindRoleIDForUser returns the role ID for the given user, or nil if not set.
func (r *FlowRepository) FindRoleIDForUser(ctx context.Context, userID uuid.UUID) *uuid.UUID {
	user, err := r.FindUserByID(ctx, userID)
	if err != nil || user == nil {
		return nil
	}
	return user.RoleID
}

// CountCompletedStepsByUser counts how many COMPLETED steps a user has handled in a company.
func (r *FlowRepository) CountCompletedStepsByUser(ctx context.Context, userID, companyID uuid.UUID) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&models.FlowInstanceStep{}).
		Joins("JOIN flow_instances ON flow_instances.id = flow_instance_steps.flow_instance_id").
		Where("flow_instances.company_id = ? AND flow_instance_steps.assigned_to_user_id = ? AND flow_instance_steps.status = 'COMPLETED'",
			companyID, userID).
		Count(&count).Error
	return count, err
}
