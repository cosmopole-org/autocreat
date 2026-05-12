package service

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/autocreat/server/internal/dto"
	"github.com/autocreat/server/internal/models"
	"github.com/autocreat/server/internal/repository"
	"github.com/google/uuid"
	"gorm.io/datatypes"
)

type FormService struct {
	repo *repository.FormRepository
}

func NewFormService(repo *repository.FormRepository) *FormService {
	return &FormService{repo: repo}
}

func (s *FormService) Create(ctx context.Context, companyID uuid.UUID, req dto.CreateFormRequest) (*models.FormDefinition, error) {
	fields, err := json.Marshal(req.Fields)
	if err != nil {
		return nil, fmt.Errorf("marshal fields: %w", err)
	}
	form := &models.FormDefinition{
		CompanyID:   companyID,
		Name:        req.Name,
		Description: req.Description,
		Fields:      datatypes.JSON(fields),
	}
	if err := s.repo.Create(ctx, form); err != nil {
		return nil, err
	}
	return form, nil
}

func (s *FormService) List(ctx context.Context, companyID uuid.UUID) ([]models.FormDefinition, error) {
	return s.repo.FindByCompany(ctx, companyID)
}

func (s *FormService) GetByID(ctx context.Context, id uuid.UUID) (*models.FormDefinition, error) {
	return s.repo.FindByID(ctx, id)
}

func (s *FormService) Update(ctx context.Context, id uuid.UUID, req dto.UpdateFormRequest) (*models.FormDefinition, error) {
	form, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if req.Name != "" {
		form.Name = req.Name
	}
	if req.Description != "" {
		form.Description = req.Description
	}
	if req.Fields != nil {
		fields, err := json.Marshal(req.Fields)
		if err != nil {
			return nil, fmt.Errorf("marshal fields: %w", err)
		}
		form.Fields = datatypes.JSON(fields)
	}
	return form, s.repo.Update(ctx, form)
}

func (s *FormService) Delete(ctx context.Context, id uuid.UUID) error {
	return s.repo.Delete(ctx, id)
}
