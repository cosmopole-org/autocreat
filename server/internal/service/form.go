package service

import (
	"context"
	"encoding/json"

	"github.com/autocreat/server/internal/dto"
	"github.com/autocreat/server/internal/models"
	"github.com/autocreat/server/internal/repository"
	"github.com/google/uuid"
)

type FormService struct {
	repo *repository.FormRepository
	hub  *Hub
}

func NewFormService(repo *repository.FormRepository, hub *Hub) *FormService {
	return &FormService{repo: repo, hub: hub}
}

func (s *FormService) Create(ctx context.Context, companyID uuid.UUID, req dto.CreateFormRequest) (*dto.FormResponse, error) {
	fieldsJSON, _ := json.Marshal(req.Fields)
	status := req.Status
	if status == "" {
		status = "draft"
	}
	var modelID *uuid.UUID
	if req.ModelID != "" {
		if id, err := uuid.Parse(req.ModelID); err == nil {
			modelID = &id
		}
	}
	form := &models.FormDefinition{
		CompanyID:   companyID,
		ModelID:     modelID,
		Name:        req.Name,
		Description: req.Description,
		Status:      status,
		Fields:      string(fieldsJSON),
	}
	if err := s.repo.Create(ctx, form); err != nil {
		return nil, err
	}
	s.hub.BroadcastToCompany(form.CompanyID, "form.created", form)
	return toFormResponse(form), nil
}

func (s *FormService) List(ctx context.Context, companyID uuid.UUID) ([]dto.FormResponse, error) {
	forms, err := s.repo.FindByCompany(ctx, companyID)
	if err != nil {
		return nil, err
	}
	result := make([]dto.FormResponse, len(forms))
	for i, f := range forms {
		result[i] = *toFormResponse(&f)
	}
	return result, nil
}

func (s *FormService) GetByID(ctx context.Context, id uuid.UUID) (*dto.FormResponse, error) {
	form, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	return toFormResponse(form), nil
}

func (s *FormService) Update(ctx context.Context, id uuid.UUID, req dto.UpdateFormRequest) (*dto.FormResponse, error) {
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
	if req.Status != "" {
		form.Status = req.Status
	}
	if req.ModelID != "" {
		if id, err := uuid.Parse(req.ModelID); err == nil {
			form.ModelID = &id
		}
	}
	if req.Fields != nil {
		fieldsJSON, _ := json.Marshal(req.Fields)
		form.Fields = string(fieldsJSON)
	}
	if err := s.repo.Update(ctx, form); err != nil {
		return nil, err
	}
	s.hub.BroadcastToCompany(form.CompanyID, "form.updated", form)
	return toFormResponse(form), nil
}

func (s *FormService) Delete(ctx context.Context, id uuid.UUID) error {
	form, _ := s.repo.FindByID(ctx, id)
	err := s.repo.Delete(ctx, id)
	if err == nil && form != nil {
		s.hub.BroadcastToCompany(form.CompanyID, "form.deleted", map[string]interface{}{"id": id})
	}
	return err
}

func toFormResponse(f *models.FormDefinition) *dto.FormResponse {
	var fields interface{}
	if f.Fields != "" && f.Fields != "[]" {
		_ = json.Unmarshal([]byte(f.Fields), &fields)
	}
	if fields == nil {
		fields = []interface{}{}
	}
	status := f.Status
	if status == "" {
		status = "draft"
	}
	return &dto.FormResponse{
		ID:          f.ID,
		CompanyID:   f.CompanyID,
		ModelID:     f.ModelID,
		Name:        f.Name,
		Description: f.Description,
		Status:      status,
		Fields:      fields,
		CreatedAt:   f.CreatedAt,
		UpdatedAt:   f.UpdatedAt,
	}
}
