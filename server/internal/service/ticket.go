package service

import (
	"context"
	"encoding/json"
	"time"

	"github.com/autocreat/server/internal/dto"
	"github.com/autocreat/server/internal/models"
	"github.com/autocreat/server/internal/repository"
	"github.com/google/uuid"
)

type TicketService struct {
	repo *repository.TicketRepository
	hub  *Hub
}

func NewTicketService(repo *repository.TicketRepository, hub *Hub) *TicketService {
	return &TicketService{repo: repo, hub: hub}
}

func (s *TicketService) Create(ctx context.Context, companyID, creatorID uuid.UUID, req dto.CreateTicketRequest) (*dto.TicketResponse, error) {
	priority := req.Priority
	if priority == "" {
		priority = models.TicketPriorityMedium
	}
	tagsJSON, _ := json.Marshal(req.Tags)

	ticket := &models.Ticket{
		CompanyID:   companyID,
		Title:       req.Title,
		Description: req.Description,
		FlowID:      req.FlowID,
		FlowNodeID:  req.FlowNodeID,
		Status:      models.TicketStatusOpen,
		Priority:    priority,
		Tags:        string(tagsJSON),
		CreatorID:   creatorID,
		AssigneeID:  req.AssigneeID,
		DueDate:     req.DueDate,
	}
	if err := s.repo.Create(ctx, ticket); err != nil {
		return nil, err
	}
	if ticket.CompanyID != uuid.Nil {
		s.hub.BroadcastToCompany(ticket.CompanyID, "ticket.created", ticket)
	}
	// Reload with Creator/Assignee/Messages preloaded so the response carries
	// creatorName/assigneeName like every other ticket endpoint.
	if full, err := s.repo.FindByID(ctx, ticket.ID); err == nil {
		return s.toTicketResponse(ctx, full), nil
	}
	return s.toTicketResponse(ctx, ticket), nil
}

type ListTicketsFilter struct {
	Status     string
	AssigneeID string
}

func (s *TicketService) List(ctx context.Context, companyID uuid.UUID, filter ListTicketsFilter) ([]dto.TicketResponse, error) {
	tickets, err := s.repo.FindByCompany(ctx, companyID, filter.Status, filter.AssigneeID)
	if err != nil {
		return nil, err
	}
	result := make([]dto.TicketResponse, len(tickets))
	for i, t := range tickets {
		result[i] = *s.toTicketResponse(ctx, &t)
	}
	return result, nil
}

func (s *TicketService) GetByID(ctx context.Context, id uuid.UUID) (*dto.TicketResponse, error) {
	ticket, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	return s.toTicketResponse(ctx, ticket), nil
}

func (s *TicketService) Update(ctx context.Context, id uuid.UUID, req dto.UpdateTicketRequest) (*dto.TicketResponse, error) {
	ticket, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if req.Title != "" {
		ticket.Title = req.Title
	}
	if req.Description != "" {
		ticket.Description = req.Description
	}
	if req.AssigneeID != nil {
		ticket.AssigneeID = req.AssigneeID
	}
	if req.Priority != "" {
		ticket.Priority = req.Priority
	}
	if req.Tags != nil {
		tagsJSON, _ := json.Marshal(req.Tags)
		ticket.Tags = string(tagsJSON)
	}
	if req.DueDate != nil {
		ticket.DueDate = req.DueDate
	}
	if req.IsRead != nil {
		ticket.IsRead = *req.IsRead
	}
	if err := s.repo.Update(ctx, ticket); err != nil {
		return nil, err
	}
	s.hub.BroadcastToCompany(ticket.CompanyID, "ticket.updated", ticket)
	return s.toTicketResponse(ctx, ticket), nil
}

func (s *TicketService) UpdateStatus(ctx context.Context, id uuid.UUID, req dto.UpdateTicketStatusRequest) (*dto.TicketResponse, error) {
	ticket, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	ticket.Status = req.Status
	if req.Status == models.TicketStatusResolved {
		now := time.Now()
		ticket.ResolvedAt = &now
	}
	if err := s.repo.Update(ctx, ticket); err != nil {
		return nil, err
	}
	s.hub.BroadcastToCompany(ticket.CompanyID, "ticket.status_updated", ticket)
	return s.toTicketResponse(ctx, ticket), nil
}

func (s *TicketService) SendMessage(ctx context.Context, ticketID, senderID uuid.UUID, req dto.SendTicketMessageRequest) (*dto.TicketMessageResponse, error) {
	attachmentsJSON, _ := json.Marshal(req.Attachments)
	msg := &models.TicketMessage{
		TicketID:    ticketID,
		SenderID:    senderID,
		Content:     req.Content,
		Attachments: string(attachmentsJSON),
	}
	if err := s.repo.CreateMessage(ctx, msg); err != nil {
		return nil, err
	}
	if t, err2 := s.repo.FindByID(ctx, ticketID); err2 == nil {
		s.hub.BroadcastToCompany(t.CompanyID, "ticket.message_sent", msg)
	}
	return s.toMessageResponse(msg, nil), nil
}

// ---------- helpers ----------

func (s *TicketService) toTicketResponse(ctx context.Context, t *models.Ticket) *dto.TicketResponse {
	var tags []string
	if t.Tags != "" && t.Tags != "[]" {
		_ = json.Unmarshal([]byte(t.Tags), &tags)
	}
	if tags == nil {
		tags = []string{}
	}

	creatorName := ""
	if t.Creator != nil {
		creatorName = t.Creator.FirstName + " " + t.Creator.LastName
	}

	assigneeName := ""
	if t.Assignee != nil {
		assigneeName = t.Assignee.FirstName + " " + t.Assignee.LastName
	}

	messages := make([]dto.TicketMessageResponse, len(t.Messages))
	for i, m := range t.Messages {
		messages[i] = *s.toMessageResponse(&m, m.Sender)
	}

	priority := t.Priority
	if priority == "" {
		priority = models.TicketPriorityMedium
	}

	return &dto.TicketResponse{
		ID:           t.ID,
		Title:        t.Title,
		Description:  t.Description,
		CompanyID:    t.CompanyID,
		FlowID:       t.FlowID,
		FlowNodeID:   t.FlowNodeID,
		CreatorID:    t.CreatorID,
		CreatorName:  creatorName,
		AssigneeID:   t.AssigneeID,
		AssigneeName: assigneeName,
		Status:       t.Status,
		Priority:     priority,
		Tags:         tags,
		Messages:     messages,
		MessageCount: len(messages),
		IsRead:       t.IsRead,
		DueDate:      t.DueDate,
		ResolvedAt:   t.ResolvedAt,
		CreatedAt:    t.CreatedAt,
		UpdatedAt:    t.UpdatedAt,
	}
}

func (s *TicketService) toMessageResponse(m *models.TicketMessage, sender *models.User) *dto.TicketMessageResponse {
	senderName := ""
	senderAvatar := ""
	if sender != nil {
		senderName = sender.FirstName + " " + sender.LastName
		senderAvatar = sender.Avatar
	}

	var attachments []string
	if m.Attachments != "" && m.Attachments != "[]" {
		_ = json.Unmarshal([]byte(m.Attachments), &attachments)
	}
	if attachments == nil {
		attachments = []string{}
	}

	return &dto.TicketMessageResponse{
		ID:           m.ID,
		TicketID:     m.TicketID,
		SenderID:     m.SenderID,
		SenderName:   senderName,
		SenderAvatar: senderAvatar,
		Content:      m.Content,
		Attachments:  attachments,
		IsSystem:     m.IsSystem,
		CreatedAt:    m.CreatedAt,
	}
}
