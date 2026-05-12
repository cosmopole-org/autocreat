-- AutoCreat initial schema
-- This file documents the schema; GORM AutoMigrate handles actual creation.

-- Enable UUID extension (required on PostgreSQL < 13 for gen_random_uuid())
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users & Sessions are handled by GORM AutoMigrate.
-- This file can be used for manual inspection or seeding.

-- Example seed: default admin user (password: admin1234)
-- INSERT INTO users (id, email, password_hash, full_name, is_active, is_owner, created_at, updated_at)
-- VALUES (
--   uuid_generate_v4(),
--   'admin@autocreat.io',
--   '$2a$10$...bcrypt_hash...',
--   'System Admin',
--   true,
--   true,
--   NOW(),
--   NOW()
-- );
