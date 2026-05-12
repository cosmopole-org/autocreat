package repository

import (
	"context"

	"github.com/autocreat/server/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type FormRepository struct {
	db *gorm.DB
}

func NewFormRepository(db *gorm.DB) *FormRepository {
	return &FormRepository{db: db}
}

func (r *FormRepository) Create(ctx context.Context, form *models.FormDefinition) error {
	return r.db.WithContext(ctx).Create(form).Error
}

func (r *FormRepository) FindByCompany(ctx context.Context, companyID uuid.UUID) ([]models.FormDefinition, error) {
	var forms []models.FormDefinition
	if err := r.db.WithContext(ctx).Where("company_id = ?", companyID).Find(&forms).Error; err != nil {
		return nil, err
	}
	return forms, nil
}

func (r *FormRepository) FindByID(ctx context.Context, id uuid.UUID) (*models.FormDefinition, error) {
	var form models.FormDefinition
	if err := r.db.WithContext(ctx).First(&form, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &form, nil
}

func (r *FormRepository) Update(ctx context.Context, form *models.FormDefinition) error {
	return r.db.WithContext(ctx).Save(form).Error
}

func (r *FormRepository) Delete(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&models.FormDefinition{}, "id = ?", id).Error
}

func (r *FormRepository) CreateSubmission(ctx context.Context, sub *models.FormSubmission) error {
	return r.db.WithContext(ctx).Create(sub).Error
}
