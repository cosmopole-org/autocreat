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

type ModelService struct {
	repo *repository.ModelRepository
}

func NewModelService(repo *repository.ModelRepository) *ModelService {
	return &ModelService{repo: repo}
}

func (s *ModelService) Create(ctx context.Context, companyID uuid.UUID, req dto.CreateModelRequest) (*models.ModelDefinition, error) {
	fields, err := json.Marshal(req.Fields)
	if err != nil {
		return nil, fmt.Errorf("marshal fields: %w", err)
	}
	m := &models.ModelDefinition{
		CompanyID:   companyID,
		Name:        req.Name,
		Description: req.Description,
		Fields:      datatypes.JSON(fields),
	}
	if err := s.repo.Create(ctx, m); err != nil {
		return nil, err
	}
	return m, nil
}

func (s *ModelService) List(ctx context.Context, companyID uuid.UUID) ([]models.ModelDefinition, error) {
	return s.repo.FindByCompany(ctx, companyID)
}

func (s *ModelService) GetByID(ctx context.Context, id uuid.UUID) (*models.ModelDefinition, error) {
	return s.repo.FindByID(ctx, id)
}

func (s *ModelService) Update(ctx context.Context, id uuid.UUID, req dto.UpdateModelRequest) (*models.ModelDefinition, error) {
	m, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if req.Name != "" {
		m.Name = req.Name
	}
	if req.Description != "" {
		m.Description = req.Description
	}
	if req.Fields != nil {
		fields, err := json.Marshal(req.Fields)
		if err != nil {
			return nil, fmt.Errorf("marshal fields: %w", err)
		}
		m.Fields = datatypes.JSON(fields)
	}
	return m, s.repo.Update(ctx, m)
}

func (s *ModelService) Delete(ctx context.Context, id uuid.UUID) error {
	return s.repo.Delete(ctx, id)
}

func (s *ModelService) CreateEntity(ctx context.Context, modelID, companyID, userID uuid.UUID, req dto.CreateEntityRequest) (*models.ModelEntity, error) {
	entity := &models.ModelEntity{
		ModelDefinitionID: modelID,
		CompanyID:         companyID,
		Data:              datatypes.JSON(req.Data),
		CreatedByID:       userID,
	}
	if err := s.repo.CreateEntity(ctx, entity); err != nil {
		return nil, err
	}
	return entity, nil
}

func (s *ModelService) ListEntities(ctx context.Context, modelID uuid.UUID) ([]models.ModelEntity, error) {
	return s.repo.FindEntitiesByModel(ctx, modelID)
}

func (s *ModelService) GetEntity(ctx context.Context, entityID uuid.UUID) (*models.ModelEntity, error) {
	return s.repo.FindEntityByID(ctx, entityID)
}

func (s *ModelService) UpdateEntity(ctx context.Context, entityID uuid.UUID, req dto.UpdateEntityRequest) (*models.ModelEntity, error) {
	entity, err := s.repo.FindEntityByID(ctx, entityID)
	if err != nil {
		return nil, err
	}
	entity.Data = datatypes.JSON(req.Data)
	return entity, s.repo.UpdateEntity(ctx, entity)
}

func (s *ModelService) DeleteEntity(ctx context.Context, entityID uuid.UUID) error {
	return s.repo.DeleteEntity(ctx, entityID)
}
