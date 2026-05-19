-- Fix flow schema to match GORM model column names.
-- Handles databases bootstrapped from the old SQL schema (pre-GORM alignment).
-- Idempotent: safe to run multiple times.

DO $$
BEGIN

    -- =========================================================================
    -- flow_nodes: rename old columns → GORM field names, add missing columns
    -- =========================================================================

    -- node_type → "type"
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_nodes' AND column_name = 'node_type'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_nodes' AND column_name = 'type'
    ) THEN
        ALTER TABLE flow_nodes RENAME COLUMN node_type TO "type";
    END IF;

    -- Drop CHECK constraint that used uppercase values / old column name
    IF EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_flow_nodes_node_type'
    ) THEN
        ALTER TABLE flow_nodes DROP CONSTRAINT chk_flow_nodes_node_type;
    END IF;

    -- name → label
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_nodes' AND column_name = 'name'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_nodes' AND column_name = 'label'
    ) THEN
        ALTER TABLE flow_nodes RENAME COLUMN name TO label;
    END IF;

    -- position_x → x
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_nodes' AND column_name = 'position_x'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_nodes' AND column_name = 'x'
    ) THEN
        ALTER TABLE flow_nodes RENAME COLUMN position_x TO x;
    END IF;

    -- position_y → y
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_nodes' AND column_name = 'position_y'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_nodes' AND column_name = 'y'
    ) THEN
        ALTER TABLE flow_nodes RENAME COLUMN position_y TO y;
    END IF;

    -- Add width if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_nodes' AND column_name = 'width'
    ) THEN
        ALTER TABLE flow_nodes ADD COLUMN width FLOAT8 NOT NULL DEFAULT 160;
    END IF;

    -- Add height if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_nodes' AND column_name = 'height'
    ) THEN
        ALTER TABLE flow_nodes ADD COLUMN height FLOAT8 NOT NULL DEFAULT 60;
    END IF;

    -- Add description if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_nodes' AND column_name = 'description'
    ) THEN
        ALTER TABLE flow_nodes ADD COLUMN description VARCHAR;
    END IF;

    -- Add branches if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_nodes' AND column_name = 'branches'
    ) THEN
        ALTER TABLE flow_nodes ADD COLUMN branches JSONB DEFAULT '[]';
    END IF;

    -- Add metadata if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_nodes' AND column_name = 'metadata'
    ) THEN
        ALTER TABLE flow_nodes ADD COLUMN metadata JSONB DEFAULT '{}';
    END IF;

    -- Drop old properties column (was unused; branches/metadata replace it)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_nodes' AND column_name = 'properties'
    ) THEN
        ALTER TABLE flow_nodes DROP COLUMN properties;
    END IF;

    -- =========================================================================
    -- flows: add status and settings columns if missing
    -- =========================================================================

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flows' AND column_name = 'status'
    ) THEN
        ALTER TABLE flows ADD COLUMN status VARCHAR NOT NULL DEFAULT 'draft';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flows' AND column_name = 'settings'
    ) THEN
        ALTER TABLE flows ADD COLUMN settings JSONB DEFAULT '{}';
    END IF;

    -- =========================================================================
    -- flow_edges: replace condition JSONB → condition_id VARCHAR
    -- =========================================================================

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_edges' AND column_name = 'condition'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'flow_edges' AND column_name = 'condition_id'
    ) THEN
        ALTER TABLE flow_edges ADD COLUMN condition_id VARCHAR;
        ALTER TABLE flow_edges DROP COLUMN condition;
    END IF;

END;
$$;
