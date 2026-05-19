-- Fix flow schema to match GORM model column names.
-- AutoMigrate runs first and adds the correct new columns; this migration
-- drops the old mismatched columns that AutoMigrate cannot rename/remove.
-- Idempotent: safe to run multiple times.

DO $$
BEGIN

    -- =========================================================================
    -- flow_nodes: drop old columns (AutoMigrate already added the correct ones)
    -- =========================================================================

    -- Drop old CHECK constraint that used uppercase values / old column name
    IF EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_flow_nodes_node_type'
    ) THEN
        ALTER TABLE flow_nodes DROP CONSTRAINT chk_flow_nodes_node_type;
    END IF;

    -- Drop node_type (GORM already created "type")
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_nodes' AND column_name = 'node_type'
    ) THEN
        ALTER TABLE flow_nodes DROP COLUMN node_type;
    END IF;

    -- Drop name (GORM already created "label")
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_nodes' AND column_name = 'name'
    ) THEN
        ALTER TABLE flow_nodes DROP COLUMN name;
    END IF;

    -- Drop position_x (GORM already created "x")
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_nodes' AND column_name = 'position_x'
    ) THEN
        ALTER TABLE flow_nodes DROP COLUMN position_x;
    END IF;

    -- Drop position_y (GORM already created "y")
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_nodes' AND column_name = 'position_y'
    ) THEN
        ALTER TABLE flow_nodes DROP COLUMN position_y;
    END IF;

    -- Drop properties (GORM already created "branches" and "metadata")
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_nodes' AND column_name = 'properties'
    ) THEN
        ALTER TABLE flow_nodes DROP COLUMN properties;
    END IF;

    -- =========================================================================
    -- flows: drop is_active (GORM already created "status" and "settings")
    -- =========================================================================

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flows' AND column_name = 'is_active'
    ) THEN
        ALTER TABLE flows DROP COLUMN is_active;
    END IF;

    -- =========================================================================
    -- flow_edges: drop condition JSONB (GORM already created "condition_id")
    -- =========================================================================

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_edges' AND column_name = 'condition'
    ) THEN
        ALTER TABLE flow_edges DROP COLUMN condition;
    END IF;

END;
$$;
