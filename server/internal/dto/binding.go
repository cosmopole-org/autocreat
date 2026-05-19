package dto

import (
	"time"

	"github.com/google/uuid"
)

// ---------- Form-Model Bindings ----------

type FormModelBindingRuleRequest struct {
	SourceNodeID      *string `json:"sourceNodeId"`
	FormFieldKey      string  `json:"formFieldKey" binding:"required"`
	ModelDefinitionID string  `json:"modelDefinitionId" binding:"required"`
	ModelInstanceKey  string  `json:"modelInstanceKey"`
	ModelFieldKey     string  `json:"modelFieldKey" binding:"required"`
}

type SaveFormModelBindingRequest struct {
	// If ID is provided and non-empty, the existing binding is updated.
	ID            string                        `json:"id"`
	Name          string                        `json:"name"`
	StoreAtNodeID *string                       `json:"storeAtNodeId"`
	Rules         []FormModelBindingRuleRequest `json:"rules"`
}

type FormModelBindingRuleResponse struct {
	ID                uuid.UUID  `json:"id"`
	BindingID         uuid.UUID  `json:"bindingId"`
	SourceNodeID      *uuid.UUID `json:"sourceNodeId"`
	FormFieldKey      string     `json:"formFieldKey"`
	ModelDefinitionID uuid.UUID  `json:"modelDefinitionId"`
	ModelInstanceKey  string     `json:"modelInstanceKey"`
	ModelFieldKey     string     `json:"modelFieldKey"`
}

type FormModelBindingResponse struct {
	ID            uuid.UUID                      `json:"id"`
	FlowNodeID    uuid.UUID                      `json:"flowNodeId"`
	Name          string                         `json:"name"`
	StoreAtNodeID *uuid.UUID                     `json:"storeAtNodeId"`
	Rules         []FormModelBindingRuleResponse `json:"rules"`
	CreatedAt     time.Time                      `json:"createdAt"`
	UpdatedAt     time.Time                      `json:"updatedAt"`
}

// ---------- Node Letter Assignments ----------

type VariableBindingEntry struct {
	SourceNodeID *string `json:"sourceNodeId"`
	FormFieldKey string  `json:"formFieldKey"`
}

type SaveNodeLetterAssignmentRequest struct {
	// If ID is provided, the existing assignment is updated; otherwise created.
	ID                    string                          `json:"id"`
	LetterTemplateID      string                          `json:"letterTemplateId" binding:"required"`
	AutoGenerateOnApprove bool                            `json:"autoGenerateOnApprove"`
	AllowBeforeApprove    bool                            `json:"allowBeforeApprove"`
	VariableBindings      map[string]VariableBindingEntry `json:"variableBindings"`
}

type NodeLetterAssignmentResponse struct {
	ID                    uuid.UUID                       `json:"id"`
	FlowNodeID            uuid.UUID                       `json:"flowNodeId"`
	LetterTemplateID      uuid.UUID                       `json:"letterTemplateId"`
	LetterName            string                          `json:"letterName"`
	LetterVariables       []string                        `json:"letterVariables"`
	AutoGenerateOnApprove bool                            `json:"autoGenerateOnApprove"`
	AllowBeforeApprove    bool                            `json:"allowBeforeApprove"`
	VariableBindings      map[string]VariableBindingEntry `json:"variableBindings"`
	CreatedAt             time.Time                       `json:"createdAt"`
	UpdatedAt             time.Time                       `json:"updatedAt"`
}

// ---------- Step Letter Generation ----------

type GenerateStepLetterRequest struct {
	AssignmentID string `json:"assignmentId" binding:"required"`
	Trigger      string `json:"trigger"` // "before_approve" | "after_approve" | "manual"
}

type StepGeneratedLetterResponse struct {
	ID               uuid.UUID `json:"id"`
	AssignmentID     uuid.UUID `json:"assignmentId"`
	LetterTemplateID uuid.UUID `json:"letterTemplateId"`
	LetterName       string    `json:"letterName"`
	GeneratedContent string    `json:"generatedContent"`
	Trigger          string    `json:"trigger"`
	GeneratedByID    uuid.UUID `json:"generatedById"`
	CreatedAt        time.Time `json:"createdAt"`
}
