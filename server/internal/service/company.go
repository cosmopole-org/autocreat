package service

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/autocreat/server/internal/dto"
	"github.com/autocreat/server/internal/models"
	"github.com/autocreat/server/internal/repository"
	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
	"gorm.io/datatypes"
)

const companyTTL = 5 * time.Minute

type CompanyService struct {
	repo  *repository.CompanyRepository
	redis *redis.Client
}

func NewCompanyService(repo *repository.CompanyRepository, redis *redis.Client) *CompanyService {
	return &CompanyService{repo: repo, redis: redis}
}

func (s *CompanyService) Create(ctx context.Context, ownerID uuid.UUID, req dto.CreateCompanyRequest) (*models.Company, error) {
	company := &models.Company{
		Name:        req.Name,
		Description: req.Description,
		Logo:        req.Logo,
		OwnerID:     ownerID,
	}
	if err := s.repo.Create(ctx, company); err != nil {
		return nil, fmt.Errorf("create company: %w", err)
	}
	return company, nil
}

func (s *CompanyService) List(ctx context.Context) ([]models.Company, error) {
	return s.repo.FindAll(ctx)
}

func (s *CompanyService) GetByID(ctx context.Context, id uuid.UUID) (*models.Company, error) {
	// Try Redis cache first.
	if s.redis != nil {
		key := fmt.Sprintf("company:%s", id)
		if data, err := s.redis.Get(ctx, key).Bytes(); err == nil {
			var company models.Company
			if json.Unmarshal(data, &company) == nil {
				return &company, nil
			}
		}
	}

	company, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}

	// Cache result.
	if s.redis != nil {
		key := fmt.Sprintf("company:%s", id)
		if data, err := json.Marshal(company); err == nil {
			_ = s.redis.Set(ctx, key, data, companyTTL).Err()
		}
	}

	return company, nil
}

func (s *CompanyService) Update(ctx context.Context, id uuid.UUID, req dto.UpdateCompanyRequest) (*models.Company, error) {
	company, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if req.Name != "" {
		company.Name = req.Name
	}
	if req.Description != "" {
		company.Description = req.Description
	}
	if req.Logo != "" {
		company.Logo = req.Logo
	}
	if err := s.repo.Update(ctx, company); err != nil {
		return nil, err
	}
	s.invalidateCache(ctx, id)
	return company, nil
}

func (s *CompanyService) Delete(ctx context.Context, id uuid.UUID) error {
	if err := s.repo.Delete(ctx, id); err != nil {
		return err
	}
	s.invalidateCache(ctx, id)
	return nil
}

func (s *CompanyService) ListMembers(ctx context.Context, companyID uuid.UUID) ([]models.CompanyMember, error) {
	return s.repo.FindMembers(ctx, companyID)
}

func (s *CompanyService) AddMember(ctx context.Context, companyID uuid.UUID, req dto.AddMemberRequest) error {
	member := &models.CompanyMember{
		CompanyID: companyID,
		UserID:    req.UserID,
		RoleID:    req.RoleID,
		JoinedAt:  time.Now(),
	}
	return s.repo.AddMember(ctx, member)
}

func (s *CompanyService) RemoveMember(ctx context.Context, companyID, userID uuid.UUID) error {
	return s.repo.RemoveMember(ctx, companyID, userID)
}

func (s *CompanyService) invalidateCache(ctx context.Context, id uuid.UUID) {
	if s.redis != nil {
		_ = s.redis.Del(ctx, fmt.Sprintf("company:%s", id)).Err()
	}
}

// ToResponse converts a Company model to a DTO.
func ToCompanyResponse(c *models.Company) dto.CompanyResponse {
	return dto.CompanyResponse{
		ID:          c.ID,
		Name:        c.Name,
		Description: c.Description,
		Logo:        c.Logo,
		OwnerID:     c.OwnerID,
		CreatedAt:   c.CreatedAt,
		UpdatedAt:   c.UpdatedAt,
	}
}

// ToRoleResponse converts a Role model to a DTO.
func ToRoleResponse(r *models.Role) dto.RoleResponse {
	raw, _ := json.Marshal(r.Permissions)
	if r.Permissions != nil {
		raw = datatypes.JSON(r.Permissions)
	}
	return dto.RoleResponse{
		ID:          r.ID,
		CompanyID:   r.CompanyID,
		Name:        r.Name,
		Description: r.Description,
		Color:       r.Color,
		Permissions: raw,
		CreatedAt:   r.CreatedAt,
		UpdatedAt:   r.UpdatedAt,
	}
}
