package handler

import (
	"net/http"

	"github.com/autocreat/server/internal/middleware"
	"github.com/autocreat/server/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"go.uber.org/zap"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		// Origin checking is handled by CORS middleware; allow all here.
		return true
	},
}

type RealtimeHandler struct {
	hub *service.Hub
	log *zap.Logger
}

func NewRealtimeHandler(hub *service.Hub, log *zap.Logger) *RealtimeHandler {
	return &RealtimeHandler{hub: hub, log: log}
}

func (h *RealtimeHandler) ServeWS(c *gin.Context) {
	userIDVal, exists := c.Get(middleware.ContextUserID)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "not authenticated"})
		return
	}
	userID := userIDVal.(uuid.UUID)

	var companyID uuid.UUID
	if cidVal, ok := c.Get(middleware.ContextCompanyID); ok {
		companyID = cidVal.(uuid.UUID)
	}

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		h.log.Error("ws upgrade failed", zap.Error(err))
		return
	}

	client := &service.Client{
		ID:        uuid.New(),
		UserID:    userID,
		CompanyID: companyID,
		Conn:      conn,
		Send:      make(chan []byte, 256),
	}

	h.hub.Register(client)

	go h.hub.WritePump(client)
	h.hub.ReadPump(client) // blocks until disconnect
}
