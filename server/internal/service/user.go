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
		FirstName:    req.FirstName,
		LastName:     req.LastName,
		Phone:        req.Phone,
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
	if req.FirstName != "" {
		user.FirstName = req.FirstName
	}
	if req.LastName != "" {
		user.LastName = req.LastName
	}
	if req.Phone != "" {
		user.Phone = req.Phone
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

func (s *UserService) AssignRole(ctx context.Context, userID, roleID uuid.UUID) (*models.User, error) {
	user, err := s.repo.FindByID(ctx, userID)
	if err != nil {
		return nil, err
	}
	user.RoleID = &roleID
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

// ToUserResponse converts a User model to a UserResponse DTO.
func ToUserResponse(u *models.User) dto.UserResponse {
	role := "member"
	if u.IsOwner {
		role = "owner"
	}
	return dto.UserResponse{
		ID:          u.ID,
		Email:       u.Email,
		FirstName:   u.FirstName,
		LastName:    u.LastName,
		Phone:       u.Phone,
		Avatar:      u.Avatar,
		Role:        role,
		IsActive:    u.IsActive,
		CompanyID:   u.CompanyID,
		RoleID:      u.RoleID,
		Permissions: []string{},
		CreatedAt:   u.CreatedAt,
		UpdatedAt:   u.UpdatedAt,
	}
}
