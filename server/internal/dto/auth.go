package dto

// RegisterRequest is the payload for creating a new user account.
// Accepts both camelCase (firstName) and snake_case (first_name) via Go's
// case-insensitive JSON unmarshal.
type RegisterRequest struct {
	Email       string `json:"email"       binding:"required,email"`
	Password    string `json:"password"    binding:"required,min=8"`
	FirstName   string `json:"firstName"   binding:"required"`
	LastName    string `json:"lastName"    binding:"required"`
	CompanyName string `json:"companyName"`
	Phone       string `json:"phone"`
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

// TokenResponse is returned by the refresh endpoint (snake_case for the
// Flutter interceptor which reads response.data['access_token']).
type TokenResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	TokenType    string `json:"token_type"`
	ExpiresIn    int64  `json:"expires_in"`
}

// AuthResponse wraps a user profile together with tokens.
// Uses camelCase to match Flutter's AuthResponse.fromJson.
type AuthResponse struct {
	AccessToken  string       `json:"accessToken"`
	RefreshToken string       `json:"refreshToken"`
	User         UserResponse `json:"user"`
}
