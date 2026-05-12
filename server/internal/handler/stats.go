package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type StatsHandler struct {
	db *gorm.DB
}

func NewStatsHandler(db *gorm.DB) *StatsHandler {
	return &StatsHandler{db: db}
}

type StatsResponse struct {
	TotalUsers         int64 `json:"total_users"`
	TotalFlows         int64 `json:"total_flows"`
	ActiveInstances    int64 `json:"active_instances"`
	TotalTickets       int64 `json:"total_tickets"`
	OpenTickets        int64 `json:"open_tickets"`
	TotalForms         int64 `json:"total_forms"`
	TotalModels        int64 `json:"total_models"`
	TotalLetterTemplates int64 `json:"total_letter_templates"`
}

func (h *StatsHandler) GetStats(c *gin.Context) {
	cid := c.MustGet("routeCompanyID").(uuid.UUID)
	ctx := c.Request.Context()

	var stats StatsResponse

	h.db.WithContext(ctx).Table("users").Where("company_id = ?", cid).Count(&stats.TotalUsers)
	h.db.WithContext(ctx).Table("flows").Where("company_id = ?", cid).Count(&stats.TotalFlows)
	h.db.WithContext(ctx).Table("flow_instances").Where("company_id = ? AND status = 'ACTIVE'", cid).Count(&stats.ActiveInstances)
	h.db.WithContext(ctx).Table("tickets").Where("company_id = ?", cid).Count(&stats.TotalTickets)
	h.db.WithContext(ctx).Table("tickets").Where("company_id = ? AND status = 'OPEN'", cid).Count(&stats.OpenTickets)
	h.db.WithContext(ctx).Table("form_definitions").Where("company_id = ?", cid).Count(&stats.TotalForms)
	h.db.WithContext(ctx).Table("model_definitions").Where("company_id = ?", cid).Count(&stats.TotalModels)
	h.db.WithContext(ctx).Table("letter_templates").Where("company_id = ?", cid).Count(&stats.TotalLetterTemplates)

	c.JSON(http.StatusOK, stats)
}
