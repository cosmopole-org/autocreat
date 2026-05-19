-- Fix users table: replace full_name with first_name / last_name to match GORM model.
-- This migration is idempotent and safe to run on existing databases.

DO $$
BEGIN
    -- Add first_name if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'first_name'
    ) THEN
        ALTER TABLE users ADD COLUMN first_name VARCHAR NOT NULL DEFAULT '';
    END IF;

    -- Add last_name if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'last_name'
    ) THEN
        ALTER TABLE users ADD COLUMN last_name VARCHAR NOT NULL DEFAULT '';
    END IF;

    -- Add phone if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'phone'
    ) THEN
        ALTER TABLE users ADD COLUMN phone VARCHAR NOT NULL DEFAULT '';
    END IF;

    -- Migrate data from full_name into first_name / last_name
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'full_name'
    ) THEN
        UPDATE users
        SET
            first_name = COALESCE(SPLIT_PART(full_name, ' ', 1), ''),
            last_name  = COALESCE(
                NULLIF(TRIM(SUBSTRING(full_name FROM POSITION(' ' IN full_name) + 1)), ''),
                ''
            )
        WHERE first_name = '' AND full_name IS NOT NULL AND full_name <> '';

        ALTER TABLE users DROP COLUMN full_name;
    END IF;
END;
$$;
