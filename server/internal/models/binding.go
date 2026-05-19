package models

import "github.com/google/uuid"

// FormModelBinding is a named group of form-field→model-field mappings for a node.
// When the node's task is approved, these rules are executed to persist model entities.
type FormModelBinding struct {
	BaseModel
	FlowNodeID    uuid.UUID  `gorm:"type:uuid;not null;index" json:"flowNodeId"`
	Name          string     `gorm:"not null;default:'Binding'" json:"name"`
	// StoreAtNodeID: nil means "store immediately when this node's task is approved".
	// Set to another node's ID to defer storage until that node is reached.
	StoreAtNodeID *uuid.UUID `gorm:"type:uuid" json:"storeAtNodeId"`

	Rules []FormModelBindingRule `gorm:"foreignKey:BindingID;constraint:OnDelete:CASCADE" json:"rules"`
}

// FormModelBindingRule maps a single form field to a single model field in a named instance.
type FormModelBindingRule struct {
	BaseModel
	BindingID         uuid.UUID  `gorm:"type:uuid;not null;index" json:"bindingId"`
	// SourceNodeID: nil means the current node's form. Otherwise references another node.
	SourceNodeID      *uuid.UUID `gorm:"type:uuid" json:"sourceNodeId"`
	FormFieldKey      string     `gorm:"not null" json:"formFieldKey"`
	ModelDefinitionID uuid.UUID  `gorm:"type:uuid;not null" json:"modelDefinitionId"`
	// ModelInstanceKey allows multiple instances of the same model (e.g. "person_1", "person_2").
	ModelInstanceKey  string     `gorm:"not null;default:'default'" json:"modelInstanceKey"`
	ModelFieldKey     string     `gorm:"not null" json:"modelFieldKey"`
}

// NodeLetterAssignment links a letter template to a flow node with generation settings.
type NodeLetterAssignment struct {
	BaseModel
	FlowNodeID            uuid.UUID `gorm:"type:uuid;not null;index" json:"flowNodeId"`
	LetterTemplateID      uuid.UUID `gorm:"type:uuid;not null" json:"letterTemplateId"`
	AutoGenerateOnApprove bool      `gorm:"default:false" json:"autoGenerateOnApprove"`
	AllowBeforeApprove    bool      `gorm:"default:true" json:"allowBeforeApprove"`
	// VariableBindings: JSON object mapping variable name →
	// { "sourceNodeId": "<uuid or null>", "formFieldKey": "<key>" }
	VariableBindings string `gorm:"type:jsonb;default:'{}'" json:"variableBindings"`
}

// StepGeneratedLetter records a letter generated in the context of a task step.
type StepGeneratedLetter struct {
	BaseModel
	FlowInstanceID   uuid.UUID `gorm:"type:uuid;not null;index" json:"flowInstanceId"`
	FlowNodeID       uuid.UUID `gorm:"type:uuid;not null" json:"flowNodeId"`
	StepID           uuid.UUID `gorm:"type:uuid;not null" json:"stepId"`
	AssignmentID     uuid.UUID `gorm:"type:uuid;not null" json:"assignmentId"`
	LetterTemplateID uuid.UUID `gorm:"type:uuid;not null" json:"letterTemplateId"`
	GeneratedContent string    `gorm:"type:text" json:"generatedContent"`
	GeneratedByID    uuid.UUID `gorm:"type:uuid;not null" json:"generatedById"`
	// Trigger: "before_approve" | "after_approve" | "manual"
	Trigger string `gorm:"not null;default:'manual'" json:"trigger"`
}
