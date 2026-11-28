-- Лаба 3: расчёты, бизнес-операция и поиск с параметрами

-- Формула для темы Meme Registry:
-- один репост даёт 10 баллов, одна реакция — 1 балл.
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

-- Пересчитывает сохранённое значение после изменения репоста или реакции.
CREATE OR REPLACE FUNCTION recalculate_meme_viral_index(p_meme_id integer)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    UPDATE memes
    SET viral_index = meme_viral_score(p_meme_id)
    WHERE id = p_meme_id;
END;
$$;

-- Бизнес-операция, выполняемая одной командой: зарегистрировать репост.
-- AFTER-триггер автоматически пересчитывает viral_index.
CREATE OR REPLACE FUNCTION register_repost(
    p_meme_id integer,
    p_platform text
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
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

-- Функция поиска для формы фильтров на сайте. Любой фильтр может быть NULL.
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

-- Пересчитываем начальный индекс для уже существующих мемов.
UPDATE memes AS m
SET viral_index = meme_viral_score(m.id);
