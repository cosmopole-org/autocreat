package dto_test

import (
	"encoding/json"
	"testing"

	"github.com/autocreat/server/internal/dto"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ---- RegisterRequest ----

func TestRegisterRequest_JSON(t *testing.T) {
	req := dto.RegisterRequest{
		Email:       "alice@example.com",
		Password:    "securePass1",
		FirstName:   "Alice",
		LastName:    "Smith",
		CompanyName: "Acme",
		Phone:       "+1234567890",
	}
	data, err := json.Marshal(req)
	require.NoError(t, err)

	var decoded dto.RegisterRequest
	require.NoError(t, json.Unmarshal(data, &decoded))
	assert.Equal(t, req.Email, decoded.Email)
	assert.Equal(t, req.CompanyName, decoded.CompanyName)
}

// ---- LoginRequest ----

func TestLoginRequest_JSON(t *testing.T) {
	req := dto.LoginRequest{Email: "bob@example.com", Password: "myPass"}
	data, _ := json.Marshal(req)

	var decoded dto.LoginRequest
	require.NoError(t, json.Unmarshal(data, &decoded))
	assert.Equal(t, req.Email, decoded.Email)
	assert.Equal(t, req.Password, decoded.Password)
}

// ---- RefreshRequest ----

func TestRefreshRequest_JSON(t *testing.T) {
	req := dto.RefreshRequest{RefreshToken: "some-refresh-token"}
	data, _ := json.Marshal(req)

	var decoded dto.RefreshRequest
	require.NoError(t, json.Unmarshal(data, &decoded))
	assert.Equal(t, req.RefreshToken, decoded.RefreshToken)
}

// ---- TokenResponse snake_case JSON ----

func TestTokenResponse_SnakeCaseJSON(t *testing.T) {
	tr := dto.TokenResponse{
		AccessToken:  "access",
		RefreshToken: "refresh",
		TokenType:    "Bearer",
		ExpiresIn:    900,
	}
	data, err := json.Marshal(tr)
	require.NoError(t, err)

	// TokenResponse must use snake_case keys (the Flutter interceptor reads 'access_token').
	assert.Contains(t, string(data), `"access_token"`)
	assert.Contains(t, string(data), `"refresh_token"`)
	assert.Contains(t, string(data), `"token_type"`)
	assert.Contains(t, string(data), `"expires_in"`)
}

// ---- AuthResponse camelCase JSON ----

func TestAuthResponse_CamelCaseJSON(t *testing.T) {
	uid := uuid.New()
	cid := uuid.New()
	ar := dto.AuthResponse{
		AccessToken:  "at",
		RefreshToken: "rt",
		User: dto.UserResponse{
			ID:        uid,
			Email:     "test@test.com",
			FirstName: "First",
			LastName:  "Last",
			CompanyID: &cid,
		},
	}
	data, err := json.Marshal(ar)
	require.NoError(t, err)

	// AuthResponse uses camelCase (Flutter's AuthResponse.fromJson).
	assert.Contains(t, string(data), `"accessToken"`)
	assert.Contains(t, string(data), `"refreshToken"`)
}

// ---- UserResponse ----

func TestUserResponse_OptionalFields(t *testing.T) {
	ur := dto.UserResponse{
		ID:          uuid.New(),
		Email:       "user@test.com",
		Permissions: []string{},
	}
	data, err := json.Marshal(ur)
	require.NoError(t, err)
	assert.Contains(t, string(data), `"permissions":[]`)
}

// ---- CreateCompanyRequest ----

func TestCreateCompanyRequest_JSON(t *testing.T) {
	req := dto.CreateCompanyRequest{
		Name:        "Acme Corp",
		Description: "A company",
		Industry:    "Technology",
	}
	data, _ := json.Marshal(req)

	var decoded dto.CreateCompanyRequest
	require.NoError(t, json.Unmarshal(data, &decoded))
	assert.Equal(t, "Acme Corp", decoded.Name)
	assert.Equal(t, "Technology", decoded.Industry)
}

// ---- Permission ----

func TestPermission_JSON(t *testing.T) {
	p := dto.Permission{
		Resource:      "flows",
		CanCreate:     true,
		CanRead:       true,
		CanUpdate:     false,
		CanDelete:     false,
		CustomActions: []string{"export"},
	}
	data, _ := json.Marshal(p)

	var decoded dto.Permission
	require.NoError(t, json.Unmarshal(data, &decoded))
	assert.Equal(t, "flows", decoded.Resource)
	assert.True(t, decoded.CanCreate)
	assert.False(t, decoded.CanDelete)
	assert.Equal(t, []string{"export"}, decoded.CustomActions)
}

// ---- CompanyResponse ----

func TestCompanyResponse_JSON(t *testing.T) {
	cr := dto.CompanyResponse{
		ID:          uuid.New(),
		Name:        "Test Co",
		Status:      "active",
		MemberCount: 5,
		FlowCount:   2,
	}
	data, _ := json.Marshal(cr)
	assert.Contains(t, string(data), `"memberCount":5`)
	assert.Contains(t, string(data), `"flowCount":2`)
}
