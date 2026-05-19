package repository

import (
	"context"

	"github.com/autocreat/server/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type BindingRepository struct {
	db *gorm.DB
}

func NewBindingRepository(db *gorm.DB) *BindingRepository {
	return &BindingRepository{db: db}
}

// ---------- Form-Model Bindings ----------

func (r *BindingRepository) FindBindingsByNode(ctx context.Context, nodeID uuid.UUID) ([]models.FormModelBinding, error) {
	var bindings []models.FormModelBinding
	err := r.db.WithContext(ctx).
		Preload("Rules").
		Where("flow_node_id = ?", nodeID).
		Find(&bindings).Error
	return bindings, err
}

func (r *BindingRepository) FindBindingByID(ctx context.Context, id uuid.UUID) (*models.FormModelBinding, error) {
	var b models.FormModelBinding
	err := r.db.WithContext(ctx).Preload("Rules").First(&b, "id = ?", id).Error
	if err != nil {
		return nil, err
	}
	return &b, nil
}

// SaveBinding upserts a binding and atomically replaces all its rules.
func (r *BindingRepository) SaveBinding(ctx context.Context, binding *models.FormModelBinding, rules []models.FormModelBindingRule) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if binding.ID == uuid.Nil {
			binding.ID = uuid.New()
		}
		if err := tx.Save(binding).Error; err != nil {
			return err
		}
		// Replace rules atomically.
		if err := tx.Where("binding_id = ?", binding.ID).Delete(&models.FormModelBindingRule{}).Error; err != nil {
			return err
		}
		for i := range rules {
			rules[i].BindingID = binding.ID
			if rules[i].ID == uuid.Nil {
				rules[i].ID = uuid.New()
			}
			if err := tx.Create(&rules[i]).Error; err != nil {
				return err
			}
		}
		return nil
	})
}

func (r *BindingRepository) DeleteBinding(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&models.FormModelBinding{}, "id = ?", id).Error
}

// FindAllBindingsForFlow returns all bindings for every node of a given flow.
// Used during AdvanceInstance to find bindings that store at a specific node.
func (r *BindingRepository) FindAllBindingsForFlow(ctx context.Context, flowID uuid.UUID) ([]models.FormModelBinding, error) {
	var bindings []models.FormModelBinding
	err := r.db.WithContext(ctx).
		Preload("Rules").
		Joins("JOIN flow_nodes ON flow_nodes.id = form_model_bindings.flow_node_id").
		Where("flow_nodes.flow_id = ?", flowID).
		Find(&bindings).Error
	return bindings, err
}

// ---------- Node Letter Assignments ----------

func (r *BindingRepository) FindLetterAssignmentsByNode(ctx context.Context, nodeID uuid.UUID) ([]models.NodeLetterAssignment, error) {
	var assignments []models.NodeLetterAssignment
	err := r.db.WithContext(ctx).
		Where("flow_node_id = ?", nodeID).
		Find(&assignments).Error
	return assignments, err
}

func (r *BindingRepository) FindLetterAssignmentByID(ctx context.Context, id uuid.UUID) (*models.NodeLetterAssignment, error) {
	var a models.NodeLetterAssignment
	err := r.db.WithContext(ctx).First(&a, "id = ?", id).Error
	if err != nil {
		return nil, err
	}
	return &a, nil
}

func (r *BindingRepository) SaveLetterAssignment(ctx context.Context, a *models.NodeLetterAssignment) error {
	if a.ID == uuid.Nil {
		a.ID = uuid.New()
	}
	return r.db.WithContext(ctx).Save(a).Error
}

func (r *BindingRepository) DeleteLetterAssignment(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&models.NodeLetterAssignment{}, "id = ?", id).Error
}

// FindLetterAssignmentsByNode for a flow (all nodes) — used during auto-generation.
func (r *BindingRepository) FindLetterAssignmentsForNode(ctx context.Context, nodeID uuid.UUID) ([]models.NodeLetterAssignment, error) {
	var assignments []models.NodeLetterAssignment
	err := r.db.WithContext(ctx).
		Where("flow_node_id = ? AND auto_generate_on_approve = true", nodeID).
		Find(&assignments).Error
	return assignments, err
}

// ---------- Form Submissions ----------

func (r *BindingRepository) FindFormSubmissionsByInstance(ctx context.Context, instanceID uuid.UUID) ([]models.FormSubmission, error) {
	var subs []models.FormSubmission
	err := r.db.WithContext(ctx).
		Where("flow_instance_id = ?", instanceID).
		Order("created_at ASC").
		Find(&subs).Error
	return subs, err
}

// ---------- Step Generated Letters ----------

func (r *BindingRepository) CreateStepGeneratedLetter(ctx context.Context, g *models.StepGeneratedLetter) error {
	if g.ID == uuid.Nil {
		g.ID = uuid.New()
	}
	return r.db.WithContext(ctx).Create(g).Error
}

func (r *BindingRepository) FindStepGeneratedLetters(ctx context.Context, instanceID, stepID uuid.UUID) ([]models.StepGeneratedLetter, error) {
	var letters []models.StepGeneratedLetter
	err := r.db.WithContext(ctx).
		Where("flow_instance_id = ? AND step_id = ?", instanceID, stepID).
		Order("created_at DESC").
		Find(&letters).Error
	return letters, err
}
