package service

import (
	"encoding/json"
	"sync"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"go.uber.org/zap"
)

// WSMessage is the envelope for every WebSocket message.
type WSMessage struct {
	Type    string          `json:"type"`
	Payload json.RawMessage `json:"payload"`
}

// Client represents a single connected WebSocket client.
type Client struct {
	ID        uuid.UUID
	UserID    uuid.UUID
	CompanyID uuid.UUID
	Conn      *websocket.Conn
	Send      chan []byte
}

// Hub manages all connected WebSocket clients and broadcasts messages.
type Hub struct {
	mu        sync.RWMutex
	clients   map[uuid.UUID]*Client // keyed by Client.ID
	log       *zap.Logger
}

func NewHub(log *zap.Logger) *Hub {
	return &Hub{
		clients: make(map[uuid.UUID]*Client),
		log:     log,
	}
}

// Register adds a client to the hub.
func (h *Hub) Register(c *Client) {
	h.mu.Lock()
	h.clients[c.ID] = c
	h.mu.Unlock()
	h.log.Info("ws client registered", zap.String("client_id", c.ID.String()), zap.String("user_id", c.UserID.String()))
}

// Unregister removes a client from the hub and closes its send channel.
func (h *Hub) Unregister(c *Client) {
	h.mu.Lock()
	if _, ok := h.clients[c.ID]; ok {
		delete(h.clients, c.ID)
		close(c.Send)
	}
	h.mu.Unlock()
	h.log.Info("ws client unregistered", zap.String("client_id", c.ID.String()))
}

// BroadcastToCompany sends a message to all clients in a given company.
func (h *Hub) BroadcastToCompany(companyID uuid.UUID, msgType string, payload interface{}) {
	raw, err := json.Marshal(payload)
	if err != nil {
		h.log.Error("broadcast marshal error", zap.Error(err))
		return
	}
	msg := WSMessage{Type: msgType, Payload: raw}
	data, _ := json.Marshal(msg)

	h.mu.RLock()
	defer h.mu.RUnlock()
	for _, c := range h.clients {
		if c.CompanyID == companyID {
			select {
			case c.Send <- data:
			default:
				h.log.Warn("ws send buffer full, dropping message", zap.String("client_id", c.ID.String()))
			}
		}
	}
}

// BroadcastToUser sends a message to a specific user (all their connections).
func (h *Hub) BroadcastToUser(userID uuid.UUID, msgType string, payload interface{}) {
	raw, err := json.Marshal(payload)
	if err != nil {
		return
	}
	msg := WSMessage{Type: msgType, Payload: raw}
	data, _ := json.Marshal(msg)

	h.mu.RLock()
	defer h.mu.RUnlock()
	for _, c := range h.clients {
		if c.UserID == userID {
			select {
			case c.Send <- data:
			default:
			}
		}
	}
}

// WritePump pumps messages from the hub to the WebSocket connection.
func (h *Hub) WritePump(c *Client) {
	defer func() {
		c.Conn.Close()
	}()
	for msg := range c.Send {
		if err := c.Conn.WriteMessage(websocket.TextMessage, msg); err != nil {
			h.log.Warn("ws write error", zap.Error(err))
			return
		}
	}
}

// ReadPump reads messages from the WebSocket and unregisters on disconnect.
func (h *Hub) ReadPump(c *Client) {
	defer func() {
		h.Unregister(c)
		c.Conn.Close()
	}()
	c.Conn.SetReadLimit(512 * 1024) // 512 KB
	for {
		_, _, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				h.log.Warn("ws unexpected close", zap.Error(err))
			}
			break
		}
		// We don't process inbound messages for now; the server is push-only.
	}
}
