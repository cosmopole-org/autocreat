package router

import "testing"

// Gin panics at registration time on conflicting wildcards (e.g. mixing
// /companies/:id with /companies/:cid/...). This guards against reintroducing
// such a conflict, which would crash the server on startup.
func TestRouterBuildsWithoutPanic(t *testing.T) {
	defer func() {
		if r := recover(); r != nil {
			t.Fatalf("router build panicked: %v", r)
		}
	}()
	_ = New(Options{
		AuthHandler:     nil,
		CompanyHandler:  nil,
		RoleHandler:     nil,
		UserHandler:     nil,
		FlowHandler:     nil,
		FormHandler:     nil,
		ModelHandler:    nil,
		LetterHandler:   nil,
		TicketHandler:   nil,
		StatsHandler:    nil,
		RealtimeHandler: nil,
		AuthService:     nil,
		AllowedOrigins:  []string{"*"},
		RateLimitRPS:    10,
		RateLimitBurst:  20,
		Log:             nil,
	})
}
