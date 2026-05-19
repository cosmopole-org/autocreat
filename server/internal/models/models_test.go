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

// ---- FormModelBinding ----

func TestFormModelBinding_DefaultName(t *testing.T) {
	nodeID := uuid.New()
	b := models.FormModelBinding{
		FlowNodeID: nodeID,
		Name:       "Binding",
	}
	assert.Equal(t, "Binding", b.Name)
	assert.Equal(t, nodeID, b.FlowNodeID)
	assert.Nil(t, b.StoreAtNodeID)
}

func TestFormModelBinding_WithStoreAtNodeID(t *testing.T) {
	nodeID := uuid.New()
	storeAt := uuid.New()
	b := models.FormModelBinding{
		FlowNodeID:    nodeID,
		Name:          "Deferred Binding",
		StoreAtNodeID: &storeAt,
	}
	assert.NotNil(t, b.StoreAtNodeID)
	assert.Equal(t, storeAt, *b.StoreAtNodeID)
}

func TestFormModelBindingRule_Fields(t *testing.T) {
	bindingID := uuid.New()
	modelDefID := uuid.New()
	r := models.FormModelBindingRule{
		BindingID:         bindingID,
		FormFieldKey:      "full_name",
		ModelDefinitionID: modelDefID,
		ModelInstanceKey:  "person_1",
		ModelFieldKey:     "name",
	}
	assert.Equal(t, "full_name", r.FormFieldKey)
	assert.Equal(t, "person_1", r.ModelInstanceKey)
	assert.Equal(t, "name", r.ModelFieldKey)
	assert.Nil(t, r.SourceNodeID)
}

func TestFormModelBindingRule_WithSourceNodeID(t *testing.T) {
	src := uuid.New()
	r := models.FormModelBindingRule{
		SourceNodeID: &src,
		FormFieldKey: "email",
	}
	assert.NotNil(t, r.SourceNodeID)
	assert.Equal(t, src, *r.SourceNodeID)
}

// ---- NodeLetterAssignment ----

func TestNodeLetterAssignment_Defaults(t *testing.T) {
	nodeID := uuid.New()
	tmplID := uuid.New()
	a := models.NodeLetterAssignment{
		FlowNodeID:            nodeID,
		LetterTemplateID:      tmplID,
		AutoGenerateOnApprove: false,
		AllowBeforeApprove:    true,
		VariableBindings:      "{}",
	}
	assert.False(t, a.AutoGenerateOnApprove)
	assert.True(t, a.AllowBeforeApprove)
	assert.Equal(t, "{}", a.VariableBindings)
}

func TestNodeLetterAssignment_AutoGenerate(t *testing.T) {
	a := models.NodeLetterAssignment{
		AutoGenerateOnApprove: true,
		AllowBeforeApprove:    false,
		VariableBindings:      `{"name":{"formFieldKey":"full_name"}}`,
	}
	assert.True(t, a.AutoGenerateOnApprove)
	assert.False(t, a.AllowBeforeApprove)
}

// ---- StepGeneratedLetter ----

func TestStepGeneratedLetter_TriggerValues(t *testing.T) {
	instanceID := uuid.New()
	nodeID := uuid.New()
	stepID := uuid.New()
	aID := uuid.New()
	tmplID := uuid.New()
	userID := uuid.New()

	for _, trigger := range []string{"manual", "before_approve", "after_approve"} {
		l := models.StepGeneratedLetter{
			FlowInstanceID:   instanceID,
			FlowNodeID:       nodeID,
			StepID:           stepID,
			AssignmentID:     aID,
			LetterTemplateID: tmplID,
			GeneratedContent: "Hello World",
			GeneratedByID:    userID,
			Trigger:          trigger,
		}
		assert.Equal(t, trigger, l.Trigger)
		assert.Equal(t, "Hello World", l.GeneratedContent)
	}
}

func TestStepGeneratedLetter_ZeroValue(t *testing.T) {
	var l models.StepGeneratedLetter
	assert.Equal(t, uuid.Nil, l.FlowInstanceID)
	assert.Equal(t, "", l.GeneratedContent)
	assert.Equal(t, "", l.Trigger)
}
