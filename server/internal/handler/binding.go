package handler

import (
	"net/http"

	"github.com/autocreat/server/internal/dto"
	"github.com/autocreat/server/internal/middleware"
	"github.com/autocreat/server/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type BindingHandler struct {
	svc *service.BindingService
}

func NewBindingHandler(svc *service.BindingService) *BindingHandler {
	return &BindingHandler{svc: svc}
}

// ---------- Form-Model Bindings ----------

// GET /nodes/:nodeId/bindings
func (h *BindingHandler) ListBindings(c *gin.Context) {
	nodeID, err := uuid.Parse(c.Param("nodeId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid nodeId"})
		return
	}
	result, err := h.svc.GetNodeBindings(c.Request.Context(), nodeID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, result)
}

// POST /nodes/:nodeId/bindings
func (h *BindingHandler) SaveBinding(c *gin.Context) {
	nodeID, err := uuid.Parse(c.Param("nodeId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid nodeId"})
		return
	}
	var req dto.SaveFormModelBindingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	result, err := h.svc.SaveBinding(c.Request.Context(), nodeID, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, result)
}

// DELETE /bindings/:id
func (h *BindingHandler) DeleteBinding(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	if err := h.svc.DeleteBinding(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusNoContent, nil)
}

// ---------- Node Letter Assignments ----------

// GET /nodes/:nodeId/letter-assignments
func (h *BindingHandler) ListLetterAssignments(c *gin.Context) {
	nodeID, err := uuid.Parse(c.Param("nodeId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid nodeId"})
		return
	}
	result, err := h.svc.GetNodeLetterAssignments(c.Request.Context(), nodeID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, result)
}

// POST /nodes/:nodeId/letter-assignments
func (h *BindingHandler) SaveLetterAssignment(c *gin.Context) {
	nodeID, err := uuid.Parse(c.Param("nodeId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid nodeId"})
		return
	}
	var req dto.SaveNodeLetterAssignmentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	result, err := h.svc.SaveNodeLetterAssignment(c.Request.Context(), nodeID, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, result)
}

// DELETE /letter-assignments/:id
func (h *BindingHandler) DeleteLetterAssignment(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	if err := h.svc.DeleteNodeLetterAssignment(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusNoContent, nil)
}

// ---------- Step Letter Generation ----------

// POST /instances/:instanceId/steps/:stepId/generate-letter
func (h *BindingHandler) GenerateStepLetter(c *gin.Context) {
	instanceID, err := uuid.Parse(c.Param("instanceId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid instanceId"})
		return
	}
	stepID, err := uuid.Parse(c.Param("stepId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid stepId"})
		return
	}
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	var req dto.GenerateStepLetterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	assignmentID, err := uuid.Parse(req.AssignmentID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid assignmentId"})
		return
	}

	// Resolve nodeID from the assignment.
	assignment, err := h.svc.GetLetterAssignmentByID(c.Request.Context(), assignmentID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "assignment not found"})
		return
	}

	trigger := req.Trigger
	if trigger == "" {
		trigger = "manual"
	}

	result, err := h.svc.GenerateLetterForStep(
		c.Request.Context(),
		instanceID,
		assignment.FlowNodeID,
		stepID,
		assignmentID,
		userID,
		trigger,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, result)
}

// GET /instances/:instanceId/steps/:stepId/generated-letters
func (h *BindingHandler) ListStepGeneratedLetters(c *gin.Context) {
	instanceID, err := uuid.Parse(c.Param("instanceId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid instanceId"})
		return
	}
	stepID, err := uuid.Parse(c.Param("stepId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid stepId"})
		return
	}
	result, err := h.svc.GetStepGeneratedLetters(c.Request.Context(), instanceID, stepID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, result)
}
