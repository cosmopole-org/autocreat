package repository

import (
	"context"
	"time"

	"github.com/autocreat/server/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AuthRepository struct {
	db *gorm.DB
}

func NewAuthRepository(db *gorm.DB) *AuthRepository {
	return &AuthRepository{db: db}
}

func (r *AuthRepository) CreateUser(ctx context.Context, user *models.User) error {
	return r.db.WithContext(ctx).Create(user).Error
}

func (r *AuthRepository) FindUserByEmail(ctx context.Context, email string) (*models.User, error) {
	var user models.User
	if err := r.db.WithContext(ctx).Where("email = ?", email).First(&user).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *AuthRepository) FindUserByID(ctx context.Context, id uuid.UUID) (*models.User, error) {
	var user models.User
	if err := r.db.WithContext(ctx).First(&user, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *AuthRepository) CreateSession(ctx context.Context, session *models.Session) error {
	return r.db.WithContext(ctx).Create(session).Error
}

func (r *AuthRepository) FindSessionByToken(ctx context.Context, token string) (*models.Session, error) {
	var session models.Session
	if err := r.db.WithContext(ctx).Where("refresh_token = ? AND expires_at > ?", token, time.Now()).First(&session).Error; err != nil {
		return nil, err
	}
	return &session, nil
}

func (r *AuthRepository) DeleteSession(ctx context.Context, token string) error {
	return r.db.WithContext(ctx).Where("refresh_token = ?", token).Delete(&models.Session{}).Error
}

func (r *AuthRepository) DeleteSessionsByUserID(ctx context.Context, userID uuid.UUID) error {
	return r.db.WithContext(ctx).Where("user_id = ?", userID).Delete(&models.Session{}).Error
}
