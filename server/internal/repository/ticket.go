package repository

import (
	"context"

	"github.com/autocreat/server/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type TicketRepository struct {
	db *gorm.DB
}

func NewTicketRepository(db *gorm.DB) *TicketRepository {
	return &TicketRepository{db: db}
}

func (r *TicketRepository) Create(ctx context.Context, ticket *models.Ticket) error {
	return r.db.WithContext(ctx).Create(ticket).Error
}

func (r *TicketRepository) FindByCompany(ctx context.Context, companyID uuid.UUID) ([]models.Ticket, error) {
	var tickets []models.Ticket
	if err := r.db.WithContext(ctx).Where("company_id = ?", companyID).
		Preload("Creator").Find(&tickets).Error; err != nil {
		return nil, err
	}
	return tickets, nil
}

func (r *TicketRepository) FindByID(ctx context.Context, id uuid.UUID) (*models.Ticket, error) {
	var ticket models.Ticket
	if err := r.db.WithContext(ctx).Preload("Messages").Preload("Creator").
		First(&ticket, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &ticket, nil
}

func (r *TicketRepository) Update(ctx context.Context, ticket *models.Ticket) error {
	return r.db.WithContext(ctx).Save(ticket).Error
}

func (r *TicketRepository) CreateMessage(ctx context.Context, msg *models.TicketMessage) error {
	return r.db.WithContext(ctx).Create(msg).Error
}
