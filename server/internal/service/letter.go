package service

import (
	"context"
	"encoding/json"
	"fmt"
	"regexp"
	"strings"

	"github.com/autocreat/server/internal/dto"
	"github.com/autocreat/server/internal/models"
	"github.com/autocreat/server/internal/repository"
	"github.com/google/uuid"
)

type LetterService struct {
	repo *repository.LetterRepository
}

func NewLetterService(repo *repository.LetterRepository) *LetterService {
	return &LetterService{repo: repo}
}

func (s *LetterService) Create(ctx context.Context, companyID uuid.UUID, req dto.CreateLetterRequest) (*dto.LetterResponse, error) {
	deltaJSON, _ := json.Marshal(req.DeltaContent)
	varsJSON, _ := json.Marshal(req.Variables)
	status := req.Status
	if status == "" {
		status = "draft"
	}
	t := &models.LetterTemplate{
		CompanyID:    companyID,
		Name:         req.Name,
		Description:  req.Description,
		Content:      req.Content,
		DeltaContent: string(deltaJSON),
		Variables:    string(varsJSON),
		Status:       status,
		Category:     req.Category,
	}
	if err := s.repo.Create(ctx, t); err != nil {
		return nil, err
	}
	resp := toLetterResponse(t)
	return &resp, nil
}

func (s *LetterService) List(ctx context.Context, companyID uuid.UUID) ([]dto.LetterResponse, error) {
	templates, err := s.repo.FindByCompany(ctx, companyID)
	if err != nil {
		return nil, err
	}
	result := make([]dto.LetterResponse, len(templates))
	for i, t := range templates {
		result[i] = toLetterResponse(&t)
	}
	return result, nil
}

func (s *LetterService) GetByID(ctx context.Context, id uuid.UUID) (*dto.LetterResponse, error) {
	t, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	resp := toLetterResponse(t)
	return &resp, nil
}

func (s *LetterService) Update(ctx context.Context, id uuid.UUID, req dto.UpdateLetterRequest) (*dto.LetterResponse, error) {
	t, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if req.Name != "" {
		t.Name = req.Name
	}
	if req.Description != "" {
		t.Description = req.Description
	}
	if req.Content != "" {
		t.Content = req.Content
	}
	if req.DeltaContent != nil {
		deltaJSON, _ := json.Marshal(req.DeltaContent)
		t.DeltaContent = string(deltaJSON)
	}
	if req.Variables != nil {
		varsJSON, _ := json.Marshal(req.Variables)
		t.Variables = string(varsJSON)
	}
	if req.Status != "" {
		t.Status = req.Status
	}
	if req.Category != "" {
		t.Category = req.Category
	}
	if err := s.repo.Update(ctx, t); err != nil {
		return nil, err
	}
	resp := toLetterResponse(t)
	return &resp, nil
}

func (s *LetterService) Delete(ctx context.Context, id uuid.UUID) error {
	return s.repo.Delete(ctx, id)
}

func (s *LetterService) Generate(ctx context.Context, templateID, createdByID uuid.UUID, req dto.GenerateLetterRequest) (*models.GeneratedLetter, error) {
	tmpl, err := s.repo.FindByID(ctx, templateID)
	if err != nil {
		return nil, fmt.Errorf("template not found: %w", err)
	}

	dataJSON, _ := json.Marshal(req.Data)
	var vars map[string]string
	_ = json.Unmarshal(dataJSON, &vars)

	contentStr := tmpl.Content
	re := regexp.MustCompile(`\{\{(\w+)\}\}`)
	generated := re.ReplaceAllStringFunc(contentStr, func(match string) string {
		key := strings.Trim(match, "{}")
		if val, ok := vars[key]; ok {
			return val
		}
		return match
	})

	g := &models.GeneratedLetter{
		TemplateID:       templateID,
		FlowInstanceID:   req.FlowInstanceID,
		Data:             string(dataJSON),
		GeneratedContent: generated,
		CreatedByID:      createdByID,
	}
	if err := s.repo.CreateGenerated(ctx, g); err != nil {
		return nil, err
	}
	return g, nil
}

func toLetterResponse(t *models.LetterTemplate) dto.LetterResponse {
	var deltaContent interface{}
	if t.DeltaContent != "" && t.DeltaContent != "{}" {
		_ = json.Unmarshal([]byte(t.DeltaContent), &deltaContent)
	}
	if deltaContent == nil {
		deltaContent = map[string]interface{}{}
	}

	var variables []string
	if t.Variables != "" && t.Variables != "[]" {
		_ = json.Unmarshal([]byte(t.Variables), &variables)
	}
	if variables == nil {
		variables = []string{}
	}

	status := t.Status
	if status == "" {
		status = "draft"
	}

	return dto.LetterResponse{
		ID:           t.ID,
		CompanyID:    t.CompanyID,
		Name:         t.Name,
		Description:  t.Description,
		Content:      t.Content,
		DeltaContent: deltaContent,
		Variables:    variables,
		Status:       status,
		Category:     t.Category,
		CreatedAt:    t.CreatedAt,
		UpdatedAt:    t.UpdatedAt,
	}
}
