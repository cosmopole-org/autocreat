package service_test

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/autocreat/server/internal/service"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
)

func testHub(t *testing.T) *service.Hub {
	t.Helper()
	log, _ := zap.NewDevelopment()
	return service.NewHub(log)
}

// mockClient creates a Client with a buffered Send channel (no real websocket).
func mockClient(companyID, userID uuid.UUID) *service.Client {
	return &service.Client{
		ID:        uuid.New(),
		UserID:    userID,
		CompanyID: companyID,
		Conn:      nil, // not used in broadcast tests
		Send:      make(chan []byte, 256),
	}
}

// ---- Hub Register / Unregister ----

func TestHub_RegisterAndUnregister(t *testing.T) {
	hub := testHub(t)
	cid := uuid.New()
	uid := uuid.New()

	c := mockClient(cid, uid)
	hub.Register(c)

	// After register, broadcast should reach the client.
	hub.BroadcastToCompany(cid, "test.event", map[string]string{"key": "val"})

	select {
	case msg := <-c.Send:
		assert.NotEmpty(t, msg)
	case <-time.After(time.Second):
		t.Fatal("expected message not received after Register")
	}

	hub.Unregister(c)

	// After unregister, the Send channel is closed.
	_, ok := <-c.Send
	assert.False(t, ok, "Send channel should be closed after Unregister")
}

func TestHub_UnregisterNonExistentClient(t *testing.T) {
	hub := testHub(t)
	c := mockClient(uuid.New(), uuid.New())
	// Should not panic.
	assert.NotPanics(t, func() { hub.Unregister(c) })
}

func TestHub_DoubleUnregister(t *testing.T) {
	hub := testHub(t)
	c := mockClient(uuid.New(), uuid.New())
	hub.Register(c)
	hub.Unregister(c)
	// Second unregister of a deleted client should be a no-op (not panic/close twice).
	assert.NotPanics(t, func() { hub.Unregister(c) })
}

// ---- BroadcastToCompany ----

func TestHub_BroadcastToCompany_OnlyTargetCompany(t *testing.T) {
	hub := testHub(t)
	cid1 := uuid.New()
	cid2 := uuid.New()

	c1 := mockClient(cid1, uuid.New())
	c2 := mockClient(cid2, uuid.New())
	hub.Register(c1)
	hub.Register(c2)
	defer hub.Unregister(c1)
	defer hub.Unregister(c2)

	hub.BroadcastToCompany(cid1, "ping", nil)

	// c1 should receive the message.
	select {
	case msg := <-c1.Send:
		assert.NotEmpty(t, msg)
	case <-time.After(time.Second):
		t.Fatal("c1 should have received the message")
	}

	// c2 should NOT receive a message.
	select {
	case <-c2.Send:
		t.Fatal("c2 should not have received message for cid1")
	case <-time.After(50 * time.Millisecond):
		// expected: no message
	}
}

func TestHub_BroadcastToCompany_MessageEncoding(t *testing.T) {
	hub := testHub(t)
	cid := uuid.New()
	c := mockClient(cid, uuid.New())
	hub.Register(c)
	defer hub.Unregister(c)

	payload := map[string]interface{}{"id": "abc", "count": 42}
	hub.BroadcastToCompany(cid, "resource.updated", payload)

	select {
	case raw := <-c.Send:
		var msg service.WSMessage
		require.NoError(t, json.Unmarshal(raw, &msg))
		assert.Equal(t, "resource.updated", msg.Type)
		assert.NotEmpty(t, msg.Payload)
	case <-time.After(time.Second):
		t.Fatal("message not received")
	}
}

func TestHub_BroadcastToCompany_NoClients(t *testing.T) {
	hub := testHub(t)
	// Should not panic when no clients are registered.
	assert.NotPanics(t, func() {
		hub.BroadcastToCompany(uuid.New(), "event", nil)
	})
}

// ---- BroadcastToCompanyExcept ----

func TestHub_BroadcastToCompanyExcept(t *testing.T) {
	hub := testHub(t)
	cid := uuid.New()

	c1 := mockClient(cid, uuid.New())
	c2 := mockClient(cid, uuid.New())
	hub.Register(c1)
	hub.Register(c2)
	defer hub.Unregister(c1)
	defer hub.Unregister(c2)

	hub.BroadcastToCompanyExcept(cid, c1.ID, "test.except", "payload")

	// c2 receives, c1 does not.
	select {
	case <-c2.Send:
		// ok
	case <-time.After(time.Second):
		t.Fatal("c2 should have received the message")
	}
	select {
	case <-c1.Send:
		t.Fatal("c1 should not have received the message")
	case <-time.After(50 * time.Millisecond):
		// expected
	}
}

// ---- BroadcastToUser ----

func TestHub_BroadcastToUser(t *testing.T) {
	hub := testHub(t)
	cid := uuid.New()
	uid1 := uuid.New()
	uid2 := uuid.New()

	c1 := mockClient(cid, uid1)
	c2 := mockClient(cid, uid2)
	hub.Register(c1)
	hub.Register(c2)
	defer hub.Unregister(c1)
	defer hub.Unregister(c2)

	hub.BroadcastToUser(uid1, "user.notification", "hello")

	select {
	case <-c1.Send:
		// ok
	case <-time.After(time.Second):
		t.Fatal("c1 (uid1) should have received the message")
	}
	select {
	case <-c2.Send:
		t.Fatal("c2 (uid2) should not have received uid1's message")
	case <-time.After(50 * time.Millisecond):
		// expected
	}
}

// ---- WSMessage JSON ----

func TestWSMessage_JSON(t *testing.T) {
	payload, _ := json.Marshal(map[string]string{"hello": "world"})
	msg := service.WSMessage{
		Type:    "test.type",
		Payload: json.RawMessage(payload),
	}
	data, err := json.Marshal(msg)
	require.NoError(t, err)

	var decoded service.WSMessage
	require.NoError(t, json.Unmarshal(data, &decoded))
	assert.Equal(t, "test.type", decoded.Type)
	assert.JSONEq(t, `{"hello":"world"}`, string(decoded.Payload))
}

// ---- Multiple clients for same user ----

func TestHub_BroadcastToUser_MultipleConnections(t *testing.T) {
	hub := testHub(t)
	cid := uuid.New()
	uid := uuid.New()

	c1 := mockClient(cid, uid)
	c2 := mockClient(cid, uid) // same user, second connection
	hub.Register(c1)
	hub.Register(c2)
	defer hub.Unregister(c1)
	defer hub.Unregister(c2)

	hub.BroadcastToUser(uid, "ping", nil)

	for _, ch := range []chan []byte{c1.Send, c2.Send} {
		select {
		case <-ch:
			// ok
		case <-time.After(time.Second):
			t.Fatal("expected both connections to receive")
		}
	}
}
