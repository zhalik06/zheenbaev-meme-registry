-- Lab 4: protect meme activity from concurrent changes.
CREATE OR REPLACE FUNCTION check_meme_activity_target()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    PERFORM 1
    FROM memes
    WHERE id = NEW.meme_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'мем с id % не найден: нельзя зарегистрировать активность', NEW.meme_id;
    END IF;

    RETURN NEW;
END;
$$;