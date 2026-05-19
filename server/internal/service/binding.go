package service

import (
	"context"
	"encoding/json"
	"fmt"
	"regexp"
	"strings"

	"github.com/autocreat/server/internal/dto"
	"github.com/autocreat/server/internal/models"
	"github.com/autocreat/server/internal/repository"
	"github.com/google/uuid"
)

type BindingService struct {
	repo       *repository.BindingRepository
	letterRepo *repository.LetterRepository
	modelRepo  *repository.ModelRepository
	flowRepo   *repository.FlowRepository
	formRepo   *repository.FormRepository
}

func NewBindingService(
	repo *repository.BindingRepository,
	letterRepo *repository.LetterRepository,
	modelRepo *repository.ModelRepository,
	flowRepo *repository.FlowRepository,
	formRepo *repository.FormRepository,
) *BindingService {
	return &BindingService{repo: repo, letterRepo: letterRepo, modelRepo: modelRepo, flowRepo: flowRepo, formRepo: formRepo}
}

// ---------- Form-Model Bindings ----------

func (s *BindingService) GetNodeBindings(ctx context.Context, nodeID uuid.UUID) ([]dto.FormModelBindingResponse, error) {
	bindings, err := s.repo.FindBindingsByNode(ctx, nodeID)
	if err != nil {
		return nil, err
	}
	result := make([]dto.FormModelBindingResponse, len(bindings))
	for i, b := range bindings {
		result[i] = toBindingResponse(&b)
	}
	return result, nil
}

func (s *BindingService) SaveBinding(ctx context.Context, nodeID uuid.UUID, req dto.SaveFormModelBindingRequest) (*dto.FormModelBindingResponse, error) {
	name := req.Name
	if name == "" {
		name = "Binding"
	}
	binding := &models.FormModelBinding{
		FlowNodeID: nodeID,
		Name:       name,
	}
	if req.ID != "" {
		if id, err := uuid.Parse(req.ID); err == nil {
			binding.ID = id
		}
	}
	if req.StoreAtNodeID != nil && *req.StoreAtNodeID != "" {
		if id, err := uuid.Parse(*req.StoreAtNodeID); err == nil {
			binding.StoreAtNodeID = &id
		}
	}

	rules := make([]models.FormModelBindingRule, 0, len(req.Rules))
	for _, rr := range req.Rules {
		modelDefID, err := uuid.Parse(rr.ModelDefinitionID)
		if err != nil {
			return nil, fmt.Errorf("invalid modelDefinitionId: %w", err)
		}
		instanceKey := rr.ModelInstanceKey
		if instanceKey == "" {
			instanceKey = "default"
		}
		rule := models.FormModelBindingRule{
			FormFieldKey:      rr.FormFieldKey,
			ModelDefinitionID: modelDefID,
			ModelInstanceKey:  instanceKey,
			ModelFieldKey:     rr.ModelFieldKey,
		}
		if rr.SourceNodeID != nil && *rr.SourceNodeID != "" {
			if id, err := uuid.Parse(*rr.SourceNodeID); err == nil {
				rule.SourceNodeID = &id
			}
		}
		rules = append(rules, rule)
	}

	if err := s.repo.SaveBinding(ctx, binding, rules); err != nil {
		return nil, err
	}

	saved, err := s.repo.FindBindingByID(ctx, binding.ID)
	if err != nil {
		return nil, err
	}
	resp := toBindingResponse(saved)
	return &resp, nil
}

func (s *BindingService) DeleteBinding(ctx context.Context, id uuid.UUID) error {
	return s.repo.DeleteBinding(ctx, id)
}

// ---------- Node Letter Assignments ----------

func (s *BindingService) GetNodeLetterAssignments(ctx context.Context, nodeID uuid.UUID) ([]dto.NodeLetterAssignmentResponse, error) {
	assignments, err := s.repo.FindLetterAssignmentsByNode(ctx, nodeID)
	if err != nil {
		return nil, err
	}
	result := make([]dto.NodeLetterAssignmentResponse, 0, len(assignments))
	for _, a := range assignments {
		resp, err := s.enrichLetterAssignment(ctx, &a)
		if err != nil {
			continue
		}
		result = append(result, *resp)
	}
	return result, nil
}

func (s *BindingService) SaveNodeLetterAssignment(ctx context.Context, nodeID uuid.UUID, req dto.SaveNodeLetterAssignmentRequest) (*dto.NodeLetterAssignmentResponse, error) {
	tmplID, err := uuid.Parse(req.LetterTemplateID)
	if err != nil {
		return nil, fmt.Errorf("invalid letterTemplateId: %w", err)
	}
	vbJSON, _ := json.Marshal(req.VariableBindings)

	a := &models.NodeLetterAssignment{
		FlowNodeID:            nodeID,
		LetterTemplateID:      tmplID,
		AutoGenerateOnApprove: req.AutoGenerateOnApprove,
		AllowBeforeApprove:    req.AllowBeforeApprove,
		VariableBindings:      string(vbJSON),
	}
	if req.ID != "" {
		if id, err := uuid.Parse(req.ID); err == nil {
			a.ID = id
		}
	}

	if err := s.repo.SaveLetterAssignment(ctx, a); err != nil {
		return nil, err
	}
	return s.enrichLetterAssignment(ctx, a)
}

func (s *BindingService) DeleteNodeLetterAssignment(ctx context.Context, id uuid.UUID) error {
	return s.repo.DeleteLetterAssignment(ctx, id)
}

func (s *BindingService) GetLetterAssignmentByID(ctx context.Context, id uuid.UUID) (*models.NodeLetterAssignment, error) {
	return s.repo.FindLetterAssignmentByID(ctx, id)
}

// ---------- Step Letter Generation ----------

// GenerateLetterForStep resolves variable values from form submissions and produces
// a generated letter, persisting it as a StepGeneratedLetter record.
func (s *BindingService) GenerateLetterForStep(
	ctx context.Context,
	instanceID, nodeID, stepID uuid.UUID,
	assignmentID uuid.UUID,
	userID uuid.UUID,
	trigger string,
) (*dto.StepGeneratedLetterResponse, error) {
	assignment, err := s.repo.FindLetterAssignmentByID(ctx, assignmentID)
	if err != nil {
		return nil, fmt.Errorf("assignment not found: %w", err)
	}

	tmpl, err := s.letterRepo.FindByID(ctx, assignment.LetterTemplateID)
	if err != nil {
		return nil, fmt.Errorf("letter template not found: %w", err)
	}

	// Collect all form submissions for this instance.
	submissions, err := s.repo.FindFormSubmissionsByInstance(ctx, instanceID)
	if err != nil {
		return nil, err
	}

	// Parse variable bindings.
	var vbMap map[string]dto.VariableBindingEntry
	if assignment.VariableBindings != "" && assignment.VariableBindings != "{}" {
		_ = json.Unmarshal([]byte(assignment.VariableBindings), &vbMap)
	}

	// Resolve each variable to its value from the submissions.
	vars := make(map[string]string)
	for varName, binding := range vbMap {
		val := resolveFieldFromSubmissions(submissions, binding.SourceNodeID, binding.FormFieldKey)
		if val != "" {
			vars[varName] = val
		}
	}

	// Substitute {{var}} placeholders.
	re := regexp.MustCompile(`\{\{(\w+)\}\}`)
	generated := re.ReplaceAllStringFunc(tmpl.Content, func(match string) string {
		key := strings.TrimFunc(match, func(r rune) bool { return r == '{' || r == '}' })
		if val, ok := vars[key]; ok {
			return val
		}
		return match
	})

	rec := &models.StepGeneratedLetter{
		FlowInstanceID:   instanceID,
		FlowNodeID:       nodeID,
		StepID:           stepID,
		AssignmentID:     assignmentID,
		LetterTemplateID: assignment.LetterTemplateID,
		GeneratedContent: generated,
		GeneratedByID:    userID,
		Trigger:          trigger,
	}
	if err := s.repo.CreateStepGeneratedLetter(ctx, rec); err != nil {
		return nil, err
	}

	if trigger == "" {
		trigger = "manual"
	}
	return &dto.StepGeneratedLetterResponse{
		ID:               rec.ID,
		AssignmentID:     assignmentID,
		LetterTemplateID: assignment.LetterTemplateID,
		LetterName:       tmpl.Name,
		GeneratedContent: generated,
		Trigger:          trigger,
		GeneratedByID:    userID,
		CreatedAt:        rec.CreatedAt,
	}, nil
}

func (s *BindingService) GetStepGeneratedLetters(ctx context.Context, instanceID, stepID uuid.UUID) ([]dto.StepGeneratedLetterResponse, error) {
	letters, err := s.repo.FindStepGeneratedLetters(ctx, instanceID, stepID)
	if err != nil {
		return nil, err
	}
	result := make([]dto.StepGeneratedLetterResponse, 0, len(letters))
	for _, l := range letters {
		tmpl, err := s.letterRepo.FindByID(ctx, l.LetterTemplateID)
		name := ""
		if err == nil && tmpl != nil {
			name = tmpl.Name
		}
		result = append(result, dto.StepGeneratedLetterResponse{
			ID:               l.ID,
			AssignmentID:     l.AssignmentID,
			LetterTemplateID: l.LetterTemplateID,
			LetterName:       name,
			GeneratedContent: l.GeneratedContent,
			Trigger:          l.Trigger,
			GeneratedByID:    l.GeneratedByID,
			CreatedAt:        l.CreatedAt,
		})
	}
	return result, nil
}

// ---------- Execution during AdvanceInstance ----------

// ExecuteBindingsForNode is called after a step is approved. It finds all
// FormModelBindings whose StoreAtNodeID matches nodeID (or is nil = current node),
// collects form field values from submissions, and creates ModelEntity records.
func (s *BindingService) ExecuteBindingsForNode(
	ctx context.Context,
	nodeID uuid.UUID,
	instanceID uuid.UUID,
	companyID uuid.UUID,
	userID uuid.UUID,
	currentFormData map[string]interface{},
	currentNodeID uuid.UUID,
) error {
	bindings, err := s.repo.FindBindingsByNode(ctx, nodeID)
	if err != nil {
		return err
	}
	if len(bindings) == 0 {
		return nil
	}

	// Collect all historical submissions for this instance.
	submissions, err := s.repo.FindFormSubmissionsByInstance(ctx, instanceID)
	if err != nil {
		return err
	}

	for _, binding := range bindings {
		// Only execute if this is the storage trigger node.
		if binding.StoreAtNodeID != nil && *binding.StoreAtNodeID != nodeID {
			continue
		}

		// Group rules by (modelDefinitionID, modelInstanceKey).
		type groupKey struct {
			ModelDefID  uuid.UUID
			InstanceKey string
		}
		groups := make(map[groupKey]map[string]interface{})

		for _, rule := range binding.Rules {
			var val interface{}
			if rule.SourceNodeID == nil || *rule.SourceNodeID == currentNodeID {
				// Use current form data.
				val = currentFormData[rule.FormFieldKey]
			} else {
				// Look up from historical submissions.
				valStr := resolveFieldFromSubmissions(submissions, func() *string {
					s := rule.SourceNodeID.String()
					return &s
				}(), rule.FormFieldKey)
				if valStr != "" {
					val = valStr
				}
			}
			if val == nil {
				continue
			}

			key := groupKey{ModelDefID: rule.ModelDefinitionID, InstanceKey: rule.ModelInstanceKey}
			if groups[key] == nil {
				groups[key] = make(map[string]interface{})
			}
			groups[key][rule.ModelFieldKey] = val
		}

		// Create a ModelEntity for each group.
		for key, data := range groups {
			dataJSON, _ := json.Marshal(data)
			entity := &models.ModelEntity{
				ModelDefinitionID: key.ModelDefID,
				CompanyID:         companyID,
				Data:              string(dataJSON),
				CreatedByID:       userID,
			}
			_ = s.modelRepo.CreateEntity(ctx, entity)
		}
	}
	return nil
}

// AutoGenerateLettersForNode generates all letters with AutoGenerateOnApprove=true.
func (s *BindingService) AutoGenerateLettersForNode(
	ctx context.Context,
	nodeID uuid.UUID,
	instanceID uuid.UUID,
	stepID uuid.UUID,
	userID uuid.UUID,
) {
	assignments, err := s.repo.FindLetterAssignmentsForNode(ctx, nodeID)
	if err != nil || len(assignments) == 0 {
		return
	}
	for _, a := range assignments {
		_, _ = s.GenerateLetterForStep(ctx, instanceID, nodeID, stepID, a.ID, userID, "after_approve")
	}
}

// GetAccessibleFormFields returns the current node + all ancestor nodes (BFS over
// reversed edges) that have a form assigned, together with their parsed form fields.
// The current node is always first in the result slice.
func (s *BindingService) GetAccessibleFormFields(ctx context.Context, nodeID uuid.UUID) ([]dto.AccessibleNodeFormFields, error) {
	node, err := s.flowRepo.FindNodeByID(ctx, nodeID)
	if err != nil {
		return nil, err
	}

	edges, err := s.flowRepo.FindEdgesByFlow(ctx, node.FlowID)
	if err != nil {
		return nil, err
	}

	// Build reverse adjacency map: target → []sources
	revAdj := make(map[uuid.UUID][]uuid.UUID, len(edges))
	for _, e := range edges {
		revAdj[e.TargetNodeID] = append(revAdj[e.TargetNodeID], e.SourceNodeID)
	}

	// BFS backward from nodeID to collect ordered node IDs (current first)
	visited := map[uuid.UUID]bool{nodeID: true}
	queue := []uuid.UUID{nodeID}
	var orderedIDs []uuid.UUID
	for len(queue) > 0 {
		curr := queue[0]
		queue = queue[1:]
		orderedIDs = append(orderedIDs, curr)
		for _, parent := range revAdj[curr] {
			if !visited[parent] {
				visited[parent] = true
				queue = append(queue, parent)
			}
		}
	}

	result := make([]dto.AccessibleNodeFormFields, 0, len(orderedIDs))
	for _, nid := range orderedIDs {
		n, err := s.flowRepo.FindNodeByID(ctx, nid)
		if err != nil || n.AssignedFormID == nil {
			continue
		}
		form, err := s.formRepo.FindByID(ctx, *n.AssignedFormID)
		if err != nil {
			continue
		}

		var rawFields []map[string]interface{}
		if form.Fields != "" && form.Fields != "[]" {
			_ = json.Unmarshal([]byte(form.Fields), &rawFields)
		}

		fields := make([]dto.AccessibleFormField, 0, len(rawFields))
		for _, f := range rawFields {
			key := fmt.Sprintf("%v", f["id"])
			label := fmt.Sprintf("%v", f["label"])
			if key == "" || key == "<nil>" {
				continue
			}
			if label == "" || label == "<nil>" {
				label = key
			}
			fields = append(fields, dto.AccessibleFormField{Key: key, Label: label})
		}
		if len(fields) == 0 {
			continue
		}

		result = append(result, dto.AccessibleNodeFormFields{
			NodeID:    nid,
			NodeLabel: n.Label,
			IsCurrent: nid == nodeID,
			FormID:    *n.AssignedFormID,
			FormName:  form.Name,
			Fields:    fields,
		})
	}
	return result, nil
}

// ---------- helpers ----------

func resolveFieldFromSubmissions(submissions []models.FormSubmission, sourceNodeID *string, fieldKey string) string {
	for _, sub := range submissions {
		if sourceNodeID != nil && *sourceNodeID != "" {
			nodeIDStr := sub.FlowNodeID.String()
			if nodeIDStr != *sourceNodeID {
				continue
			}
		}
		var data map[string]interface{}
		if sub.Data != "" && sub.Data != "{}" {
			if err := json.Unmarshal([]byte(sub.Data), &data); err == nil {
				if val, ok := data[fieldKey]; ok {
					return fmt.Sprintf("%v", val)
				}
			}
		}
	}
	return ""
}

func toBindingResponse(b *models.FormModelBinding) dto.FormModelBindingResponse {
	rules := make([]dto.FormModelBindingRuleResponse, len(b.Rules))
	for i, r := range b.Rules {
		rules[i] = dto.FormModelBindingRuleResponse{
			ID:                r.ID,
			BindingID:         r.BindingID,
			SourceNodeID:      r.SourceNodeID,
			FormFieldKey:      r.FormFieldKey,
			ModelDefinitionID: r.ModelDefinitionID,
			ModelInstanceKey:  r.ModelInstanceKey,
			ModelFieldKey:     r.ModelFieldKey,
		}
	}
	return dto.FormModelBindingResponse{
		ID:            b.ID,
		FlowNodeID:    b.FlowNodeID,
		Name:          b.Name,
		StoreAtNodeID: b.StoreAtNodeID,
		Rules:         rules,
		CreatedAt:     b.CreatedAt,
		UpdatedAt:     b.UpdatedAt,
	}
}

func (s *BindingService) enrichLetterAssignment(ctx context.Context, a *models.NodeLetterAssignment) (*dto.NodeLetterAssignmentResponse, error) {
	tmpl, err := s.letterRepo.FindByID(ctx, a.LetterTemplateID)
	if err != nil {
		return nil, err
	}
	var variables []string
	if tmpl.Variables != "" && tmpl.Variables != "[]" {
		_ = json.Unmarshal([]byte(tmpl.Variables), &variables)
	}

	var vbMap map[string]dto.VariableBindingEntry
	if a.VariableBindings != "" && a.VariableBindings != "{}" {
		_ = json.Unmarshal([]byte(a.VariableBindings), &vbMap)
	}
	if vbMap == nil {
		vbMap = map[string]dto.VariableBindingEntry{}
	}

	return &dto.NodeLetterAssignmentResponse{
		ID:                    a.ID,
		FlowNodeID:            a.FlowNodeID,
		LetterTemplateID:      a.LetterTemplateID,
		LetterName:            tmpl.Name,
		LetterVariables:       variables,
		AutoGenerateOnApprove: a.AutoGenerateOnApprove,
		AllowBeforeApprove:    a.AllowBeforeApprove,
		VariableBindings:      vbMap,
		CreatedAt:             a.CreatedAt,
		UpdatedAt:             a.UpdatedAt,
	}, nil
}
