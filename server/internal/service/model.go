package service

import (
	"context"
	"encoding/json"

	"github.com/autocreat/server/internal/dto"
	"github.com/autocreat/server/internal/models"
	"github.com/autocreat/server/internal/repository"
	"github.com/google/uuid"
)

type ModelService struct {
	repo *repository.ModelRepository
}

func NewModelService(repo *repository.ModelRepository) *ModelService {
	return &ModelService{repo: repo}
}

func (s *ModelService) Create(ctx context.Context, companyID uuid.UUID, req dto.CreateModelRequest) (*dto.ModelResponse, error) {
	fieldsJSON, _ := json.Marshal(req.Fields)
	m := &models.ModelDefinition{
		CompanyID:   companyID,
		Name:        req.Name,
		Description: req.Description,
		Fields:      string(fieldsJSON),
	}
	if err := s.repo.Create(ctx, m); err != nil {
		return nil, err
	}
	return toModelResponse(m), nil
}

func (s *ModelService) List(ctx context.Context, companyID uuid.UUID) ([]dto.ModelResponse, error) {
	defs, err := s.repo.FindByCompany(ctx, companyID)
	if err != nil {
		return nil, err
	}
	result := make([]dto.ModelResponse, len(defs))
	for i, d := range defs {
		result[i] = *toModelResponse(&d)
	}
	return result, nil
}

func (s *ModelService) GetByID(ctx context.Context, id uuid.UUID) (*dto.ModelResponse, error) {
	m, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	return toModelResponse(m), nil
}

func (s *ModelService) Update(ctx context.Context, id uuid.UUID, req dto.UpdateModelRequest) (*dto.ModelResponse, error) {
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
		fieldsJSON, _ := json.Marshal(req.Fields)
		m.Fields = string(fieldsJSON)
	}
	if err := s.repo.Update(ctx, m); err != nil {
		return nil, err
	}
	return toModelResponse(m), nil
}

func (s *ModelService) Delete(ctx context.Context, id uuid.UUID) error {
	return s.repo.Delete(ctx, id)
}

func (s *ModelService) CreateEntity(ctx context.Context, modelID, companyID, userID uuid.UUID, req dto.CreateEntityRequest) (*dto.EntityResponse, error) {
	dataJSON, _ := json.Marshal(req.Data)
	entity := &models.ModelEntity{
		ModelDefinitionID: modelID,
		CompanyID:         companyID,
		Data:              string(dataJSON),
		CreatedByID:       userID,
	}
	if err := s.repo.CreateEntity(ctx, entity); err != nil {
		return nil, err
	}
	return toEntityResponse(entity), nil
}

func (s *ModelService) ListEntities(ctx context.Context, modelID uuid.UUID) ([]dto.EntityResponse, error) {
	entities, err := s.repo.FindEntitiesByModel(ctx, modelID)
	if err != nil {
		return nil, err
	}
	result := make([]dto.EntityResponse, len(entities))
	for i, e := range entities {
		result[i] = *toEntityResponse(&e)
	}
	return result, nil
}

func (s *ModelService) GetEntity(ctx context.Context, entityID uuid.UUID) (*dto.EntityResponse, error) {
	entity, err := s.repo.FindEntityByID(ctx, entityID)
	if err != nil {
		return nil, err
	}
	return toEntityResponse(entity), nil
}

func (s *ModelService) UpdateEntity(ctx context.Context, entityID uuid.UUID, req dto.UpdateEntityRequest) (*dto.EntityResponse, error) {
	entity, err := s.repo.FindEntityByID(ctx, entityID)
	if err != nil {
		return nil, err
	}
	dataJSON, _ := json.Marshal(req.Data)
	entity.Data = string(dataJSON)
	if err := s.repo.UpdateEntity(ctx, entity); err != nil {
		return nil, err
	}
	return toEntityResponse(entity), nil
}

func (s *ModelService) DeleteEntity(ctx context.Context, entityID uuid.UUID) error {
	return s.repo.DeleteEntity(ctx, entityID)
}

func toModelResponse(m *models.ModelDefinition) *dto.ModelResponse {
	var fields interface{}
	if m.Fields != "" && m.Fields != "[]" {
		_ = json.Unmarshal([]byte(m.Fields), &fields)
	}
	if fields == nil {
		fields = []interface{}{}
	}
	return &dto.ModelResponse{
		ID:          m.ID,
		CompanyID:   m.CompanyID,
		Name:        m.Name,
		Description: m.Description,
		Fields:      fields,
		CreatedAt:   m.CreatedAt,
		UpdatedAt:   m.UpdatedAt,
	}
}

func toEntityResponse(e *models.ModelEntity) *dto.EntityResponse {
	var data interface{}
	if e.Data != "" && e.Data != "{}" {
		_ = json.Unmarshal([]byte(e.Data), &data)
	}
	return &dto.EntityResponse{
		ID:                e.ID,
		ModelDefinitionID: e.ModelDefinitionID,
		CompanyID:         e.CompanyID,
		Data:              data,
		CreatedByID:       e.CreatedByID,
		CreatedAt:         e.CreatedAt,
		UpdatedAt:         e.UpdatedAt,
	}
}
