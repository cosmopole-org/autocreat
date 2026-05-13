package app

import (
	"github.com/autocreat/server/internal/config"
	"github.com/autocreat/server/internal/handler"
	"github.com/autocreat/server/internal/repository"
	"github.com/autocreat/server/internal/router"
	"github.com/autocreat/server/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

// App holds all wired-up dependencies.
type App struct {
	Engine *gin.Engine
	DB     *gorm.DB
	Redis  *redis.Client
	Log    *zap.Logger
	Config *config.Config
	Hub    *service.Hub
}

// New wires all components together and returns a ready App.
func New(cfg *config.Config, db *gorm.DB, rdb *redis.Client, log *zap.Logger) *App {
	if cfg.Env == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Hub
	hub := service.NewHub(log)

	// Repositories
	authRepo := repository.NewAuthRepository(db)
	companyRepo := repository.NewCompanyRepository(db)
	roleRepo := repository.NewRoleRepository(db)
	userRepo := repository.NewUserRepository(db)
	flowRepo := repository.NewFlowRepository(db)
	formRepo := repository.NewFormRepository(db)
	modelRepo := repository.NewModelRepository(db)
	letterRepo := repository.NewLetterRepository(db)
	ticketRepo := repository.NewTicketRepository(db)

	// Services
	authSvc := service.NewAuthService(authRepo, cfg)
	companySvc := service.NewCompanyService(companyRepo, rdb)
	roleSvc := service.NewRoleService(roleRepo, hub)
	userSvc := service.NewUserService(userRepo, hub)
	flowSvc := service.NewFlowService(flowRepo, db, hub)
	formSvc := service.NewFormService(formRepo, hub)
	modelSvc := service.NewModelService(modelRepo)
	letterSvc := service.NewLetterService(letterRepo)
	ticketSvc := service.NewTicketService(ticketRepo, hub)

	// Handlers
	authH := handler.NewAuthHandler(authSvc)
	companyH := handler.NewCompanyHandler(companySvc)
	roleH := handler.NewRoleHandler(roleSvc)
	userH := handler.NewUserHandler(userSvc)
	flowH := handler.NewFlowHandler(flowSvc)
	formH := handler.NewFormHandler(formSvc)
	modelH := handler.NewModelHandler(modelSvc)
	letterH := handler.NewLetterHandler(letterSvc)
	ticketH := handler.NewTicketHandler(ticketSvc)
	statsH := handler.NewStatsHandler(db)
	realtimeH := handler.NewRealtimeHandler(hub, log)

	engine := router.New(router.Options{
		AuthHandler:     authH,
		CompanyHandler:  companyH,
		RoleHandler:     roleH,
		UserHandler:     userH,
		FlowHandler:     flowH,
		FormHandler:     formH,
		ModelHandler:    modelH,
		LetterHandler:   letterH,
		TicketHandler:   ticketH,
		StatsHandler:    statsH,
		RealtimeHandler: realtimeH,
		AuthService:     authSvc,
		AllowedOrigins:  cfg.AllowedOrigins,
		RateLimitRPS:    cfg.RateLimit,
		RateLimitBurst:  cfg.RateLimitBurst,
		Log:             log,
	})

	return &App{
		Engine: engine,
		DB:     db,
		Redis:  rdb,
		Log:    log,
		Config: cfg,
		Hub:    hub,
	}
}
