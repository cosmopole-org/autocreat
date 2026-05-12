package dto

// RegisterRequest is the payload for creating a new user account.
type RegisterRequest struct {
	Email    string `json:"email"    binding:"required,email"`
	Password string `json:"password" binding:"required,min=8"`
	FullName string `json:"full_name" binding:"required"`
}

// LoginRequest is the payload for authenticating with email + password.
type LoginRequest struct {
	Email    string `json:"email"    binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

// RefreshRequest carries the refresh token issued at login.
type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// TokenPair is returned after a successful login or token refresh.
type TokenPair struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	TokenType    string `json:"token_type"`
	ExpiresIn    int64  `json:"expires_in"` // seconds
}

// AuthResponse wraps a user profile together with token pair.
type AuthResponse struct {
	User  UserResponse `json:"user"`
	Tokens TokenPair   `json:"tokens"`
}
