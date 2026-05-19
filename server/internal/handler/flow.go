package handler

import (
	"net/http"

	"github.com/autocreat/server/internal/dto"
	"github.com/autocreat/server/internal/middleware"
	"github.com/autocreat/server/internal/models"
	"github.com/autocreat/server/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type FlowHandler struct {
	svc *service.FlowService
}

func NewFlowHandler(svc *service.FlowService) *FlowHandler {
	return &FlowHandler{svc: svc}
}

// ---------- Flows ----------

func (h *FlowHandler) List(c *gin.Context) {
	cid := companyIDFromContext(c)
	if cid == uuid.Nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing companyId"})
		return
	}
	flows, err := h.svc.List(c.Request.Context(), cid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, flows)
}

func (h *FlowHandler) Create(c *gin.Context) {
	cid := companyIDFromContext(c)
	var req dto.CreateFlowRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	// Allow companyId from body for flat routes
	if cid == uuid.Nil && req.CompanyID != "" {
		if id, err := uuid.Parse(req.CompanyID); err == nil {
			cid = id
		}
	}
	if cid == uuid.Nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing companyId"})
		return
	}
	flow, err := h.svc.Create(c.Request.Context(), cid, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, flow)
}

func (h *FlowHandler) GetByID(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	flow, err := h.svc.GetByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "flow not found"})
		return
	}
	c.JSON(http.StatusOK, flow)
}

func (h *FlowHandler) Update(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	var req dto.UpdateFlowRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	flow, err := h.svc.Update(c.Request.Context(), id, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, flow)
}

func (h *FlowHandler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	if err := h.svc.Delete(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusNoContent, nil)
}

// ---------- Nodes ----------

func (h *FlowHandler) ListNodes(c *gin.Context) {
	flowID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid flow id"})
		return
	}
	nodes, err := h.svc.ListNodes(c.Request.Context(), flowID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	resp := make([]dto.FlowNodeResponse, len(nodes))
	for i, n := range nodes {
		resp[i] = dto.NodeFromModel(n)
	}
	c.JSON(http.StatusOK, resp)
}

func (h *FlowHandler) CreateNode(c *gin.Context) {
	flowID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid flow id"})
		return
	}
	var req dto.CreateNodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	node, err := h.svc.CreateNode(c.Request.Context(), flowID, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, dto.NodeFromModel(*node))
}

func (h *FlowHandler) UpdateNode(c *gin.Context) {
	nid, err := uuid.Parse(c.Param("nid"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid node id"})
		return
	}
	var req dto.UpdateNodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	node, err := h.svc.UpdateNode(c.Request.Context(), nid, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, dto.NodeFromModel(*node))
}

func (h *FlowHandler) DeleteNode(c *gin.Context) {
	nid, err := uuid.Parse(c.Param("nid"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid node id"})
		return
	}
	if err := h.svc.DeleteNode(c.Request.Context(), nid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusNoContent, nil)
}

// ---------- Edges ----------

func (h *FlowHandler) ListEdges(c *gin.Context) {
	flowID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid flow id"})
		return
	}
	edges, err := h.svc.ListEdges(c.Request.Context(), flowID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	resp := make([]dto.FlowEdgeResponse, len(edges))
	for i, e := range edges {
		resp[i] = dto.EdgeFromModel(e)
	}
	c.JSON(http.StatusOK, resp)
}

func (h *FlowHandler) CreateEdge(c *gin.Context) {
	flowID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid flow id"})
		return
	}
	var req dto.CreateEdgeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	edge, err := h.svc.CreateEdge(c.Request.Context(), flowID, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, dto.EdgeFromModel(*edge))
}

func (h *FlowHandler) DeleteEdge(c *gin.Context) {
	eid, err := uuid.Parse(c.Param("eid"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid edge id"})
		return
	}
	if err := h.svc.DeleteEdge(c.Request.Context(), eid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusNoContent, nil)
}

// ---------- SaveGraph ----------

func (h *FlowHandler) SaveGraph(c *gin.Context) {
	flowID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid flow id"})
		return
	}
	var req dto.SaveGraphRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	flow, err := h.svc.SaveGraph(c.Request.Context(), flowID, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, flow)
}

// ---------- Assignments ----------

func (h *FlowHandler) ListAssignments(c *gin.Context) {
	flowID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid flow id"})
		return
	}
	assignments, err := h.svc.ListAssignments(c.Request.Context(), flowID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, assignments)
}

func (h *FlowHandler) CreateAssignment(c *gin.Context) {
	flowID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid flow id"})
		return
	}
	var req dto.CreateAssignmentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	a, err := h.svc.CreateAssignment(c.Request.Context(), flowID, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, a)
}

func (h *FlowHandler) DeleteAssignment(c *gin.Context) {
	aid, err := uuid.Parse(c.Param("aid"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid assignment id"})
		return
	}
	if err := h.svc.DeleteAssignment(c.Request.Context(), aid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusNoContent, nil)
}

// ---------- Flow Instances ----------

func instanceToDTO(inst *models.FlowInstance) dto.FlowInstanceResponse {
	return dto.FlowInstanceResponse{
		ID:            inst.ID,
		FlowID:        inst.FlowID,
		CompanyID:     inst.CompanyID,
		CurrentNodeID: inst.CurrentNodeID,
		Status:        inst.Status,
		StartedByID:   inst.StartedByID,
		CreatedAt:     inst.CreatedAt,
		UpdatedAt:     inst.UpdatedAt,
	}
}

func instancesToDTO(instances []models.FlowInstance) []dto.FlowInstanceResponse {
	resp := make([]dto.FlowInstanceResponse, len(instances))
	for i := range instances {
		resp[i] = instanceToDTO(&instances[i])
	}
	return resp
}

func (h *FlowHandler) ListInstances(c *gin.Context) {
	cid := companyIDFromContext(c)
	if cid == uuid.Nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing companyId"})
		return
	}
	instances, err := h.svc.ListInstances(c.Request.Context(), cid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, instancesToDTO(instances))
}

func (h *FlowHandler) StartInstance(c *gin.Context) {
	cid := companyIDFromContext(c)
	if cid == uuid.Nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing companyId"})
		return
	}
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)
	var req dto.StartFlowRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	instance, err := h.svc.StartInstance(c.Request.Context(), cid, userID, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, instanceToDTO(instance))
}

func (h *FlowHandler) GetInstance(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	instance, err := h.svc.GetInstance(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "instance not found"})
		return
	}
	c.JSON(http.StatusOK, instanceToDTO(instance))
}

func (h *FlowHandler) AdvanceInstance(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	var req dto.AdvanceFlowRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	instance, err := h.svc.AdvanceInstance(c.Request.Context(), id, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, instanceToDTO(instance))
}

func (h *FlowHandler) RejectInstance(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	var req dto.RejectFlowRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	instance, err := h.svc.RejectInstance(c.Request.Context(), id, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, instanceToDTO(instance))
}

func (h *FlowHandler) GetMyTasks(c *gin.Context) {
	cid := companyIDFromContext(c)
	if cid == uuid.Nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing companyId"})
		return
	}
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)
	roleID := roleIDFromContext(c, h.svc, userID)
	tasks, err := h.svc.GetMyTasksFull(c.Request.Context(), cid, userID, roleID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, tasks)
}

func (h *FlowHandler) GetMyTasksFull(c *gin.Context) {
	cid := companyIDFromContext(c)
	if cid == uuid.Nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing companyId"})
		return
	}
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)
	roleID := roleIDFromContext(c, h.svc, userID)
	tasks, err := h.svc.GetMyTasksFull(c.Request.Context(), cid, userID, roleID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, tasks)
}

func (h *FlowHandler) GetTaskDetails(c *gin.Context) {
	cid := companyIDFromContext(c)
	if cid == uuid.Nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing companyId"})
		return
	}
	instanceIDStr := c.Query("instanceId")
	nodeIDStr := c.Query("nodeId")
	if instanceIDStr == "" || nodeIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "instanceId and nodeId query params required"})
		return
	}
	instanceID, err := uuid.Parse(instanceIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid instanceId"})
		return
	}
	nodeID, err := uuid.Parse(nodeIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid nodeId"})
		return
	}
	task, err := h.svc.GetTaskDetail(c.Request.Context(), cid, instanceID, nodeID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, task)
}

func (h *FlowHandler) GetUsersForRole(c *gin.Context) {
	roleID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid role id"})
		return
	}
	users, err := h.svc.GetUsersForRole(c.Request.Context(), roleID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, users)
}

func (h *FlowHandler) GetStartableFlows(c *gin.Context) {
	cid := companyIDFromContext(c)
	if cid == uuid.Nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing companyId"})
		return
	}
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)
	roleID := roleIDFromContext(c, h.svc, userID)
	flows, err := h.svc.GetStartableFlows(c.Request.Context(), cid, roleID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, flows)
}
