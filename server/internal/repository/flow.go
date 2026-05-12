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
