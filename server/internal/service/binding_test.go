package service_test

import (
	"encoding/json"
	"fmt"
	"regexp"
	"strings"
	"testing"

	"github.com/autocreat/server/internal/models"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

// ── resolveFieldFromSubmissions (extracted logic) ─────────────────────────────

// resolveField mirrors the package-private resolveFieldFromSubmissions function
// so we can test it inline without exporting it.
func resolveField(submissions []models.FormSubmission, sourceNodeID *string, fieldKey string) string {
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

func makeSubmission(nodeID uuid.UUID, data map[string]interface{}) models.FormSubmission {
	b, _ := json.Marshal(data)
	return models.FormSubmission{
		FlowNodeID: nodeID,
		Data:       string(b),
	}
}

func TestResolveField_BasicLookup(t *testing.T) {
	nodeID := uuid.New()
	sub := makeSubmission(nodeID, map[string]interface{}{"name": "Alice"})

	nodeStr := nodeID.String()
	result := resolveField([]models.FormSubmission{sub}, &nodeStr, "name")
	assert.Equal(t, "Alice", result)
}

func TestResolveField_WrongNode_ReturnsEmpty(t *testing.T) {
	nodeID := uuid.New()
	otherID := uuid.New()
	sub := makeSubmission(nodeID, map[string]interface{}{"name": "Alice"})

	otherStr := otherID.String()
	result := resolveField([]models.FormSubmission{sub}, &otherStr, "name")
	assert.Equal(t, "", result)
}

func TestResolveField_NilSourceNode_SearchesAll(t *testing.T) {
	nodeA := uuid.New()
	nodeB := uuid.New()
	subs := []models.FormSubmission{
		makeSubmission(nodeA, map[string]interface{}{"x": "from_a"}),
		makeSubmission(nodeB, map[string]interface{}{"y": "from_b"}),
	}
	// nil sourceNodeID means any node
	result := resolveField(subs, nil, "y")
	assert.Equal(t, "from_b", result)
}

func TestResolveField_MissingKey_ReturnsEmpty(t *testing.T) {
	nodeID := uuid.New()
	sub := makeSubmission(nodeID, map[string]interface{}{"name": "Alice"})

	nodeStr := nodeID.String()
	result := resolveField([]models.FormSubmission{sub}, &nodeStr, "nonexistent")
	assert.Equal(t, "", result)
}

func TestResolveField_EmptySubmissions_ReturnsEmpty(t *testing.T) {
	nodeStr := uuid.New().String()
	result := resolveField(nil, &nodeStr, "key")
	assert.Equal(t, "", result)
}

func TestResolveField_EmptyData_ReturnsEmpty(t *testing.T) {
	nodeID := uuid.New()
	sub := models.FormSubmission{FlowNodeID: nodeID, Data: "{}"}

	nodeStr := nodeID.String()
	result := resolveField([]models.FormSubmission{sub}, &nodeStr, "key")
	assert.Equal(t, "", result)
}

func TestResolveField_NumericValue_ConvertsToString(t *testing.T) {
	nodeID := uuid.New()
	sub := makeSubmission(nodeID, map[string]interface{}{"count": 42})

	nodeStr := nodeID.String()
	result := resolveField([]models.FormSubmission{sub}, &nodeStr, "count")
	assert.Equal(t, "42", result)
}

func TestResolveField_MultipleSubmissionsFirstMatchWins(t *testing.T) {
	nodeID := uuid.New()
	subs := []models.FormSubmission{
		makeSubmission(nodeID, map[string]interface{}{"name": "First"}),
		makeSubmission(nodeID, map[string]interface{}{"name": "Second"}),
	}
	nodeStr := nodeID.String()
	result := resolveField(subs, &nodeStr, "name")
	assert.Equal(t, "First", result)
}

// ── Variable substitution (used in GenerateLetterForStep) ────────────────────

// substituteVars mirrors the regex replacement logic in GenerateLetterForStep.
func substituteVars(template string, vars map[string]string) string {
	re := regexp.MustCompile(`\{\{(\w+)\}\}`)
	return re.ReplaceAllStringFunc(template, func(match string) string {
		key := strings.TrimFunc(match, func(r rune) bool { return r == '{' || r == '}' })
		if val, ok := vars[key]; ok {
			return val
		}
		return match
	})
}

func TestSubstituteVars_Basic(t *testing.T) {
	result := substituteVars("Hello {{name}}!", map[string]string{"name": "World"})
	assert.Equal(t, "Hello World!", result)
}

func TestSubstituteVars_MultipleVars(t *testing.T) {
	result := substituteVars(
		"Dear {{firstName}} {{lastName}}, your ref is {{ref}}.",
		map[string]string{"firstName": "Jane", "lastName": "Doe", "ref": "REF-999"},
	)
	assert.Equal(t, "Dear Jane Doe, your ref is REF-999.", result)
}

func TestSubstituteVars_MissingVar_Kept(t *testing.T) {
	result := substituteVars("Hello {{unknown}}!", map[string]string{})
	assert.Contains(t, result, "{{unknown}}")
}

func TestSubstituteVars_NoPlaceholders(t *testing.T) {
	result := substituteVars("Static content.", map[string]string{"x": "y"})
	assert.Equal(t, "Static content.", result)
}

func TestSubstituteVars_EmptyTemplate(t *testing.T) {
	result := substituteVars("", map[string]string{"a": "b"})
	assert.Equal(t, "", result)
}

func TestSubstituteVars_RepeatedVar(t *testing.T) {
	result := substituteVars("{{x}} and {{x}} again", map[string]string{"x": "foo"})
	assert.Equal(t, "foo and foo again", result)
}

// ── Binding grouping logic ────────────────────────────────────────────────────

type groupKey struct {
	ModelDefID  uuid.UUID
	InstanceKey string
}

// groupRules mirrors the grouping logic in ExecuteBindingsForNode so it can be
// tested without hitting the database.
func groupRules(
	rules []models.FormModelBindingRule,
	currentFormData map[string]interface{},
	currentNodeID uuid.UUID,
	submissions []models.FormSubmission,
) map[groupKey]map[string]interface{} {
	groups := make(map[groupKey]map[string]interface{})
	for _, rule := range rules {
		var val interface{}
		if rule.SourceNodeID == nil || *rule.SourceNodeID == currentNodeID {
			val = currentFormData[rule.FormFieldKey]
		} else {
			nodeStr := rule.SourceNodeID.String()
			valStr := resolveField(submissions, &nodeStr, rule.FormFieldKey)
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
	return groups
}

func TestGroupRules_CurrentNodeData(t *testing.T) {
	currentNode := uuid.New()
	modelDef := uuid.New()

	rules := []models.FormModelBindingRule{
		{
			FormFieldKey:      "fullName",
			ModelDefinitionID: modelDef,
			ModelInstanceKey:  "default",
			ModelFieldKey:     "name",
		},
	}
	formData := map[string]interface{}{"fullName": "Alice"}

	groups := groupRules(rules, formData, currentNode, nil)
	assert.Len(t, groups, 1)
	key := groupKey{ModelDefID: modelDef, InstanceKey: "default"}
	assert.Equal(t, "Alice", groups[key]["name"])
}

func TestGroupRules_CrossNodeData(t *testing.T) {
	currentNode := uuid.New()
	sourceNode := uuid.New()
	modelDef := uuid.New()

	subs := []models.FormSubmission{
		makeSubmission(sourceNode, map[string]interface{}{"email": "bob@example.com"}),
	}

	src := sourceNode
	rules := []models.FormModelBindingRule{
		{
			SourceNodeID:      &src,
			FormFieldKey:      "email",
			ModelDefinitionID: modelDef,
			ModelInstanceKey:  "default",
			ModelFieldKey:     "contactEmail",
		},
	}

	groups := groupRules(rules, nil, currentNode, subs)
	assert.Len(t, groups, 1)
	key := groupKey{ModelDefID: modelDef, InstanceKey: "default"}
	assert.Equal(t, "bob@example.com", groups[key]["contactEmail"])
}

func TestGroupRules_MultipleInstances_SameModel(t *testing.T) {
	currentNode := uuid.New()
	modelDef := uuid.New()

	rules := []models.FormModelBindingRule{
		{FormFieldKey: "name1", ModelDefinitionID: modelDef, ModelInstanceKey: "person_1", ModelFieldKey: "name"},
		{FormFieldKey: "name2", ModelDefinitionID: modelDef, ModelInstanceKey: "person_2", ModelFieldKey: "name"},
	}
	formData := map[string]interface{}{"name1": "Alice", "name2": "Bob"}

	groups := groupRules(rules, formData, currentNode, nil)
	assert.Len(t, groups, 2)
	assert.Equal(t, "Alice", groups[groupKey{modelDef, "person_1"}]["name"])
	assert.Equal(t, "Bob", groups[groupKey{modelDef, "person_2"}]["name"])
}

func TestGroupRules_MissingFormField_Skipped(t *testing.T) {
	currentNode := uuid.New()
	modelDef := uuid.New()

	rules := []models.FormModelBindingRule{
		{FormFieldKey: "missing", ModelDefinitionID: modelDef, ModelInstanceKey: "default", ModelFieldKey: "x"},
	}

	groups := groupRules(rules, map[string]interface{}{}, currentNode, nil)
	assert.Len(t, groups, 0)
}

func TestGroupRules_EmptyRules(t *testing.T) {
	groups := groupRules(nil, nil, uuid.New(), nil)
	assert.Len(t, groups, 0)
}
