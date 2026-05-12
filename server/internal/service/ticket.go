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
}

func NewTicketService(repo *repository.TicketRepository) *TicketService {
	return &TicketService{repo: repo}
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
	return ticket, s.repo.Update(ctx, ticket)
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
	return msg, nil
}
