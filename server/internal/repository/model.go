package repository

import (
	"context"

	"github.com/autocreat/server/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ModelRepository struct {
	db *gorm.DB
}

func NewModelRepository(db *gorm.DB) *ModelRepository {
	return &ModelRepository{db: db}
}

func (r *ModelRepository) Create(ctx context.Context, m *models.ModelDefinition) error {
	return r.db.WithContext(ctx).Create(m).Error
}

func (r *ModelRepository) FindByCompany(ctx context.Context, companyID uuid.UUID) ([]models.ModelDefinition, error) {
	var defs []models.ModelDefinition
	if err := r.db.WithContext(ctx).Where("company_id = ?", companyID).Find(&defs).Error; err != nil {
		return nil, err
	}
	return defs, nil
}

func (r *ModelRepository) FindByID(ctx context.Context, id uuid.UUID) (*models.ModelDefinition, error) {
	var def models.ModelDefinition
	if err := r.db.WithContext(ctx).First(&def, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &def, nil
}

func (r *ModelRepository) Update(ctx context.Context, m *models.ModelDefinition) error {
	return r.db.WithContext(ctx).Save(m).Error
}

func (r *ModelRepository) Delete(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&models.ModelDefinition{}, "id = ?", id).Error
}

func (r *ModelRepository) CreateEntity(ctx context.Context, entity *models.ModelEntity) error {
	return r.db.WithContext(ctx).Create(entity).Error
}

func (r *ModelRepository) FindEntitiesByModel(ctx context.Context, modelID uuid.UUID) ([]models.ModelEntity, error) {
	var entities []models.ModelEntity
	if err := r.db.WithContext(ctx).Where("model_definition_id = ?", modelID).Find(&entities).Error; err != nil {
		return nil, err
	}
	return entities, nil
}

func (r *ModelRepository) FindEntityByID(ctx context.Context, id uuid.UUID) (*models.ModelEntity, error) {
	var entity models.ModelEntity
	if err := r.db.WithContext(ctx).First(&entity, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &entity, nil
}

func (r *ModelRepository) UpdateEntity(ctx context.Context, entity *models.ModelEntity) error {
	return r.db.WithContext(ctx).Save(entity).Error
}

func (r *ModelRepository) DeleteEntity(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&models.ModelEntity{}, "id = ?", id).Error
}
