package service

import (
	"context"
	"fmt"

	"github.com/autocreat/server/internal/dto"
	"github.com/autocreat/server/internal/models"
	"github.com/autocreat/server/internal/repository"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type UserService struct {
	repo *repository.UserRepository
	hub  *Hub
}

func NewUserService(repo *repository.UserRepository, hub *Hub) *UserService {
	return &UserService{repo: repo, hub: hub}
}

func (s *UserService) Create(ctx context.Context, companyID uuid.UUID, req dto.CreateUserRequest) (*models.User, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("hash password: %w", err)
	}
	user := &models.User{
		Email:        req.Email,
		PasswordHash: string(hash),
		FullName:     req.FullName,
		CompanyID:    &companyID,
		RoleID:       req.RoleID,
		Avatar:       req.Avatar,
		IsActive:     true,
	}
	if err := s.repo.Create(ctx, user); err != nil {
		return nil, err
	}
	if user.CompanyID != nil {
		s.hub.BroadcastToCompany(*user.CompanyID, "user.created", ToUserResponse(user))
	}
	return user, nil
}

func (s *UserService) List(ctx context.Context, companyID uuid.UUID) ([]models.User, error) {
	return s.repo.FindByCompany(ctx, companyID)
}

func (s *UserService) GetByID(ctx context.Context, id uuid.UUID) (*models.User, error) {
	return s.repo.FindByID(ctx, id)
}

func (s *UserService) Update(ctx context.Context, id uuid.UUID, req dto.UpdateUserRequest) (*models.User, error) {
	user, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if req.FullName != "" {
		user.FullName = req.FullName
	}
	if req.RoleID != nil {
		user.RoleID = req.RoleID
	}
	if req.Avatar != "" {
		user.Avatar = req.Avatar
	}
	if req.IsActive != nil {
		user.IsActive = *req.IsActive
	}
	if err := s.repo.Update(ctx, user); err != nil {
		return nil, err
	}
	if user.CompanyID != nil {
		s.hub.BroadcastToCompany(*user.CompanyID, "user.updated", ToUserResponse(user))
	}
	return user, nil
}

func (s *UserService) Delete(ctx context.Context, id uuid.UUID) error {
	user, _ := s.repo.FindByID(ctx, id)
	err := s.repo.Delete(ctx, id)
	if err == nil && user != nil && user.CompanyID != nil {
		s.hub.BroadcastToCompany(*user.CompanyID, "user.deleted", map[string]interface{}{"id": id})
	}
	return err
}

func ToUserResponse(u *models.User) dto.UserResponse {
	return dto.UserResponse{
		ID:        u.ID,
		Email:     u.Email,
		FullName:  u.FullName,
		CompanyID: u.CompanyID,
		RoleID:    u.RoleID,
		Avatar:    u.Avatar,
		IsActive:  u.IsActive,
		IsOwner:   u.IsOwner,
		CreatedAt: u.CreatedAt,
	}
}
