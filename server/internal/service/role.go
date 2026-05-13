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

type RoleService struct {
	repo *repository.RoleRepository
	hub  *Hub
}

func NewRoleService(repo *repository.RoleRepository, hub *Hub) *RoleService {
	return &RoleService{repo: repo, hub: hub}
}

func (s *RoleService) Create(ctx context.Context, companyID uuid.UUID, req dto.CreateRoleRequest) (*models.Role, error) {
	permJSON, err := json.Marshal(req.Permissions)
	if err != nil {
		return nil, fmt.Errorf("marshal permissions: %w", err)
	}
	role := &models.Role{
		CompanyID:   companyID,
		Name:        req.Name,
		Description: req.Description,
		Color:       req.Color,
		Permissions: datatypes.JSON(permJSON),
	}
	if err := s.repo.Create(ctx, role); err != nil {
		return nil, err
	}
	s.hub.BroadcastToCompany(role.CompanyID, "role.created", role)
	return role, nil
}

func (s *RoleService) List(ctx context.Context, companyID uuid.UUID) ([]models.Role, error) {
	return s.repo.FindByCompany(ctx, companyID)
}

func (s *RoleService) GetByID(ctx context.Context, id uuid.UUID) (*models.Role, error) {
	return s.repo.FindByID(ctx, id)
}

func (s *RoleService) Update(ctx context.Context, id uuid.UUID, req dto.UpdateRoleRequest) (*models.Role, error) {
	role, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if req.Name != "" {
		role.Name = req.Name
	}
	if req.Description != "" {
		role.Description = req.Description
	}
	if req.Color != "" {
		role.Color = req.Color
	}
	if req.Permissions != nil {
		permJSON, err := json.Marshal(req.Permissions)
		if err != nil {
			return nil, fmt.Errorf("marshal permissions: %w", err)
		}
		role.Permissions = datatypes.JSON(permJSON)
	}
	if err := s.repo.Update(ctx, role); err != nil {
		return nil, err
	}
	s.hub.BroadcastToCompany(role.CompanyID, "role.updated", role)
	return role, nil
}

func (s *RoleService) Delete(ctx context.Context, id uuid.UUID) error {
	role, _ := s.repo.FindByID(ctx, id)
	err := s.repo.Delete(ctx, id)
	if err == nil && role != nil {
		s.hub.BroadcastToCompany(role.CompanyID, "role.deleted", map[string]interface{}{"id": id})
	}
	return err
}
