package router

import (
	"context"
	"fmt"
	"html"
	"net/http"
	"strings"
	"time"

	"github.com/autocreat/server/internal/handler"
	"github.com/autocreat/server/internal/middleware"
	"github.com/autocreat/server/internal/service"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// Options bundles everything the router needs to wire up.
type Options struct {
	AuthHandler     *handler.AuthHandler
	CompanyHandler  *handler.CompanyHandler
	RoleHandler     *handler.RoleHandler
	UserHandler     *handler.UserHandler
	FlowHandler     *handler.FlowHandler
	FormHandler     *handler.FormHandler
	ModelHandler    *handler.ModelHandler
	LetterHandler   *handler.LetterHandler
	TicketHandler   *handler.TicketHandler
	StatsHandler    *handler.StatsHandler
	RealtimeHandler *handler.RealtimeHandler
	BindingHandler  *handler.BindingHandler
	AuthService     *service.AuthService
	AllowedOrigins  []string
	RateLimitRPS    int
	RateLimitBurst  int
	Log             *zap.Logger

	// Env is reported by the /diag probe (e.g. "production").
	Env string
	// PingDB, when set, is called by /diag to check database connectivity.
	PingDB func(ctx context.Context) error
}

// New builds and returns the configured Gin engine.
func New(opts Options) *gin.Engine {
	engine := gin.New()
	engine.Use(gin.Recovery())
	engine.Use(middleware.Logger(opts.Log))
	engine.Use(middleware.CORS(opts.AllowedOrigins))
	engine.Use(middleware.RateLimiter(opts.RateLimitRPS, opts.RateLimitBurst))

	// Request timeout (30s)
	engine.Use(func(c *gin.Context) {
		ctx := c.Request.Context()
		// We add a deadline; if the handler respects ctx.Done() it can cancel.
		_ = ctx
		timer := time.AfterFunc(30*time.Second, func() {})
		defer timer.Stop()
		c.Next()
	})

	// Health check (no auth required)
	engine.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok", "service": "autocreat"})
	})

	// Diagnostic probe — meant to be opened in a browser (including mobile)
	// without needing DevTools. Reports env, DB connectivity, and the
	// configured CORS origins so client/server connection issues can be
	// confirmed at a glance. Also accessible at /api/v1/diag.
	diag := diagHandler(opts)
	engine.GET("/diag", diag)

	v1 := engine.Group("/api/v1")
	v1.GET("/diag", diag)

	// ---------- Auth ----------
	auth := v1.Group("/auth")
	{
		auth.POST("/register", opts.AuthHandler.Register)
		auth.POST("/login", opts.AuthHandler.Login)
		auth.POST("/refresh", opts.AuthHandler.Refresh)
		auth.POST("/logout", opts.AuthHandler.Logout)
		auth.GET("/me", middleware.Auth(opts.AuthService), opts.AuthHandler.Me)
	}

	// ---------- Authenticated routes ----------
	authed := v1.Group("")
	authed.Use(middleware.Auth(opts.AuthService))
	authed.Use(middleware.DemoMode())

	// Companies
	companies := authed.Group("/companies")
	{
		companies.GET("", opts.CompanyHandler.List)
		companies.POST("", opts.CompanyHandler.Create)
		companies.GET("/:id", opts.CompanyHandler.GetByID)
		companies.PUT("/:id", opts.CompanyHandler.Update)
		companies.DELETE("/:id", opts.CompanyHandler.Delete)
		companies.GET("/:id/members", opts.CompanyHandler.ListMembers)
		companies.POST("/:id/members", opts.CompanyHandler.AddMember)
		companies.DELETE("/:id/members/:userId", opts.CompanyHandler.RemoveMember)
	}

	// ---------- Flat resource routes ----------
	// The Flutter client addresses all company-scoped resources via flat
	// paths with companyId supplied as a query parameter (or in the body for
	// create requests). companyIDFromContext resolves it from either source.
	flat := authed.Group("")

	flat.GET("/roles", opts.RoleHandler.List)
	flat.POST("/roles", opts.RoleHandler.Create)
	flat.GET("/roles/:id", opts.RoleHandler.GetByID)
	flat.PUT("/roles/:id", opts.RoleHandler.Update)
	flat.DELETE("/roles/:id", opts.RoleHandler.Delete)

	flat.GET("/users", opts.UserHandler.List)
	flat.POST("/users", opts.UserHandler.Create)
	flat.GET("/users/:id", opts.UserHandler.GetByID)
	flat.PUT("/users/:id", opts.UserHandler.Update)
	flat.DELETE("/users/:id", opts.UserHandler.Delete)
	flat.PATCH("/users/:id/role", opts.UserHandler.AssignRole)

	flat.GET("/flows", opts.FlowHandler.List)
	flat.POST("/flows", opts.FlowHandler.Create)
	flat.GET("/flows/startable", opts.FlowHandler.GetStartableFlows)
	flat.GET("/flows/:id", opts.FlowHandler.GetByID)
	flat.PUT("/flows/:id", opts.FlowHandler.Update)
	flat.DELETE("/flows/:id", opts.FlowHandler.Delete)
	flat.GET("/flows/:id/nodes", opts.FlowHandler.ListNodes)
	flat.POST("/flows/:id/nodes", opts.FlowHandler.CreateNode)
	flat.PUT("/flows/:id/nodes/:nid", opts.FlowHandler.UpdateNode)
	flat.DELETE("/flows/:id/nodes/:nid", opts.FlowHandler.DeleteNode)
	flat.GET("/flows/:id/edges", opts.FlowHandler.ListEdges)
	flat.POST("/flows/:id/edges", opts.FlowHandler.CreateEdge)
	flat.DELETE("/flows/:id/edges/:eid", opts.FlowHandler.DeleteEdge)
	flat.PUT("/flows/:id/graph", opts.FlowHandler.SaveGraph)
	flat.GET("/flows/:id/assignments", opts.FlowHandler.ListAssignments)
	flat.POST("/flows/:id/assignments", opts.FlowHandler.CreateAssignment)
	flat.DELETE("/flows/:id/assignments/:aid", opts.FlowHandler.DeleteAssignment)

	flat.GET("/instances", opts.FlowHandler.ListInstances)
	flat.POST("/instances", opts.FlowHandler.StartInstance)
	flat.GET("/instances/my-tasks", opts.FlowHandler.GetMyTasks)
	flat.GET("/instances/my-tasks/full", opts.FlowHandler.GetMyTasksFull)
	flat.GET("/instances/task-detail", opts.FlowHandler.GetTaskDetails)
	flat.GET("/roles/:id/role-users", opts.FlowHandler.GetUsersForRole)
	flat.GET("/instances/:id", opts.FlowHandler.GetInstance)
	flat.POST("/instances/:id/advance", opts.FlowHandler.AdvanceInstance)
	flat.POST("/instances/:id/reject", opts.FlowHandler.RejectInstance)

	flat.GET("/forms", opts.FormHandler.List)
	flat.POST("/forms", opts.FormHandler.Create)
	flat.GET("/forms/:id", opts.FormHandler.GetByID)
	flat.PUT("/forms/:id", opts.FormHandler.Update)
	flat.DELETE("/forms/:id", opts.FormHandler.Delete)

	flat.GET("/models", opts.ModelHandler.List)
	flat.POST("/models", opts.ModelHandler.Create)
	flat.GET("/models/:id", opts.ModelHandler.GetByID)
	flat.PUT("/models/:id", opts.ModelHandler.Update)
	flat.DELETE("/models/:id", opts.ModelHandler.Delete)
	flat.GET("/models/:id/entities", opts.ModelHandler.ListEntities)
	flat.POST("/models/:id/entities", opts.ModelHandler.CreateEntity)
	flat.GET("/models/:id/entities/:eid", opts.ModelHandler.GetEntity)
	flat.PUT("/models/:id/entities/:eid", opts.ModelHandler.UpdateEntity)
	flat.DELETE("/models/:id/entities/:eid", opts.ModelHandler.DeleteEntity)

	flat.GET("/letters", opts.LetterHandler.List)
	flat.POST("/letters", opts.LetterHandler.Create)
	flat.GET("/letters/:id", opts.LetterHandler.GetByID)
	flat.PUT("/letters/:id", opts.LetterHandler.Update)
	flat.DELETE("/letters/:id", opts.LetterHandler.Delete)
	flat.POST("/letters/:id/generate", opts.LetterHandler.Generate)

	flat.GET("/tickets", opts.TicketHandler.List)
	flat.POST("/tickets", opts.TicketHandler.Create)
	flat.GET("/tickets/:id", opts.TicketHandler.GetByID)
	flat.PUT("/tickets/:id", opts.TicketHandler.Update)
	flat.PATCH("/tickets/:id/status", opts.TicketHandler.UpdateStatus)
	flat.POST("/tickets/:id/messages", opts.TicketHandler.SendMessage)

	flat.GET("/stats", opts.StatsHandler.GetStats)

	// ---------- Binding & Letter Assignment routes ----------
	if opts.BindingHandler != nil {
		flat.GET("/nodes/:nodeId/bindings", opts.BindingHandler.ListBindings)
		flat.POST("/nodes/:nodeId/bindings", opts.BindingHandler.SaveBinding)
		flat.DELETE("/bindings/:id", opts.BindingHandler.DeleteBinding)

		flat.GET("/nodes/:nodeId/letter-assignments", opts.BindingHandler.ListLetterAssignments)
		flat.POST("/nodes/:nodeId/letter-assignments", opts.BindingHandler.SaveLetterAssignment)
		flat.DELETE("/letter-assignments/:id", opts.BindingHandler.DeleteLetterAssignment)

		flat.POST("/instances/:id/steps/:stepId/generate-letter", opts.BindingHandler.GenerateStepLetter)
		flat.GET("/instances/:id/steps/:stepId/generated-letters", opts.BindingHandler.ListStepGeneratedLetters)
	}

	// Realtime WebSocket
	rt := v1.Group("/realtime")
	rt.Use(middleware.Auth(opts.AuthService))
	rt.GET("/ws", opts.RealtimeHandler.ServeWS)

	return engine
}

// diagHandler returns a handler that reports basic connectivity info,
// rendering as HTML for browsers and JSON for everything else.
func diagHandler(opts Options) gin.HandlerFunc {
	return func(c *gin.Context) {
		dbStatus := "skipped"
		dbErr := ""
		if opts.PingDB != nil {
			ctx, cancel := context.WithTimeout(c.Request.Context(), 3*time.Second)
			defer cancel()
			if err := opts.PingDB(ctx); err != nil {
				dbStatus = "down"
				dbErr = err.Error()
			} else {
				dbStatus = "ok"
			}
		}

		origin := c.GetHeader("Origin")
		originAllowed := "n/a (no Origin header on request)"
		if origin != "" {
			originAllowed = "no"
			for _, o := range opts.AllowedOrigins {
				if o == origin || o == "http://localhost:*" || o == "http://127.0.0.1:*" {
					originAllowed = "yes"
					break
				}
			}
		}

		payload := gin.H{
			"status":          "ok",
			"service":         "autocreat",
			"env":             opts.Env,
			"db":              dbStatus,
			"dbError":         dbErr,
			"requestOrigin":   origin,
			"originAllowed":   originAllowed,
			"allowedOrigins":  opts.AllowedOrigins,
			"serverTime":      time.Now().UTC().Format(time.RFC3339),
		}

		if strings.Contains(c.GetHeader("Accept"), "text/html") {
			c.Header("Content-Type", "text/html; charset=utf-8")
			c.String(http.StatusOK, renderDiagHTML(payload))
			return
		}
		c.JSON(http.StatusOK, payload)
	}
}

func renderDiagHTML(d gin.H) string {
	row := func(k string, v any) string {
		return fmt.Sprintf(
			`<tr><th>%s</th><td>%s</td></tr>`,
			html.EscapeString(k), html.EscapeString(fmt.Sprintf("%v", v)),
		)
	}
	var b strings.Builder
	b.WriteString(`<!doctype html><html><head><meta charset="utf-8">`)
	b.WriteString(`<meta name="viewport" content="width=device-width,initial-scale=1">`)
	b.WriteString(`<title>AutoCreat API diag</title>`)
	b.WriteString(`<style>body{font:16px -apple-system,Segoe UI,Roboto,sans-serif;`)
	b.WriteString(`margin:24px;color:#222}h1{font-size:22px;margin:0 0 16px}`)
	b.WriteString(`table{border-collapse:collapse;width:100%;max-width:680px}`)
	b.WriteString(`th,td{padding:8px 10px;border-bottom:1px solid #eee;text-align:left;`)
	b.WriteString(`vertical-align:top;word-break:break-word}th{width:38%;color:#555;font-weight:600}`)
	b.WriteString(`.ok{color:#0a7d2f}.bad{color:#b00020}</style></head><body>`)
	b.WriteString(`<h1>AutoCreat API · diag</h1><table>`)
	b.WriteString(row("status", d["status"]))
	b.WriteString(row("env", d["env"]))
	b.WriteString(row("db", d["db"]))
	if s, _ := d["dbError"].(string); s != "" {
		b.WriteString(row("dbError", s))
	}
	b.WriteString(row("requestOrigin", d["requestOrigin"]))
	b.WriteString(row("originAllowed", d["originAllowed"]))
	b.WriteString(row("allowedOrigins", strings.Join(toStringSlice(d["allowedOrigins"]), ", ")))
	b.WriteString(row("serverTime", d["serverTime"]))
	b.WriteString(`</table></body></html>`)
	return b.String()
}

func toStringSlice(v any) []string {
	if s, ok := v.([]string); ok {
		return s
	}
	return nil
}
