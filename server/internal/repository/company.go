package repository

import (
	"context"

	"github.com/autocreat/server/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type CompanyRepository struct {
	db *gorm.DB
}

func NewCompanyRepository(db *gorm.DB) *CompanyRepository {
	return &CompanyRepository{db: db}
}

func (r *CompanyRepository) Create(ctx context.Context, company *models.Company) error {
	return r.db.WithContext(ctx).Create(company).Error
}

func (r *CompanyRepository) FindByID(ctx context.Context, id uuid.UUID) (*models.Company, error) {
	var company models.Company
	if err := r.db.WithContext(ctx).First(&company, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &company, nil
}

func (r *CompanyRepository) FindAll(ctx context.Context) ([]models.Company, error) {
	var companies []models.Company
	if err := r.db.WithContext(ctx).Find(&companies).Error; err != nil {
		return nil, err
	}
	return companies, nil
}

func (r *CompanyRepository) FindByOwnerID(ctx context.Context, ownerID uuid.UUID) ([]models.Company, error) {
	var companies []models.Company
	if err := r.db.WithContext(ctx).Where("owner_id = ?", ownerID).Find(&companies).Error; err != nil {
		return nil, err
	}
	return companies, nil
}

func (r *CompanyRepository) Update(ctx context.Context, company *models.Company) error {
	return r.db.WithContext(ctx).Save(company).Error
}

func (r *CompanyRepository) Delete(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&models.Company{}, "id = ?", id).Error
}

func (r *CompanyRepository) FindMembers(ctx context.Context, companyID uuid.UUID) ([]models.CompanyMember, error) {
	var members []models.CompanyMember
	if err := r.db.WithContext(ctx).Preload("User").Preload("Role").
		Where("company_id = ?", companyID).Find(&members).Error; err != nil {
		return nil, err
	}
	return members, nil
}

func (r *CompanyRepository) AddMember(ctx context.Context, member *models.CompanyMember) error {
	return r.db.WithContext(ctx).Create(member).Error
}

func (r *CompanyRepository) RemoveMember(ctx context.Context, companyID, userID uuid.UUID) error {
	return r.db.WithContext(ctx).
		Where("company_id = ? AND user_id = ?", companyID, userID).
		Delete(&models.CompanyMember{}).Error
}

func (r *CompanyRepository) IsMember(ctx context.Context, companyID, userID uuid.UUID) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&models.CompanyMember{}).
		Where("company_id = ? AND user_id = ?", companyID, userID).
		Count(&count).Error
	return count > 0, err
}
