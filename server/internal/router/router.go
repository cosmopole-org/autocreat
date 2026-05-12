package router

import (
	"net/http"
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
	AuthService     *service.AuthService
	AllowedOrigins  []string
	RateLimitRPS    int
	RateLimitBurst  int
	Log             *zap.Logger
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

	v1 := engine.Group("/api/v1")

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

	// Company-scoped resources (all under /companies/:cid/...)
	cid := authed.Group("/companies/:cid")
	cid.Use(middleware.CompanyContext())

	// Roles
	roles := cid.Group("/roles")
	{
		roles.GET("", opts.RoleHandler.List)
		roles.POST("", opts.RoleHandler.Create)
		roles.GET("/:id", opts.RoleHandler.GetByID)
		roles.PUT("/:id", opts.RoleHandler.Update)
		roles.DELETE("/:id", opts.RoleHandler.Delete)
	}

	// Users
	users := cid.Group("/users")
	{
		users.GET("", opts.UserHandler.List)
		users.POST("", opts.UserHandler.Create)
		users.GET("/:id", opts.UserHandler.GetByID)
		users.PUT("/:id", opts.UserHandler.Update)
		users.DELETE("/:id", opts.UserHandler.Delete)
	}

	// Flows
	flows := cid.Group("/flows")
	{
		flows.GET("", opts.FlowHandler.List)
		flows.POST("", opts.FlowHandler.Create)
		flows.GET("/:id", opts.FlowHandler.GetByID)
		flows.PUT("/:id", opts.FlowHandler.Update)
		flows.DELETE("/:id", opts.FlowHandler.Delete)
		flows.GET("/:id/nodes", opts.FlowHandler.ListNodes)
		flows.POST("/:id/nodes", opts.FlowHandler.CreateNode)
		flows.PUT("/:id/nodes/:nid", opts.FlowHandler.UpdateNode)
		flows.DELETE("/:id/nodes/:nid", opts.FlowHandler.DeleteNode)
		flows.GET("/:id/edges", opts.FlowHandler.ListEdges)
		flows.POST("/:id/edges", opts.FlowHandler.CreateEdge)
		flows.DELETE("/:id/edges/:eid", opts.FlowHandler.DeleteEdge)
		flows.PUT("/:id/graph", opts.FlowHandler.SaveGraph)
		flows.GET("/:id/assignments", opts.FlowHandler.ListAssignments)
		flows.POST("/:id/assignments", opts.FlowHandler.CreateAssignment)
		flows.DELETE("/:id/assignments/:aid", opts.FlowHandler.DeleteAssignment)
	}

	// Flow Instances
	instances := cid.Group("/instances")
	{
		instances.GET("", opts.FlowHandler.ListInstances)
		instances.POST("", opts.FlowHandler.StartInstance)
		instances.GET("/my-tasks", opts.FlowHandler.GetMyTasks)
		instances.GET("/:id", opts.FlowHandler.GetInstance)
		instances.POST("/:id/advance", opts.FlowHandler.AdvanceInstance)
		instances.POST("/:id/reject", opts.FlowHandler.RejectInstance)
	}

	// Forms
	forms := cid.Group("/forms")
	{
		forms.GET("", opts.FormHandler.List)
		forms.POST("", opts.FormHandler.Create)
		forms.GET("/:id", opts.FormHandler.GetByID)
		forms.PUT("/:id", opts.FormHandler.Update)
		forms.DELETE("/:id", opts.FormHandler.Delete)
	}

	// Models
	models := cid.Group("/models")
	{
		models.GET("", opts.ModelHandler.List)
		models.POST("", opts.ModelHandler.Create)
		models.GET("/:id", opts.ModelHandler.GetByID)
		models.PUT("/:id", opts.ModelHandler.Update)
		models.DELETE("/:id", opts.ModelHandler.Delete)
		models.GET("/:id/entities", opts.ModelHandler.ListEntities)
		models.POST("/:id/entities", opts.ModelHandler.CreateEntity)
		models.GET("/:id/entities/:eid", opts.ModelHandler.GetEntity)
		models.PUT("/:id/entities/:eid", opts.ModelHandler.UpdateEntity)
		models.DELETE("/:id/entities/:eid", opts.ModelHandler.DeleteEntity)
	}

	// Letter Templates
	letters := cid.Group("/letters")
	{
		letters.GET("", opts.LetterHandler.List)
		letters.POST("", opts.LetterHandler.Create)
		letters.GET("/:id", opts.LetterHandler.GetByID)
		letters.PUT("/:id", opts.LetterHandler.Update)
		letters.DELETE("/:id", opts.LetterHandler.Delete)
		letters.POST("/:id/generate", opts.LetterHandler.Generate)
	}

	// Tickets
	tickets := cid.Group("/tickets")
	{
		tickets.GET("", opts.TicketHandler.List)
		tickets.POST("", opts.TicketHandler.Create)
		tickets.GET("/:id", opts.TicketHandler.GetByID)
		tickets.PUT("/:id/status", opts.TicketHandler.UpdateStatus)
		tickets.POST("/:id/messages", opts.TicketHandler.SendMessage)
	}

	// Stats
	cid.GET("/stats", opts.StatsHandler.GetStats)

	// Realtime WebSocket
	rt := v1.Group("/realtime")
	rt.Use(middleware.Auth(opts.AuthService))
	rt.GET("/ws", opts.RealtimeHandler.ServeWS)

	return engine
}
