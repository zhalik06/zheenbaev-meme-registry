-- Lab 3: business-rule and service triggers, plus meme change journal

-- The journal intentionally has no FK to memes: DELETE history must remain.
CREATE TABLE IF NOT EXISTS meme_audit_log (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    meme_id integer NOT NULL,
    operation text NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    old_data jsonb,
    new_data jsonb,
    changed_by text NOT NULL,
    changed_at timestamptz NOT NULL
);

CREATE INDEX IF NOT EXISTS meme_audit_log_meme_time_idx
    ON meme_audit_log (meme_id, changed_at DESC, id DESC);

-- Friendly validation before the FK check. The message is useful to a caller.
CREATE OR REPLACE FUNCTION check_meme_activity_target()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM memes WHERE id = NEW.meme_id) THEN
        RAISE EXCEPTION 'мем с id % не найден: нельзя зарегистрировать активность', NEW.meme_id;
    END IF;

    RETURN NEW;
END;
$$;

-- One trigger function is shared by reposts and reactions.
CREATE OR REPLACE FUNCTION sync_meme_viral_index()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM recalculate_meme_viral_index(NEW.meme_id);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        PERFORM recalculate_meme_viral_index(OLD.meme_id);
        RETURN OLD;
    ELSE
        PERFORM recalculate_meme_viral_index(NEW.meme_id);
        IF OLD.meme_id IS DISTINCT FROM NEW.meme_id THEN
            PERFORM recalculate_meme_viral_index(OLD.meme_id);
        END IF;
        RETURN NEW;
    END IF;
END;
$$;

-- Service trigger: set the timestamp on every meme update.
CREATE OR REPLACE FUNCTION set_meme_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := clock_timestamp();
    RETURN NEW;
END;
$$;

-- Keep a JSONB snapshot for every INSERT, UPDATE, and DELETE.
CREATE OR REPLACE FUNCTION audit_meme_change()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO meme_audit_log
            (meme_id, operation, old_data, new_data, changed_by, changed_at)
        VALUES
            (NEW.id, 'INSERT', NULL, to_jsonb(NEW), session_user, clock_timestamp());
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO meme_audit_log
            (meme_id, operation, old_data, new_data, changed_by, changed_at)
        VALUES
            (NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), session_user, clock_timestamp());
        RETURN NEW;
    ELSE
        INSERT INTO meme_audit_log
            (meme_id, operation, old_data, new_data, changed_by, changed_at)
        VALUES
            (OLD.id, 'DELETE', to_jsonb(OLD), NULL, session_user, clock_timestamp());
        RETURN OLD;
    END IF;
END;
$$;

-- Return the latest recorded version at or before the requested moment.
-- NULL means that the meme did not yet exist or had already been deleted.
CREATE OR REPLACE FUNCTION meme_state_at(
    p_meme_id integer,
    p_at timestamptz
)
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
    SELECT CASE
        WHEN l.operation = 'DELETE' THEN NULL::jsonb
        ELSE l.new_data
    END
    FROM meme_audit_log l
    WHERE l.meme_id = p_meme_id
      AND l.changed_at <= p_at
    ORDER BY l.changed_at DESC, l.id DESC
    LIMIT 1;
$$;

-- Recreate triggers safely when the script is run manually a second time.
DROP TRIGGER IF EXISTS trg_reposts_check_meme ON reposts;
CREATE TRIGGER trg_reposts_check_meme
BEFORE INSERT OR UPDATE OF meme_id ON reposts
FOR EACH ROW EXECUTE FUNCTION check_meme_activity_target();

DROP TRIGGER IF EXISTS trg_reactions_check_meme ON reactions;
CREATE TRIGGER trg_reactions_check_meme
BEFORE INSERT OR UPDATE OF meme_id ON reactions
FOR EACH ROW EXECUTE FUNCTION check_meme_activity_target();

DROP TRIGGER IF EXISTS trg_reposts_sync_viral_index ON reposts;
CREATE TRIGGER trg_reposts_sync_viral_index
AFTER INSERT OR UPDATE OR DELETE ON reposts
FOR EACH ROW EXECUTE FUNCTION sync_meme_viral_index();

DROP TRIGGER IF EXISTS trg_reactions_sync_viral_index ON reactions;
CREATE TRIGGER trg_reactions_sync_viral_index
AFTER INSERT OR UPDATE OR DELETE ON reactions
FOR EACH ROW EXECUTE FUNCTION sync_meme_viral_index();

DROP TRIGGER IF EXISTS trg_memes_updated_at ON memes;
CREATE TRIGGER trg_memes_updated_at
BEFORE UPDATE ON memes
FOR EACH ROW EXECUTE FUNCTION set_meme_updated_at();

DROP TRIGGER IF EXISTS trg_memes_audit ON memes;
CREATE TRIGGER trg_memes_audit
AFTER INSERT OR UPDATE OR DELETE ON memes
FOR EACH ROW EXECUTE FUNCTION audit_meme_change();
