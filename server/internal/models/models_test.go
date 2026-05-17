package models_test

import (
	"testing"

	"github.com/autocreat/server/internal/models"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

// ---- User model tests ----

func TestUser_FullName_BothNames(t *testing.T) {
	u := models.User{FirstName: "John", LastName: "Doe"}
	assert.Equal(t, "John Doe", u.FullName())
}

func TestUser_FullName_EmptyFallsToEmail(t *testing.T) {
	u := models.User{Email: "user@example.com"}
	assert.Equal(t, "user@example.com", u.FullName())
}

func TestUser_FullName_OnlyFirstName(t *testing.T) {
	u := models.User{FirstName: "Alice", LastName: ""}
	// FullName returns "Alice " (with trailing space) when only first name is set;
	// that is the current behaviour per the implementation.
	assert.Equal(t, "Alice ", u.FullName())
}

// ---- BaseModel tests ----

func TestBaseModel_IDDefaultsToNil(t *testing.T) {
	var b models.BaseModel
	assert.Equal(t, uuid.Nil, b.ID)
}

// ---- CompanyStatus tests ----

func TestCompanyStatus_Constants(t *testing.T) {
	assert.Equal(t, models.CompanyStatus("active"), models.CompanyStatusActive)
	assert.Equal(t, models.CompanyStatus("inactive"), models.CompanyStatusInactive)
	assert.Equal(t, models.CompanyStatus("suspended"), models.CompanyStatusSuspended)
}

// ---- TicketStatus / TicketPriority tests ----

func TestTicketStatus_Constants(t *testing.T) {
	assert.Equal(t, models.TicketStatus("open"), models.TicketStatusOpen)
	assert.Equal(t, models.TicketStatus("inProgress"), models.TicketStatusInProgress)
	assert.Equal(t, models.TicketStatus("resolved"), models.TicketStatusResolved)
	assert.Equal(t, models.TicketStatus("closed"), models.TicketStatusClosed)
}

func TestTicketPriority_Constants(t *testing.T) {
	assert.Equal(t, models.TicketPriority("low"), models.TicketPriorityLow)
	assert.Equal(t, models.TicketPriority("medium"), models.TicketPriorityMedium)
	assert.Equal(t, models.TicketPriority("high"), models.TicketPriorityHigh)
	assert.Equal(t, models.TicketPriority("urgent"), models.TicketPriorityUrgent)
}

// ---- NodeType tests ----

func TestNodeType_Constants(t *testing.T) {
	assert.Equal(t, models.NodeType("start"), models.NodeTypeStart)
	assert.Equal(t, models.NodeType("step"), models.NodeTypeStep)
	assert.Equal(t, models.NodeType("decision"), models.NodeTypeDecision)
	assert.Equal(t, models.NodeType("end"), models.NodeTypeEnd)
}

// ---- InstanceStatus / StepStatus tests ----

func TestInstanceStatus_Constants(t *testing.T) {
	assert.Equal(t, models.InstanceStatus("ACTIVE"), models.InstanceStatusActive)
	assert.Equal(t, models.InstanceStatus("COMPLETED"), models.InstanceStatusCompleted)
	assert.Equal(t, models.InstanceStatus("REJECTED"), models.InstanceStatusRejected)
	assert.Equal(t, models.InstanceStatus("CANCELLED"), models.InstanceStatusCancelled)
}

func TestStepStatus_Constants(t *testing.T) {
	assert.Equal(t, models.StepStatus("PENDING"), models.StepStatusPending)
	assert.Equal(t, models.StepStatus("COMPLETED"), models.StepStatusCompleted)
	assert.Equal(t, models.StepStatus("REJECTED"), models.StepStatusRejected)
}

// ---- Company model tests ----

func TestCompany_DefaultStatus(t *testing.T) {
	c := models.Company{
		Name:    "Acme",
		OwnerID: uuid.New(),
	}
	assert.Equal(t, models.CompanyStatus(""), c.Status) // zero value before DB sets default
}

// ---- Role model tests ----

func TestRole_DefaultLevel(t *testing.T) {
	r := models.Role{Name: "Member"}
	assert.Equal(t, "", r.Level) // zero value; DB default kicks in on insert
}

// ---- Ticket model ----

func TestTicket_FieldsInitializedCorrectly(t *testing.T) {
	cid := uuid.New()
	uid := uuid.New()
	t1 := models.Ticket{
		CompanyID: cid,
		Title:     "Test Ticket",
		Status:    models.TicketStatusOpen,
		Priority:  models.TicketPriorityHigh,
		CreatorID: uid,
	}
	assert.Equal(t, cid, t1.CompanyID)
	assert.Equal(t, "Test Ticket", t1.Title)
	assert.Equal(t, models.TicketStatusOpen, t1.Status)
	assert.Equal(t, models.TicketPriorityHigh, t1.Priority)
}

// ---- FlowNode model ----

func TestFlowNode_DefaultDimensions(t *testing.T) {
	// Struct zero value - layout constants are set at application level.
	n := models.FlowNode{
		Label: "Start",
		Type:  models.NodeTypeStart,
	}
	assert.Equal(t, models.NodeTypeStart, n.Type)
	assert.Equal(t, "Start", n.Label)
}

// ---- FlowEdge ----

func TestFlowEdge_Connectivity(t *testing.T) {
	src := uuid.New()
	tgt := uuid.New()
	e := models.FlowEdge{
		SourceNodeID: src,
		TargetNodeID: tgt,
		Label:        "approve",
	}
	assert.Equal(t, src, e.SourceNodeID)
	assert.Equal(t, tgt, e.TargetNodeID)
	assert.Equal(t, "approve", e.Label)
}
