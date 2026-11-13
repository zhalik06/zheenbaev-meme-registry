-- Lab 3: calculations, business operation, and parameterized search

-- Formula for the Meme Registry topic:
-- one repost gives 10 points, one reaction gives 1 point.
CREATE OR REPLACE FUNCTION meme_viral_score(p_meme_id integer)
RETURNS integer
LANGUAGE sql
STABLE
AS $$
    SELECT (
        (SELECT count(*) FROM reposts WHERE meme_id = p_meme_id) * 10
        + (SELECT count(*) FROM reactions WHERE meme_id = p_meme_id)
    )::integer;
$$;

-- Recalculate the stored value after a repost or reaction changes.
CREATE OR REPLACE FUNCTION recalculate_meme_viral_index(p_meme_id integer)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE memes
    SET viral_index = meme_viral_score(p_meme_id)
    WHERE id = p_meme_id;
END;
$$;

-- One-command business operation: register a repost.
-- The AFTER trigger recalculates viral_index automatically.
CREATE OR REPLACE FUNCTION register_repost(
    p_meme_id integer,
    p_platform text
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_repost_id integer;
BEGIN
    INSERT INTO reposts (meme_id, platform)
    VALUES (p_meme_id, p_platform)
    RETURNING id INTO v_repost_id;

    RETURN v_repost_id;
END;
$$;

-- Search function for a website-like filter form. Any filter may be NULL.
CREATE OR REPLACE FUNCTION search_memes(
    p_author_id integer DEFAULT NULL,
    p_tag text DEFAULT NULL,
    p_min_viral integer DEFAULT NULL,
    p_title text DEFAULT NULL
)
RETURNS TABLE (
    meme_id integer,
    title text,
    author_name text,
    viral_index integer,
    created_at timestamptz
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        m.id,
        m.title,
        a.display_name,
        m.viral_index,
        m.created_at
    FROM memes m
    JOIN authors a ON a.id = m.author_id
    WHERE (p_author_id IS NULL OR m.author_id = p_author_id)
      AND (
          p_tag IS NULL
          OR EXISTS (
              SELECT 1
              FROM meme_tags mt
              JOIN tags t ON t.id = mt.tag_id
              WHERE mt.meme_id = m.id
                AND t.name = p_tag
          )
      )
      AND (p_min_viral IS NULL OR m.viral_index >= p_min_viral)
      AND (p_title IS NULL OR m.title ILIKE '%' || p_title || '%')
    ORDER BY m.viral_index DESC, m.created_at DESC, m.id;
$$;

-- Первоначально рассчитываем индекс для уже существующих мемов.
UPDATE memes AS m
SET viral_index = meme_viral_score(m.id);