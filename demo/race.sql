-- [setup]
-- Временно возвращаем незащищённую версию функции,
-- чтобы продемонстрировать возникновение гонки.
CREATE OR REPLACE FUNCTION check_meme_activity_target()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM memes WHERE id = NEW.meme_id
    ) THEN
        RAISE EXCEPTION 'meme with id % not found', NEW.meme_id;
    END IF;

    RETURN NEW;
END;
$$;

-- Удаляем остатки предыдущего теста.
DELETE FROM memes
WHERE title = 'lab4_race_test';

INSERT INTO memes (
    title, description, media_url, author_id, template_id, viral_index
)
SELECT
    'lab4_race_test',
    description,
    media_url,
    author_id,
    template_id,
    0
FROM memes
WHERE id = 1;

-- [A]
BEGIN;

SELECT register_repost(
    (SELECT id FROM memes WHERE title = 'lab4_race_test'),
    'instagram'
);

-- [B]
BEGIN;

SELECT register_repost(
    (SELECT id FROM memes WHERE title = 'lab4_race_test'),
    'reddit'
);
-- expect: blocked

-- [A]
COMMIT;

-- [B]
COMMIT;

-- [check]
-- Проверяем, что сохранённый индекс не совпадает с рассчитанным.
SELECT (
    (SELECT viral_index
     FROM memes
     WHERE title = 'lab4_race_test')
    =
    meme_viral_score(
        (SELECT id
         FROM memes
         WHERE title = 'lab4_race_test')
    )
) AS rule_holds;
-- expect: false

-- [cleanup]
-- Удаляем тестовый мем.
DELETE FROM memes
WHERE title = 'lab4_race_test';

-- Восстанавливаем защищённую версию функции.
CREATE OR REPLACE FUNCTION check_meme_activity_target()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM 1
    FROM memes
    WHERE id = NEW.meme_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'meme with id % not found: activity cannot be registered', NEW.meme_id;
    END IF;

    RETURN NEW;
END;
$$;