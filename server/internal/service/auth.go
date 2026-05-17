package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/autocreat/server/internal/config"
	"github.com/autocreat/server/internal/dto"
	"github.com/autocreat/server/internal/models"
	"github.com/autocreat/server/internal/repository"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// DemoUserID and DemoCompanyID are the well-known identifiers for demo mode.
var (
	DemoUserID    = uuid.MustParse("d0e1f2a3-b4c5-d6e7-f8a9-b0c1d2e3f4a5")
	DemoCompanyID = uuid.MustParse("a1b2c3d4-e5f6-7890-abcd-ef1234567890")
)

// Claims is the JWT payload stored in access tokens.
type Claims struct {
	UserID    uuid.UUID  `json:"user_id"`
	Email     string     `json:"email"`
	CompanyID *uuid.UUID `json:"company_id,omitempty"`
	RoleID    *uuid.UUID `json:"role_id,omitempty"`
	IsDemo    bool       `json:"is_demo,omitempty"`
	jwt.RegisteredClaims
}

type AuthService struct {
	repo *repository.AuthRepository
	cfg  *config.Config
}

func NewAuthService(repo *repository.AuthRepository, cfg *config.Config) *AuthService {
	return &AuthService{repo: repo, cfg: cfg}
}

func (s *AuthService) Register(ctx context.Context, req dto.RegisterRequest) (*dto.AuthResponse, error) {
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
		IsActive:     true,
	}

	companyName := req.CompanyName
	if companyName == "" {
		companyName = req.FirstName + "'s Workspace"
	}
	company := &models.Company{
		Name:   companyName,
		Status: models.CompanyStatusActive,
	}
	role := &models.Role{
		Name:        "Owner",
		Description: "Full administrative access",
		Level:       "admin",
		IsActive:    true,
		Permissions: fullAccessPermissionsJSON(),
		RuleSets:    "[]",
	}
	if err := s.repo.CreateUserWithCompany(ctx, user, company, role); err != nil {
		return nil, fmt.Errorf("create user: %w", err)
	}

	return s.buildAuthResponse(ctx, user)
}

func (s *AuthService) Login(ctx context.Context, req dto.LoginRequest) (*dto.AuthResponse, error) {
	// Demo mode: special credentials bypass DB lookup.
	if req.Email == "demo@autocreat.io" && req.Password == "Demo123!" {
		return s.buildDemoAuthResponse()
	}

	user, err := s.repo.FindUserByEmail(ctx, req.Email)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("invalid credentials")
		}
		return nil, err
	}

	if !user.IsActive {
		return nil, errors.New("account is disabled")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		return nil, errors.New("invalid credentials")
	}

	return s.buildAuthResponse(ctx, user)
}

func (s *AuthService) Refresh(ctx context.Context, refreshToken string) (*dto.TokenResponse, error) {
	token, err := jwt.Parse(refreshToken, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return []byte(s.cfg.JWTRefreshSecret), nil
	})
	if err != nil || !token.Valid {
		return nil, errors.New("invalid refresh token")
	}

	mapClaims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return nil, errors.New("invalid token claims")
	}

	subStr, ok := mapClaims["sub"].(string)
	if !ok {
		return nil, errors.New("invalid token subject")
	}

	userID, err := uuid.Parse(subStr)
	if err != nil {
		return nil, errors.New("invalid user id in token")
	}

	_, err = s.repo.FindSessionByToken(ctx, refreshToken)
	if err != nil {
		return nil, errors.New("session not found or expired")
	}

	user, err := s.repo.FindUserByID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("user not found: %w", err)
	}

	_ = s.repo.DeleteSession(ctx, refreshToken)
	return s.issueTokenResponse(ctx, user)
}

func (s *AuthService) Logout(ctx context.Context, refreshToken string) error {
	return s.repo.DeleteSession(ctx, refreshToken)
}

func (s *AuthService) GetMe(ctx context.Context, userID uuid.UUID) (*models.User, error) {
	return s.repo.FindUserByID(ctx, userID)
}

func (s *AuthService) ValidateAccessToken(tokenStr string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &Claims{}, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return []byte(s.cfg.JWTSecret), nil
	})
	if err != nil || !token.Valid {
		return nil, errors.New("invalid or expired access token")
	}
	claims, ok := token.Claims.(*Claims)
	if !ok {
		return nil, errors.New("invalid token claims")
	}
	return claims, nil
}

// ---------- helpers ----------

// fullAccessPermissionsJSON returns a JSON array (matching Flutter's Permission
// model shape) granting full CRUD on every resource, for a company owner.
func fullAccessPermissionsJSON() string {
	resources := []string{
		"companies", "users", "roles", "flows", "forms",
		"models", "letters", "tickets", "instances",
	}
	perms := make([]dto.Permission, len(resources))
	for i, r := range resources {
		perms[i] = dto.Permission{
			Resource:      r,
			CanCreate:     true,
			CanRead:       true,
			CanUpdate:     true,
			CanDelete:     true,
			CustomActions: []string{},
		}
	}
	b, err := json.Marshal(perms)
	if err != nil {
		return "[]"
	}
	return string(b)
}

func (s *AuthService) buildDemoAuthResponse() (*dto.AuthResponse, error) {
	cid := DemoCompanyID
	now := time.Now()
	accessClaims := &Claims{
		UserID:    DemoUserID,
		Email:     "demo@autocreat.io",
		CompanyID: &cid,
		IsDemo:    true,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   DemoUserID.String(),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(365 * 24 * time.Hour)),
		},
	}
	accessToken, err := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims).SignedString([]byte(s.cfg.JWTSecret))
	if err != nil {
		return nil, fmt.Errorf("sign demo access token: %w", err)
	}
	refreshClaims := jwt.RegisteredClaims{
		Subject:   DemoUserID.String(),
		IssuedAt:  jwt.NewNumericDate(now),
		ExpiresAt: jwt.NewNumericDate(now.Add(365 * 24 * time.Hour)),
	}
	refreshToken, err := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims).SignedString([]byte(s.cfg.JWTRefreshSecret))
	if err != nil {
		return nil, fmt.Errorf("sign demo refresh token: %w", err)
	}
	return &dto.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User: dto.UserResponse{
			ID:          DemoUserID,
			Email:       "demo@autocreat.io",
			FirstName:   "Demo",
			LastName:    "User",
			Role:        "owner",
			IsActive:    true,
			CompanyID:   &cid,
			Permissions: []string{},
		},
	}, nil
}

func (s *AuthService) buildAuthResponse(ctx context.Context, user *models.User) (*dto.AuthResponse, error) {
	accessToken, refreshToken, err := s.issueTokens(ctx, user)
	if err != nil {
		return nil, err
	}

	role := "member"
	if user.IsOwner {
		role = "owner"
	}

	return &dto.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User: dto.UserResponse{
			ID:          user.ID,
			Email:       user.Email,
			FirstName:   user.FirstName,
			LastName:    user.LastName,
			Phone:       user.Phone,
			Avatar:      user.Avatar,
			Role:        role,
			IsActive:    user.IsActive,
			CompanyID:   user.CompanyID,
			RoleID:      user.RoleID,
			Permissions: []string{},
			CreatedAt:   user.CreatedAt,
			UpdatedAt:   user.UpdatedAt,
		},
	}, nil
}

func (s *AuthService) issueTokenResponse(ctx context.Context, user *models.User) (*dto.TokenResponse, error) {
	accessToken, refreshToken, err := s.issueTokens(ctx, user)
	if err != nil {
		return nil, err
	}
	return &dto.TokenResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		TokenType:    "Bearer",
		ExpiresIn:    int64(s.cfg.AccessTokenTTL.Seconds()),
	}, nil
}

func (s *AuthService) issueTokens(ctx context.Context, user *models.User) (string, string, error) {
	now := time.Now()

	accessClaims := &Claims{
		UserID:    user.ID,
		Email:     user.Email,
		CompanyID: user.CompanyID,
		RoleID:    user.RoleID,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   user.ID.String(),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(s.cfg.AccessTokenTTL)),
		},
	}
	accessToken, err := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims).SignedString([]byte(s.cfg.JWTSecret))
	if err != nil {
		return "", "", fmt.Errorf("sign access token: %w", err)
	}

	refreshExpiry := now.Add(s.cfg.RefreshTokenTTL)
	refreshClaims := jwt.RegisteredClaims{
		ID:        uuid.New().String(), // unique jti prevents duplicate-key collisions
		Subject:   user.ID.String(),
		IssuedAt:  jwt.NewNumericDate(now),
		ExpiresAt: jwt.NewNumericDate(refreshExpiry),
	}
	refreshToken, err := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims).SignedString([]byte(s.cfg.JWTRefreshSecret))
	if err != nil {
		return "", "", fmt.Errorf("sign refresh token: %w", err)
	}

	session := &models.Session{
		ID:           uuid.New(),
		UserID:       user.ID,
		RefreshToken: refreshToken,
		ExpiresAt:    refreshExpiry,
	}
	if err := s.repo.CreateSession(ctx, session); err != nil {
		return "", "", fmt.Errorf("persist session: %w", err)
	}

	return accessToken, refreshToken, nil
}
