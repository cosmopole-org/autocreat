package service

import (
	"context"
	"fmt"

	"github.com/autocreat/server/internal/dto"
	"github.com/autocreat/server/internal/models"
	"github.com/autocreat/server/internal/repository"
	"github.com/google/uuid"
	"gorm.io/datatypes"
)

type TicketService struct {
	repo *repository.TicketRepository
	hub  *Hub
}

func NewTicketService(repo *repository.TicketRepository, hub *Hub) *TicketService {
	return &TicketService{repo: repo, hub: hub}
}

func (s *TicketService) Create(ctx context.Context, companyID, creatorID uuid.UUID, req dto.CreateTicketRequest) (*models.Ticket, error) {
	ticket := &models.Ticket{
		CompanyID:      companyID,
		SubjectTitle:   req.SubjectTitle,
		Status:         models.TicketStatusOpen,
		CreatorID:      creatorID,
		AssignedToID:   req.AssignedToID,
		FlowInstanceID: req.FlowInstanceID,
	}
	if err := s.repo.Create(ctx, ticket); err != nil {
		return nil, err
	}
	if ticket.CompanyID != uuid.Nil {
		s.hub.BroadcastToCompany(ticket.CompanyID, "ticket.created", ticket)
	}
	return ticket, nil
}

func (s *TicketService) List(ctx context.Context, companyID uuid.UUID) ([]models.Ticket, error) {
	return s.repo.FindByCompany(ctx, companyID)
}

func (s *TicketService) GetByID(ctx context.Context, id uuid.UUID) (*models.Ticket, error) {
	return s.repo.FindByID(ctx, id)
}

func (s *TicketService) UpdateStatus(ctx context.Context, id uuid.UUID, req dto.UpdateTicketStatusRequest) (*models.Ticket, error) {
	ticket, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	switch req.Status {
	case models.TicketStatusOpen, models.TicketStatusInProgress, models.TicketStatusClosed:
		ticket.Status = req.Status
	default:
		return nil, fmt.Errorf("invalid status: %s", req.Status)
	}
	if err := s.repo.Update(ctx, ticket); err != nil {
		return nil, err
	}
	s.hub.BroadcastToCompany(ticket.CompanyID, "ticket.status_updated", ticket)
	return ticket, nil
}

func (s *TicketService) SendMessage(ctx context.Context, ticketID, senderID uuid.UUID, req dto.SendTicketMessageRequest) (*models.TicketMessage, error) {
	var attachments datatypes.JSON
	if req.Attachments != nil {
		attachments = datatypes.JSON(req.Attachments)
	} else {
		attachments = datatypes.JSON([]byte("[]"))
	}
	msg := &models.TicketMessage{
		TicketID:    ticketID,
		SenderID:    senderID,
		Content:     req.Content,
		Attachments: attachments,
	}
	if err := s.repo.CreateMessage(ctx, msg); err != nil {
		return nil, err
	}
	if t, err2 := s.repo.FindByID(ctx, ticketID); err2 == nil {
		s.hub.BroadcastToCompany(t.CompanyID, "ticket.message_sent", msg)
	}
	return msg, nil
}
