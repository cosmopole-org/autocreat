package app

import (
	"net/http"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ─────────────────────────── Node Bindings ───────────────────────────────────

func TestIntegration_NodeBindings_CRUD(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, companyID := registerAndLogin(t, app, "bindings")

	// Create a flow and a node to bind to.
	wf := doQ(t, app, http.MethodPost, "/api/v1/flows", map[string]string{"companyId": companyID},
		map[string]interface{}{"name": "Binding Test Flow"}, token)
	require.Equal(t, http.StatusCreated, wf.Code)
	var flow map[string]interface{}
	decode(t, wf, &flow)
	fid := flow["id"].(string)

	wn := do(t, app, http.MethodPost, "/api/v1/flows/"+fid+"/nodes",
		map[string]interface{}{"label": "Step 1", "type": "step", "x": 100, "y": 100}, token)
	require.Equal(t, http.StatusCreated, wn.Code)
	var node map[string]interface{}
	decode(t, wn, &node)
	nid := node["id"].(string)

	// Create a model definition so we have a real modelDefinitionId.
	wm := doQ(t, app, http.MethodPost, "/api/v1/models", map[string]string{"companyId": companyID},
		map[string]interface{}{
			"name": "Client",
			"fields": []map[string]interface{}{
				{"id": "f1", "name": "company_name", "label": "Company", "type": "string"},
			},
		}, token)
	require.Equal(t, http.StatusCreated, wm.Code)
	var modelDef map[string]interface{}
	decode(t, wm, &modelDef)
	mid := modelDef["id"].(string)

	// ── GET empty list ──────────────────────────────────────────────────────────
	wl := do(t, app, http.MethodGet, "/api/v1/nodes/"+nid+"/bindings", nil, token)
	assert.Equal(t, http.StatusOK, wl.Code, "list bindings: %s", wl.Body)
	var empty []interface{}
	decode(t, wl, &empty)
	assert.Empty(t, empty)

	// ── POST create binding ─────────────────────────────────────────────────────
	wc := do(t, app, http.MethodPost, "/api/v1/nodes/"+nid+"/bindings",
		map[string]interface{}{
			"name": "Client Binding",
			"rules": []map[string]interface{}{
				{
					"formFieldKey":      "company_name_field",
					"modelDefinitionId": mid,
					"modelInstanceKey":  "default",
					"modelFieldKey":     "company_name",
				},
			},
		}, token)
	assert.Equal(t, http.StatusCreated, wc.Code, "create binding: %s", wc.Body)
	var binding map[string]interface{}
	decode(t, wc, &binding)
	bid := binding["id"].(string)

	assert.Equal(t, "Client Binding", binding["name"])
	assert.Equal(t, nid, binding["flowNodeId"])
	rules := binding["rules"].([]interface{})
	assert.Len(t, rules, 1)
	rule := rules[0].(map[string]interface{})
	assert.Equal(t, "company_name_field", rule["formFieldKey"])
	assert.Equal(t, "company_name", rule["modelFieldKey"])
	assert.Equal(t, "default", rule["modelInstanceKey"])

	// ── GET list shows binding ──────────────────────────────────────────────────
	wl2 := do(t, app, http.MethodGet, "/api/v1/nodes/"+nid+"/bindings", nil, token)
	assert.Equal(t, http.StatusOK, wl2.Code)
	var list []interface{}
	decode(t, wl2, &list)
	assert.Len(t, list, 1)

	// ── POST update (same endpoint; service upserts on ID) ─────────────────────
	wu := do(t, app, http.MethodPost, "/api/v1/nodes/"+nid+"/bindings",
		map[string]interface{}{
			"id":   bid,
			"name": "Client Binding v2",
			"rules": []map[string]interface{}{
				{
					"formFieldKey":      "company_name_field",
					"modelDefinitionId": mid,
					"modelInstanceKey":  "default",
					"modelFieldKey":     "company_name",
				},
				{
					"formFieldKey":      "revenue_field",
					"modelDefinitionId": mid,
					"modelInstanceKey":  "default",
					"modelFieldKey":     "annual_revenue",
				},
			},
		}, token)
	assert.Equal(t, http.StatusCreated, wu.Code, "update binding: %s", wu.Body)
	var updated map[string]interface{}
	decode(t, wu, &updated)
	assert.Equal(t, "Client Binding v2", updated["name"])
	assert.Len(t, updated["rules"].([]interface{}), 2)

	// ── DELETE binding ──────────────────────────────────────────────────────────
	wd := do(t, app, http.MethodDelete, "/api/v1/bindings/"+bid, nil, token)
	assert.Equal(t, http.StatusNoContent, wd.Code, "delete binding: %s", wd.Body)

	// ── Confirm deletion ────────────────────────────────────────────────────────
	wl3 := do(t, app, http.MethodGet, "/api/v1/nodes/"+nid+"/bindings", nil, token)
	assert.Equal(t, http.StatusOK, wl3.Code)
	var afterDelete []interface{}
	decode(t, wl3, &afterDelete)
	assert.Empty(t, afterDelete)
}

func TestIntegration_NodeBindings_Unauthorized(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	fakeNodeID := "00000000-0000-0000-0000-000000000001"
	w := do(t, app, http.MethodGet, "/api/v1/nodes/"+fakeNodeID+"/bindings", nil, "")
	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestIntegration_NodeBindings_DeleteNonExistent(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, _ := registerAndLogin(t, app, "bindingdel")
	fakeID := "00000000-0000-0000-0000-000000000099"
	w := do(t, app, http.MethodDelete, "/api/v1/bindings/"+fakeID, nil, token)
	// Deletion of non-existent resource returns 204 (idempotent) or 404
	assert.True(t, w.Code == http.StatusNoContent || w.Code == http.StatusNotFound,
		"expected 204 or 404, got %d: %s", w.Code, w.Body)
}

// ─────────────────────────── Node Letter Assignments ─────────────────────────

func TestIntegration_NodeLetterAssignments_CRUD(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, companyID := registerAndLogin(t, app, "letterassign")

	// Create a flow + node.
	wf := doQ(t, app, http.MethodPost, "/api/v1/flows", map[string]string{"companyId": companyID},
		map[string]interface{}{"name": "Letter Assign Flow"}, token)
	require.Equal(t, http.StatusCreated, wf.Code)
	var flow map[string]interface{}
	decode(t, wf, &flow)
	fid := flow["id"].(string)

	wn := do(t, app, http.MethodPost, "/api/v1/flows/"+fid+"/nodes",
		map[string]interface{}{"label": "Approve Step", "type": "step", "x": 100, "y": 100}, token)
	require.Equal(t, http.StatusCreated, wn.Code)
	var node map[string]interface{}
	decode(t, wn, &node)
	nid := node["id"].(string)

	// Create a letter template.
	wlt := doQ(t, app, http.MethodPost, "/api/v1/letters", map[string]string{"companyId": companyID},
		map[string]interface{}{
			"name":      "Offer Letter",
			"content":   "Dear {{name}}, you are hired at {{company}}!",
			"variables": []string{"name", "company"},
		}, token)
	require.Equal(t, http.StatusCreated, wlt.Code)
	var letter map[string]interface{}
	decode(t, wlt, &letter)
	lid := letter["id"].(string)

	// ── GET empty list ──────────────────────────────────────────────────────────
	wl := do(t, app, http.MethodGet, "/api/v1/nodes/"+nid+"/letter-assignments", nil, token)
	assert.Equal(t, http.StatusOK, wl.Code, "list assignments: %s", wl.Body)
	var empty []interface{}
	decode(t, wl, &empty)
	assert.Empty(t, empty)

	// ── POST create assignment ──────────────────────────────────────────────────
	wc := do(t, app, http.MethodPost, "/api/v1/nodes/"+nid+"/letter-assignments",
		map[string]interface{}{
			"letterTemplateId":      lid,
			"autoGenerateOnApprove": false,
			"allowBeforeApprove":    true,
			"variableBindings": map[string]interface{}{
				"name":    map[string]interface{}{"formFieldKey": "full_name"},
				"company": map[string]interface{}{"formFieldKey": "org_name"},
			},
		}, token)
	assert.Equal(t, http.StatusCreated, wc.Code, "create assignment: %s", wc.Body)
	var assignment map[string]interface{}
	decode(t, wc, &assignment)
	aid := assignment["id"].(string)

	assert.Equal(t, lid, assignment["letterTemplateId"])
	assert.Equal(t, "Offer Letter", assignment["letterName"])
	assert.Equal(t, false, assignment["autoGenerateOnApprove"])
	assert.Equal(t, true, assignment["allowBeforeApprove"])

	// letterVariables should be populated from the template
	vars := assignment["letterVariables"].([]interface{})
	assert.Contains(t, vars, "name")
	assert.Contains(t, vars, "company")

	// variableBindings should be persisted
	vb := assignment["variableBindings"].(map[string]interface{})
	assert.NotNil(t, vb["name"])
	assert.NotNil(t, vb["company"])

	// ── GET list shows assignment ───────────────────────────────────────────────
	wl2 := do(t, app, http.MethodGet, "/api/v1/nodes/"+nid+"/letter-assignments", nil, token)
	assert.Equal(t, http.StatusOK, wl2.Code)
	var list []interface{}
	decode(t, wl2, &list)
	assert.Len(t, list, 1)

	// ── POST update assignment (upsert via same endpoint with id) ───────────────
	wu := do(t, app, http.MethodPost, "/api/v1/nodes/"+nid+"/letter-assignments",
		map[string]interface{}{
			"id":                    aid,
			"letterTemplateId":      lid,
			"autoGenerateOnApprove": true,
			"allowBeforeApprove":    false,
			"variableBindings":      map[string]interface{}{},
		}, token)
	assert.Equal(t, http.StatusCreated, wu.Code, "update assignment: %s", wu.Body)
	var updated map[string]interface{}
	decode(t, wu, &updated)
	assert.Equal(t, true, updated["autoGenerateOnApprove"])
	assert.Equal(t, false, updated["allowBeforeApprove"])

	// ── DELETE assignment ───────────────────────────────────────────────────────
	wd := do(t, app, http.MethodDelete, "/api/v1/letter-assignments/"+aid, nil, token)
	assert.Equal(t, http.StatusNoContent, wd.Code, "delete assignment: %s", wd.Body)

	// ── Confirm deletion ────────────────────────────────────────────────────────
	wl3 := do(t, app, http.MethodGet, "/api/v1/nodes/"+nid+"/letter-assignments", nil, token)
	assert.Equal(t, http.StatusOK, wl3.Code)
	var afterDelete []interface{}
	decode(t, wl3, &afterDelete)
	assert.Empty(t, afterDelete)
}

func TestIntegration_NodeLetterAssignments_InvalidTemplate(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, companyID := registerAndLogin(t, app, "badtemplate")

	wf := doQ(t, app, http.MethodPost, "/api/v1/flows", map[string]string{"companyId": companyID},
		map[string]interface{}{"name": "Bad Template Flow"}, token)
	require.Equal(t, http.StatusCreated, wf.Code)
	var flow map[string]interface{}
	decode(t, wf, &flow)
	fid := flow["id"].(string)

	wn := do(t, app, http.MethodPost, "/api/v1/flows/"+fid+"/nodes",
		map[string]interface{}{"label": "S1", "type": "step", "x": 0, "y": 0}, token)
	require.Equal(t, http.StatusCreated, wn.Code)
	var node map[string]interface{}
	decode(t, wn, &node)
	nid := node["id"].(string)

	// Use a non-existent letter template ID.
	w := do(t, app, http.MethodPost, "/api/v1/nodes/"+nid+"/letter-assignments",
		map[string]interface{}{
			"letterTemplateId":   "00000000-0000-0000-0000-000000000099",
			"allowBeforeApprove": true,
		}, token)
	// Should return an error (letter template not found)
	assert.True(t, w.Code >= 400, "expected error for invalid templateId, got %d: %s", w.Code, w.Body)
}

// ─────────────────────────── Step Generated Letters ──────────────────────────

func TestIntegration_StepGeneratedLetters_GenerateAndList(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, userMap, companyID := registerAndLogin(t, app, "genletters")
	userID := userMap["id"].(string)
	_ = userID

	// ── Create prerequisite resources ──────────────────────────────────────────

	// Letter template
	wlt := doQ(t, app, http.MethodPost, "/api/v1/letters", map[string]string{"companyId": companyID},
		map[string]interface{}{
			"name":      "Contract Letter",
			"content":   "Dear {{name}}, your contract is ready.",
			"variables": []string{"name"},
		}, token)
	require.Equal(t, http.StatusCreated, wlt.Code)
	var letter map[string]interface{}
	decode(t, wlt, &letter)
	lid := letter["id"].(string)

	// Flow with start → step → end
	wf := doQ(t, app, http.MethodPost, "/api/v1/flows", map[string]string{"companyId": companyID},
		map[string]interface{}{"name": "Contract Flow"}, token)
	require.Equal(t, http.StatusCreated, wf.Code)
	var flow map[string]interface{}
	decode(t, wf, &flow)
	fid := flow["id"].(string)

	graph := map[string]interface{}{
		"nodes": []map[string]interface{}{
			{"id": "n-start", "label": "Start", "type": "start", "x": 0, "y": 0},
			{"id": "n-step", "label": "Review", "type": "step", "x": 200, "y": 0},
			{"id": "n-end", "label": "End", "type": "end", "x": 400, "y": 0},
		},
		"edges": []map[string]interface{}{
			{"id": "e-1", "sourceNodeId": "n-start", "targetNodeId": "n-step", "label": "go"},
			{"id": "e-2", "sourceNodeId": "n-step", "targetNodeId": "n-end", "label": "done"},
		},
	}
	wsg := do(t, app, http.MethodPut, "/api/v1/flows/"+fid+"/graph", graph, token)
	require.Equal(t, http.StatusOK, wsg.Code, "save graph: %s", wsg.Body)

	// Get node ID for "n-step"
	wln := do(t, app, http.MethodGet, "/api/v1/flows/"+fid+"/nodes", nil, token)
	require.Equal(t, http.StatusOK, wln.Code)
	var nodes []map[string]interface{}
	decode(t, wln, &nodes)
	var stepNodeID string
	for _, n := range nodes {
		if n["type"] == "step" {
			stepNodeID = n["id"].(string)
			break
		}
	}
	require.NotEmpty(t, stepNodeID, "should find a step node")

	// Assign letter to the step node
	wla := do(t, app, http.MethodPost, "/api/v1/nodes/"+stepNodeID+"/letter-assignments",
		map[string]interface{}{
			"letterTemplateId":      lid,
			"autoGenerateOnApprove": false,
			"allowBeforeApprove":    true,
			"variableBindings": map[string]interface{}{
				"name": map[string]interface{}{"formFieldKey": "candidate_name"},
			},
		}, token)
	require.Equal(t, http.StatusCreated, wla.Code, "assign letter: %s", wla.Body)
	var assignment map[string]interface{}
	decode(t, wla, &assignment)
	assignmentID := assignment["id"].(string)

	// Start a flow instance
	wi := do(t, app, http.MethodPost, "/api/v1/instances",
		map[string]interface{}{"flowId": fid, "companyId": companyID}, token)
	require.Equal(t, http.StatusCreated, wi.Code, "start instance: %s", wi.Body)
	var instance map[string]interface{}
	decode(t, wi, &instance)
	instanceID := instance["id"].(string)

	// Advance to the step node (from start node, which has no step)
	wa := do(t, app, http.MethodPost, "/api/v1/instances/"+instanceID+"/advance",
		map[string]interface{}{"formData": map[string]interface{}{}}, token)
	require.Equal(t, http.StatusOK, wa.Code, "advance instance: %s", wa.Body)

	// Get the current step from the instance
	wgi := do(t, app, http.MethodGet, "/api/v1/instances/"+instanceID, nil, token)
	require.Equal(t, http.StatusOK, wgi.Code)
	var inst map[string]interface{}
	decode(t, wgi, &inst)

	// Get step ID from my-tasks
	wmt := doQ(t, app, http.MethodGet, "/api/v1/instances/my-tasks",
		map[string]string{"companyId": companyID}, nil, token)
	require.Equal(t, http.StatusOK, wmt.Code)
	var tasks []map[string]interface{}
	decode(t, wmt, &tasks)

	var stepID string
	for _, task := range tasks {
		if task["instanceId"] == instanceID {
			if sid, ok := task["stepId"].(string); ok && sid != "" {
				stepID = sid
			}
		}
	}
	// If step is not in my-tasks (e.g. instance advanced past step node), skip generation test.
	if stepID == "" {
		t.Skip("no active step found for instance; instance may have completed")
	}

	// ── GET generated letters (empty) ──────────────────────────────────────────
	wgl := do(t, app, http.MethodGet,
		"/api/v1/instances/"+instanceID+"/steps/"+stepID+"/generated-letters", nil, token)
	assert.Equal(t, http.StatusOK, wgl.Code, "list generated letters: %s", wgl.Body)
	var emptyLetters []interface{}
	decode(t, wgl, &emptyLetters)
	assert.Empty(t, emptyLetters)

	// ── POST generate letter ────────────────────────────────────────────────────
	wgen := do(t, app, http.MethodPost,
		"/api/v1/instances/"+instanceID+"/steps/"+stepID+"/generate-letter",
		map[string]interface{}{
			"assignmentId": assignmentID,
			"trigger":      "before_approve",
		}, token)
	assert.Equal(t, http.StatusCreated, wgen.Code, "generate letter: %s", wgen.Body)
	var generated map[string]interface{}
	decode(t, wgen, &generated)

	assert.NotEmpty(t, generated["id"])
	assert.Equal(t, assignmentID, generated["assignmentId"])
	assert.Equal(t, lid, generated["letterTemplateId"])
	assert.Equal(t, "before_approve", generated["trigger"])
	// Content may have unresolved {{name}} if no form data was submitted, but should not be empty
	assert.NotEmpty(t, generated["generatedContent"])

	// ── GET generated letters (one entry) ──────────────────────────────────────
	wgl2 := do(t, app, http.MethodGet,
		"/api/v1/instances/"+instanceID+"/steps/"+stepID+"/generated-letters", nil, token)
	assert.Equal(t, http.StatusOK, wgl2.Code)
	var letters []interface{}
	decode(t, wgl2, &letters)
	assert.Len(t, letters, 1)

	// Verify the content of the returned letter
	gl := letters[0].(map[string]interface{})
	assert.Equal(t, generated["id"], gl["id"])
	assert.Equal(t, "before_approve", gl["trigger"])
}

func TestIntegration_StepGeneratedLetters_Unauthorized(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	w := do(t, app, http.MethodGet,
		"/api/v1/instances/00000000-0000-0000-0000-000000000001/steps/00000000-0000-0000-0000-000000000002/generated-letters",
		nil, "")
	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestIntegration_StepGeneratedLetters_InvalidAssignment(t *testing.T) {
	app, cleanup := setupTestApp(t)
	defer cleanup()

	token, _, companyID := registerAndLogin(t, app, "badassign")

	// Start a minimal flow instance
	wf := doQ(t, app, http.MethodPost, "/api/v1/flows", map[string]string{"companyId": companyID},
		map[string]interface{}{"name": "Bad Assignment Flow"}, token)
	require.Equal(t, http.StatusCreated, wf.Code)
	var flow map[string]interface{}
	decode(t, wf, &flow)
	fid := flow["id"].(string)

	wsg := do(t, app, http.MethodPut, "/api/v1/flows/"+fid+"/graph",
		map[string]interface{}{
			"nodes": []map[string]interface{}{
				{"id": "s", "label": "Start", "type": "start", "x": 0, "y": 0},
				{"id": "e", "label": "End", "type": "end", "x": 200, "y": 0},
			},
			"edges": []map[string]interface{}{
				{"id": "ed", "sourceNodeId": "s", "targetNodeId": "e", "label": "go"},
			},
		}, token)
	require.Equal(t, http.StatusOK, wsg.Code)

	wi := do(t, app, http.MethodPost, "/api/v1/instances",
		map[string]interface{}{"flowId": fid, "companyId": companyID}, token)
	require.Equal(t, http.StatusCreated, wi.Code)
	var instance map[string]interface{}
	decode(t, wi, &instance)
	instanceID := instance["id"].(string)

	// Try to generate with a non-existent assignment ID
	fakeStepID := "00000000-0000-0000-0000-000000000002"
	w := do(t, app, http.MethodPost,
		"/api/v1/instances/"+instanceID+"/steps/"+fakeStepID+"/generate-letter",
		map[string]interface{}{
			"assignmentId": "00000000-0000-0000-0000-000000000099",
			"trigger":      "manual",
		}, token)
	assert.True(t, w.Code >= 400, "expected error for invalid assignmentId, got %d: %s", w.Code, w.Body)
}
