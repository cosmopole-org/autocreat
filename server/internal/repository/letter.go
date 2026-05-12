package repository

import (
	"context"

	"github.com/autocreat/server/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type LetterRepository struct {
	db *gorm.DB
}

func NewLetterRepository(db *gorm.DB) *LetterRepository {
	return &LetterRepository{db: db}
}

func (r *LetterRepository) Create(ctx context.Context, t *models.LetterTemplate) error {
	return r.db.WithContext(ctx).Create(t).Error
}

func (r *LetterRepository) FindByCompany(ctx context.Context, companyID uuid.UUID) ([]models.LetterTemplate, error) {
	var templates []models.LetterTemplate
	if err := r.db.WithContext(ctx).Where("company_id = ?", companyID).Find(&templates).Error; err != nil {
		return nil, err
	}
	return templates, nil
}

func (r *LetterRepository) FindByID(ctx context.Context, id uuid.UUID) (*models.LetterTemplate, error) {
	var t models.LetterTemplate
	if err := r.db.WithContext(ctx).First(&t, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &t, nil
}

func (r *LetterRepository) Update(ctx context.Context, t *models.LetterTemplate) error {
	return r.db.WithContext(ctx).Save(t).Error
}

func (r *LetterRepository) Delete(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&models.LetterTemplate{}, "id = ?", id).Error
}

func (r *LetterRepository) CreateGenerated(ctx context.Context, g *models.GeneratedLetter) error {
	return r.db.WithContext(ctx).Create(g).Error
}
