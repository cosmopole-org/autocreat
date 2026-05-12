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
	"gorm.io/datatypes"
)

type LetterService struct {
	repo *repository.LetterRepository
}

func NewLetterService(repo *repository.LetterRepository) *LetterService {
	return &LetterService{repo: repo}
}

func (s *LetterService) Create(ctx context.Context, companyID uuid.UUID, req dto.CreateLetterTemplateRequest) (*models.LetterTemplate, error) {
	t := &models.LetterTemplate{
		CompanyID:   companyID,
		Name:        req.Name,
		Description: req.Description,
		Content:     datatypes.JSON(req.Content),
		Variables:   datatypes.JSON(req.Variables),
	}
	if err := s.repo.Create(ctx, t); err != nil {
		return nil, err
	}
	return t, nil
}

func (s *LetterService) List(ctx context.Context, companyID uuid.UUID) ([]models.LetterTemplate, error) {
	return s.repo.FindByCompany(ctx, companyID)
}

func (s *LetterService) GetByID(ctx context.Context, id uuid.UUID) (*models.LetterTemplate, error) {
	return s.repo.FindByID(ctx, id)
}

func (s *LetterService) Update(ctx context.Context, id uuid.UUID, req dto.UpdateLetterTemplateRequest) (*models.LetterTemplate, error) {
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
	if req.Content != nil {
		t.Content = datatypes.JSON(req.Content)
	}
	if req.Variables != nil {
		t.Variables = datatypes.JSON(req.Variables)
	}
	return t, s.repo.Update(ctx, t)
}

func (s *LetterService) Delete(ctx context.Context, id uuid.UUID) error {
	return s.repo.Delete(ctx, id)
}

// Generate produces a letter by substituting variables in the template's raw text content.
func (s *LetterService) Generate(ctx context.Context, templateID, createdByID uuid.UUID, req dto.GenerateLetterRequest) (*models.GeneratedLetter, error) {
	tmpl, err := s.repo.FindByID(ctx, templateID)
	if err != nil {
		return nil, fmt.Errorf("template not found: %w", err)
	}

	// Build variable map from request data.
	var vars map[string]string
	if err := json.Unmarshal(req.Data, &vars); err != nil {
		return nil, fmt.Errorf("invalid data: %w", err)
	}

	// Simple variable substitution: replace {{KEY}} tokens in the content JSON string.
	contentStr := string(tmpl.Content)
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
		Data:             datatypes.JSON(req.Data),
		GeneratedContent: generated,
		CreatedByID:      createdByID,
	}
	if err := s.repo.CreateGenerated(ctx, g); err != nil {
		return nil, err
	}
	return g, nil
}
