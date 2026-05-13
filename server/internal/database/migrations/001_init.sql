-- =============================================================================
-- AutoCreat – full bootstrap schema
-- PostgreSQL 14+
--
-- Run once against a blank database to bring it to the same state that
-- GORM AutoMigrate would produce.  Safe to apply on an already-migrated DB
-- because every statement is idempotent (CREATE … IF NOT EXISTS / DO blocks).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------

CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";  -- uuid_generate_v4() (legacy compat)

-- ---------------------------------------------------------------------------
-- Enum-like CHECK helpers
-- We use VARCHAR columns (matching GORM defaults) and attach CHECK constraints
-- so that invalid values are rejected at the DB layer as well as the app layer.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- 1. users
-- company_id and role_id FKs are added later to break circular dependencies.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS users (
    id           UUID        NOT NULL DEFAULT gen_random_uuid(),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    email        VARCHAR     NOT NULL,
    password_hash VARCHAR    NOT NULL,
    full_name    VARCHAR     NOT NULL,
    company_id   UUID,                          -- FK added after companies
    role_id      UUID,                          -- FK added after roles
    avatar       VARCHAR,
    is_active    BOOLEAN     NOT NULL DEFAULT TRUE,
    is_owner     BOOLEAN     NOT NULL DEFAULT FALSE,
    CONSTRAINT   pk_users PRIMARY KEY (id)
);

CREATE UNIQUE INDEX IF NOT EXISTS uni_users_email ON users (email);
CREATE        INDEX IF NOT EXISTS idx_users_company_id ON users (company_id);
CREATE        INDEX IF NOT EXISTS idx_users_role_id    ON users (role_id);

-- ---------------------------------------------------------------------------
-- 2. sessions
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS sessions (
    id            UUID        NOT NULL DEFAULT gen_random_uuid(),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    user_id       UUID        NOT NULL,
    refresh_token VARCHAR     NOT NULL,
    expires_at    TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_sessions PRIMARY KEY (id),
    CONSTRAINT fk_sessions_user FOREIGN KEY (user_id)
        REFERENCES users (id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS uni_sessions_refresh_token ON sessions (refresh_token);
CREATE        INDEX IF NOT EXISTS idx_sessions_user_id       ON sessions (user_id);

-- ---------------------------------------------------------------------------
-- 3. companies
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS companies (
    id          UUID        NOT NULL DEFAULT gen_random_uuid(),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    name        VARCHAR     NOT NULL,
    description VARCHAR,
    logo        VARCHAR,
    owner_id    UUID        NOT NULL,
    CONSTRAINT pk_companies PRIMARY KEY (id),
    CONSTRAINT fk_companies_owner FOREIGN KEY (owner_id)
        REFERENCES users (id)
);

CREATE INDEX IF NOT EXISTS idx_companies_owner_id ON companies (owner_id);

-- ---------------------------------------------------------------------------
-- 4. roles
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS roles (
    id          UUID        NOT NULL DEFAULT gen_random_uuid(),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    company_id  UUID        NOT NULL,
    name        VARCHAR     NOT NULL,
    description VARCHAR,
    color       VARCHAR,
    permissions JSONB,
    CONSTRAINT pk_roles PRIMARY KEY (id),
    CONSTRAINT fk_roles_company FOREIGN KEY (company_id)
        REFERENCES companies (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_roles_company_id ON roles (company_id);

-- ---------------------------------------------------------------------------
-- 5. company_members  (composite PK: company_id + user_id)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS company_members (
    company_id UUID        NOT NULL,
    user_id    UUID        NOT NULL,
    role_id    UUID        NOT NULL,
    joined_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_company_members PRIMARY KEY (company_id, user_id),
    CONSTRAINT fk_company_members_company FOREIGN KEY (company_id)
        REFERENCES companies (id) ON DELETE CASCADE,
    CONSTRAINT fk_company_members_user FOREIGN KEY (user_id)
        REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_company_members_role FOREIGN KEY (role_id)
        REFERENCES roles (id)
);

CREATE INDEX IF NOT EXISTS idx_company_members_user_id   ON company_members (user_id);
CREATE INDEX IF NOT EXISTS idx_company_members_company_id ON company_members (company_id);

-- ---------------------------------------------------------------------------
-- 6. flows
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS flows (
    id          UUID        NOT NULL DEFAULT gen_random_uuid(),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    company_id  UUID        NOT NULL,
    name        VARCHAR     NOT NULL,
    description VARCHAR,
    is_active   BOOLEAN     NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_flows PRIMARY KEY (id),
    CONSTRAINT fk_flows_company FOREIGN KEY (company_id)
        REFERENCES companies (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_flows_company_id ON flows (company_id);

-- ---------------------------------------------------------------------------
-- 7. form_definitions
-- Defined before flow_nodes so that flow_nodes.assigned_form_id can
-- reference it with a proper FK.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS form_definitions (
    id          UUID        NOT NULL DEFAULT gen_random_uuid(),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    company_id  UUID        NOT NULL,
    name        VARCHAR     NOT NULL,
    description VARCHAR,
    fields      JSONB,
    CONSTRAINT pk_form_definitions PRIMARY KEY (id),
    CONSTRAINT fk_form_definitions_company FOREIGN KEY (company_id)
        REFERENCES companies (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_form_definitions_company_id ON form_definitions (company_id);

-- ---------------------------------------------------------------------------
-- 8. flow_nodes
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS flow_nodes (
    id               UUID        NOT NULL DEFAULT gen_random_uuid(),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    flow_id          UUID        NOT NULL,
    node_type        VARCHAR     NOT NULL,
    name             VARCHAR     NOT NULL,
    position_x       FLOAT8      NOT NULL DEFAULT 0,
    position_y       FLOAT8      NOT NULL DEFAULT 0,
    assigned_role_id UUID,
    assigned_form_id UUID,
    properties       JSONB,
    CONSTRAINT pk_flow_nodes PRIMARY KEY (id),
    CONSTRAINT fk_flow_nodes_flow FOREIGN KEY (flow_id)
        REFERENCES flows (id) ON DELETE CASCADE,
    CONSTRAINT fk_flow_nodes_role FOREIGN KEY (assigned_role_id)
        REFERENCES roles (id) ON DELETE SET NULL,
    CONSTRAINT fk_flow_nodes_form FOREIGN KEY (assigned_form_id)
        REFERENCES form_definitions (id) ON DELETE SET NULL,
    CONSTRAINT chk_flow_nodes_node_type CHECK (
        node_type IN ('START', 'STEP', 'DECISION', 'END')
    )
);

CREATE INDEX IF NOT EXISTS idx_flow_nodes_flow_id          ON flow_nodes (flow_id);
CREATE INDEX IF NOT EXISTS idx_flow_nodes_assigned_role_id ON flow_nodes (assigned_role_id);
CREATE INDEX IF NOT EXISTS idx_flow_nodes_assigned_form_id ON flow_nodes (assigned_form_id);

-- ---------------------------------------------------------------------------
-- 9. flow_edges
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS flow_edges (
    id             UUID        NOT NULL DEFAULT gen_random_uuid(),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    flow_id        UUID        NOT NULL,
    source_node_id UUID        NOT NULL,
    target_node_id UUID        NOT NULL,
    label          VARCHAR,
    condition      JSONB,
    CONSTRAINT pk_flow_edges PRIMARY KEY (id),
    CONSTRAINT fk_flow_edges_flow        FOREIGN KEY (flow_id)
        REFERENCES flows (id) ON DELETE CASCADE,
    CONSTRAINT fk_flow_edges_source_node FOREIGN KEY (source_node_id)
        REFERENCES flow_nodes (id) ON DELETE CASCADE,
    CONSTRAINT fk_flow_edges_target_node FOREIGN KEY (target_node_id)
        REFERENCES flow_nodes (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_flow_edges_flow_id        ON flow_edges (flow_id);
CREATE INDEX IF NOT EXISTS idx_flow_edges_source_node_id ON flow_edges (source_node_id);
CREATE INDEX IF NOT EXISTS idx_flow_edges_target_node_id ON flow_edges (target_node_id);

-- ---------------------------------------------------------------------------
-- 10. flow_assignments
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS flow_assignments (
    id            UUID        NOT NULL DEFAULT gen_random_uuid(),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    flow_id       UUID        NOT NULL,
    start_node_id UUID        NOT NULL,
    role_id       UUID        NOT NULL,
    is_active     BOOLEAN     NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_flow_assignments PRIMARY KEY (id),
    CONSTRAINT fk_flow_assignments_flow       FOREIGN KEY (flow_id)
        REFERENCES flows (id) ON DELETE CASCADE,
    CONSTRAINT fk_flow_assignments_start_node FOREIGN KEY (start_node_id)
        REFERENCES flow_nodes (id) ON DELETE CASCADE,
    CONSTRAINT fk_flow_assignments_role       FOREIGN KEY (role_id)
        REFERENCES roles (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_flow_assignments_flow_id       ON flow_assignments (flow_id);
CREATE INDEX IF NOT EXISTS idx_flow_assignments_start_node_id ON flow_assignments (start_node_id);
CREATE INDEX IF NOT EXISTS idx_flow_assignments_role_id       ON flow_assignments (role_id);

-- ---------------------------------------------------------------------------
-- 11. flow_instances
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS flow_instances (
    id              UUID        NOT NULL DEFAULT gen_random_uuid(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    flow_id         UUID        NOT NULL,
    current_node_id UUID,
    status          VARCHAR     NOT NULL DEFAULT 'ACTIVE',
    started_by_id   UUID        NOT NULL,
    company_id      UUID        NOT NULL,
    CONSTRAINT pk_flow_instances PRIMARY KEY (id),
    CONSTRAINT fk_flow_instances_flow         FOREIGN KEY (flow_id)
        REFERENCES flows (id),
    CONSTRAINT fk_flow_instances_current_node FOREIGN KEY (current_node_id)
        REFERENCES flow_nodes (id) ON DELETE SET NULL,
    CONSTRAINT fk_flow_instances_started_by   FOREIGN KEY (started_by_id)
        REFERENCES users (id),
    CONSTRAINT fk_flow_instances_company      FOREIGN KEY (company_id)
        REFERENCES companies (id) ON DELETE CASCADE,
    CONSTRAINT chk_flow_instances_status CHECK (
        status IN ('ACTIVE', 'COMPLETED', 'REJECTED', 'CANCELLED')
    )
);

CREATE INDEX IF NOT EXISTS idx_flow_instances_flow_id         ON flow_instances (flow_id);
CREATE INDEX IF NOT EXISTS idx_flow_instances_company_id      ON flow_instances (company_id);
CREATE INDEX IF NOT EXISTS idx_flow_instances_started_by_id   ON flow_instances (started_by_id);
CREATE INDEX IF NOT EXISTS idx_flow_instances_current_node_id ON flow_instances (current_node_id);
CREATE INDEX IF NOT EXISTS idx_flow_instances_status          ON flow_instances (status);

-- ---------------------------------------------------------------------------
-- 12. form_submissions
-- Defined before flow_instance_steps so that flow_instance_steps.form_submission_id
-- can reference it with a proper FK.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS form_submissions (
    id               UUID        NOT NULL DEFAULT gen_random_uuid(),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    flow_instance_id UUID        NOT NULL,
    flow_node_id     UUID        NOT NULL,
    submitted_by_id  UUID        NOT NULL,
    data             JSONB,
    CONSTRAINT pk_form_submissions PRIMARY KEY (id),
    CONSTRAINT fk_form_submissions_flow_instance FOREIGN KEY (flow_instance_id)
        REFERENCES flow_instances (id) ON DELETE CASCADE,
    CONSTRAINT fk_form_submissions_flow_node     FOREIGN KEY (flow_node_id)
        REFERENCES flow_nodes (id),
    CONSTRAINT fk_form_submissions_submitted_by  FOREIGN KEY (submitted_by_id)
        REFERENCES users (id)
);

CREATE INDEX IF NOT EXISTS idx_form_submissions_flow_instance_id ON form_submissions (flow_instance_id);
CREATE INDEX IF NOT EXISTS idx_form_submissions_flow_node_id     ON form_submissions (flow_node_id);
CREATE INDEX IF NOT EXISTS idx_form_submissions_submitted_by_id  ON form_submissions (submitted_by_id);

-- ---------------------------------------------------------------------------
-- 13. flow_instance_steps
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS flow_instance_steps (
    id                  UUID        NOT NULL DEFAULT gen_random_uuid(),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    flow_instance_id    UUID        NOT NULL,
    node_id             UUID        NOT NULL,
    status              VARCHAR     NOT NULL DEFAULT 'PENDING',
    assigned_to_role_id UUID,
    form_submission_id  UUID,
    completed_at        TIMESTAMPTZ,
    rejected_at         TIMESTAMPTZ,
    rejection_comment   VARCHAR,
    rejected_to_node_id UUID,
    CONSTRAINT pk_flow_instance_steps PRIMARY KEY (id),
    CONSTRAINT fk_flow_instance_steps_instance       FOREIGN KEY (flow_instance_id)
        REFERENCES flow_instances (id) ON DELETE CASCADE,
    CONSTRAINT fk_flow_instance_steps_node           FOREIGN KEY (node_id)
        REFERENCES flow_nodes (id),
    CONSTRAINT fk_flow_instance_steps_role           FOREIGN KEY (assigned_to_role_id)
        REFERENCES roles (id) ON DELETE SET NULL,
    CONSTRAINT fk_flow_instance_steps_form_sub       FOREIGN KEY (form_submission_id)
        REFERENCES form_submissions (id) ON DELETE SET NULL,
    CONSTRAINT fk_flow_instance_steps_rejected_node  FOREIGN KEY (rejected_to_node_id)
        REFERENCES flow_nodes (id) ON DELETE SET NULL,
    CONSTRAINT chk_flow_instance_steps_status CHECK (
        status IN ('PENDING', 'COMPLETED', 'REJECTED')
    )
);

CREATE INDEX IF NOT EXISTS idx_flow_instance_steps_flow_instance_id    ON flow_instance_steps (flow_instance_id);
CREATE INDEX IF NOT EXISTS idx_flow_instance_steps_node_id             ON flow_instance_steps (node_id);
CREATE INDEX IF NOT EXISTS idx_flow_instance_steps_assigned_to_role_id ON flow_instance_steps (assigned_to_role_id);
CREATE INDEX IF NOT EXISTS idx_flow_instance_steps_status              ON flow_instance_steps (status);

-- ---------------------------------------------------------------------------
-- 14. model_definitions
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS model_definitions (
    id          UUID        NOT NULL DEFAULT gen_random_uuid(),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    company_id  UUID        NOT NULL,
    name        VARCHAR     NOT NULL,
    description VARCHAR,
    fields      JSONB,
    CONSTRAINT pk_model_definitions PRIMARY KEY (id),
    CONSTRAINT fk_model_definitions_company FOREIGN KEY (company_id)
        REFERENCES companies (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_model_definitions_company_id ON model_definitions (company_id);

-- ---------------------------------------------------------------------------
-- 15. model_entities
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS model_entities (
    id                   UUID        NOT NULL DEFAULT gen_random_uuid(),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    model_definition_id  UUID        NOT NULL,
    company_id           UUID        NOT NULL,
    data                 JSONB,
    created_by_id        UUID        NOT NULL,
    CONSTRAINT pk_model_entities PRIMARY KEY (id),
    CONSTRAINT fk_model_entities_model_def  FOREIGN KEY (model_definition_id)
        REFERENCES model_definitions (id) ON DELETE CASCADE,
    CONSTRAINT fk_model_entities_company    FOREIGN KEY (company_id)
        REFERENCES companies (id) ON DELETE CASCADE,
    CONSTRAINT fk_model_entities_created_by FOREIGN KEY (created_by_id)
        REFERENCES users (id)
);

CREATE INDEX IF NOT EXISTS idx_model_entities_model_definition_id ON model_entities (model_definition_id);
CREATE INDEX IF NOT EXISTS idx_model_entities_company_id          ON model_entities (company_id);
CREATE INDEX IF NOT EXISTS idx_model_entities_created_by_id       ON model_entities (created_by_id);

-- ---------------------------------------------------------------------------
-- 16. letter_templates
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS letter_templates (
    id          UUID        NOT NULL DEFAULT gen_random_uuid(),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    company_id  UUID        NOT NULL,
    name        VARCHAR     NOT NULL,
    description VARCHAR,
    content     JSONB,
    variables   JSONB,
    CONSTRAINT pk_letter_templates PRIMARY KEY (id),
    CONSTRAINT fk_letter_templates_company FOREIGN KEY (company_id)
        REFERENCES companies (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_letter_templates_company_id ON letter_templates (company_id);

-- ---------------------------------------------------------------------------
-- 17. generated_letters
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS generated_letters (
    id                UUID        NOT NULL DEFAULT gen_random_uuid(),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    template_id       UUID        NOT NULL,
    flow_instance_id  UUID,
    data              JSONB,
    generated_content TEXT,
    created_by_id     UUID        NOT NULL,
    CONSTRAINT pk_generated_letters PRIMARY KEY (id),
    CONSTRAINT fk_generated_letters_template      FOREIGN KEY (template_id)
        REFERENCES letter_templates (id) ON DELETE CASCADE,
    CONSTRAINT fk_generated_letters_flow_instance FOREIGN KEY (flow_instance_id)
        REFERENCES flow_instances (id) ON DELETE SET NULL,
    CONSTRAINT fk_generated_letters_created_by    FOREIGN KEY (created_by_id)
        REFERENCES users (id)
);

CREATE INDEX IF NOT EXISTS idx_generated_letters_template_id      ON generated_letters (template_id);
CREATE INDEX IF NOT EXISTS idx_generated_letters_flow_instance_id ON generated_letters (flow_instance_id);
CREATE INDEX IF NOT EXISTS idx_generated_letters_created_by_id    ON generated_letters (created_by_id);

-- ---------------------------------------------------------------------------
-- 18. tickets
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS tickets (
    id               UUID        NOT NULL DEFAULT gen_random_uuid(),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    company_id       UUID        NOT NULL,
    subject_title    VARCHAR     NOT NULL,
    status           VARCHAR     NOT NULL DEFAULT 'OPEN',
    creator_id       UUID        NOT NULL,
    assigned_to_id   UUID,
    flow_instance_id UUID,
    CONSTRAINT pk_tickets PRIMARY KEY (id),
    CONSTRAINT fk_tickets_company       FOREIGN KEY (company_id)
        REFERENCES companies (id) ON DELETE CASCADE,
    CONSTRAINT fk_tickets_creator       FOREIGN KEY (creator_id)
        REFERENCES users (id),
    CONSTRAINT fk_tickets_assigned_to   FOREIGN KEY (assigned_to_id)
        REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT fk_tickets_flow_instance FOREIGN KEY (flow_instance_id)
        REFERENCES flow_instances (id) ON DELETE SET NULL,
    CONSTRAINT chk_tickets_status CHECK (
        status IN ('OPEN', 'IN_PROGRESS', 'CLOSED')
    )
);

CREATE INDEX IF NOT EXISTS idx_tickets_company_id       ON tickets (company_id);
CREATE INDEX IF NOT EXISTS idx_tickets_creator_id       ON tickets (creator_id);
CREATE INDEX IF NOT EXISTS idx_tickets_assigned_to_id   ON tickets (assigned_to_id);
CREATE INDEX IF NOT EXISTS idx_tickets_flow_instance_id ON tickets (flow_instance_id);
CREATE INDEX IF NOT EXISTS idx_tickets_status           ON tickets (status);

-- ---------------------------------------------------------------------------
-- 19. ticket_messages
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ticket_messages (
    id          UUID        NOT NULL DEFAULT gen_random_uuid(),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ticket_id   UUID        NOT NULL,
    sender_id   UUID        NOT NULL,
    content     TEXT        NOT NULL,
    attachments JSONB,
    CONSTRAINT pk_ticket_messages PRIMARY KEY (id),
    CONSTRAINT fk_ticket_messages_ticket FOREIGN KEY (ticket_id)
        REFERENCES tickets (id) ON DELETE CASCADE,
    CONSTRAINT fk_ticket_messages_sender FOREIGN KEY (sender_id)
        REFERENCES users (id)
);

CREATE INDEX IF NOT EXISTS idx_ticket_messages_ticket_id ON ticket_messages (ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_messages_sender_id ON ticket_messages (sender_id);

-- ---------------------------------------------------------------------------
-- Deferred FK constraints – resolve circular dependencies
-- users.company_id -> companies and users.role_id -> roles could not be
-- declared inline because the referenced tables didn't exist yet when users
-- was created.
-- ---------------------------------------------------------------------------

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_users_company'
    ) THEN
        ALTER TABLE users
            ADD CONSTRAINT fk_users_company
            FOREIGN KEY (company_id) REFERENCES companies (id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_users_role'
    ) THEN
        ALTER TABLE users
            ADD CONSTRAINT fk_users_role
            FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE SET NULL;
    END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- Seed: default system admin
-- Password "admin1234" → bcrypt cost 10.  Replace before production use.
-- Uncomment when bootstrapping a fresh environment.
-- ---------------------------------------------------------------------------

-- INSERT INTO users (id, email, password_hash, full_name, is_active, is_owner, created_at, updated_at)
-- VALUES (
--   gen_random_uuid(),
--   'admin@autocreat.io',
--   '$2a$10$YourBcryptHashHere',
--   'System Admin',
--   TRUE,
--   TRUE,
--   NOW(),
--   NOW()
-- )
-- ON CONFLICT (email) DO NOTHING;
