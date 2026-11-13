-- 1. Какие мемы создали авторы и на каких шаблонах они основаны?
-- expect: rows 10
SELECT
    m.id AS meme_id,
    m.title AS meme_title,
    a.display_name AS author,
    t.name AS template
FROM memes m
JOIN authors a ON a.id = m.author_id
JOIN templates t ON t.id = m.template_id
ORDER BY m.id;

-- 2. Какие теги присвоены каждому мему?
-- expect: rows 20
SELECT
    m.title AS meme,
    t.name AS tag
FROM memes m
JOIN meme_tags mt ON mt.meme_id = m.id
JOIN tags t ON t.id = mt.tag_id
ORDER BY m.id, t.name;


-- 3. На каких платформах публиковали мемы и кто их автор?
-- expect: rows 10
SELECT
    m.title AS meme,
    a.display_name AS author,
    r.platform AS platform,
    r.reposted_at
FROM memes m
JOIN authors a ON a.id = m.author_id
JOIN reposts r ON r.meme_id = m.id
ORDER BY m.id;

-- 4. Сколько мемов относится к каждому тегу?
-- expect: rows 10
SELECT
    t.name AS tag,
    COUNT(mt.meme_id) AS memes_count
FROM tags t
LEFT JOIN meme_tags mt ON mt.tag_id = t.id
GROUP BY t.id, t.name
ORDER BY memes_count DESC, t.name;

-- 5. На каких платформах опубликовано не менее двух репостов?
-- expect: rows 4
SELECT
    platform,
    COUNT(*) AS reposts_count
FROM reposts
GROUP BY platform
HAVING COUNT(*) >= 2
ORDER BY reposts_count DESC, platform;

-- 6. Какие теги пока не используются ни одним мемом?
-- expect: rows 2
SELECT
    t.id,
    t.name
FROM tags t
LEFT JOIN meme_tags mt ON mt.tag_id = t.id
WHERE mt.tag_id IS NULL
ORDER BY t.name;


-- 7. Какие мемы имеют тег programming?
-- expect: rows 4
SELECT
    m.id,
    m.title
FROM memes m
WHERE m.id IN (
    SELECT mt.meme_id
    FROM meme_tags mt
    JOIN tags t ON t.id = mt.tag_id
    WHERE t.name = 'programming'
)
ORDER BY m.id;

-- 8. Какие авторы создали хотя бы один мем с тегом technology?
-- expect: rows 2
SELECT
    a.id,
    a.display_name,
    a.username
FROM authors a
WHERE EXISTS (
    SELECT 1
    FROM memes m
    JOIN meme_tags mt ON mt.meme_id = m.id
    JOIN tags t ON t.id = mt.tag_id
    WHERE m.author_id = a.id
      AND t.name = 'technology'
)
ORDER BY a.id;

-- 9. Сколько репостов и реакций получил каждый мем?
-- expect: rows 10
SELECT
    m.id,
    m.title,
    (SELECT COUNT(*)
     FROM reposts r
     WHERE r.meme_id = m.id) AS reposts_count,
    (SELECT COUNT(*)
     FROM reactions r
     WHERE r.meme_id = m.id) AS reactions_count
FROM memes m
ORDER BY m.id;

-- 10. Как добавить новый мем и проверить результат?
-- expect: value 10
BEGIN;

SELECT COUNT(*) AS memes_before
FROM memes;

INSERT INTO memes
    (title, description, media_url, author_id, template_id, viral_index)
VALUES
    ('Lab 2 temporary meme',
     'Temporary meme for INSERT demonstration',
     'https://example.com/lab2-temporary.jpg',
     1, 1, 0)
RETURNING id, title;

SELECT COUNT(*) AS memes_after_insert
FROM memes;

ROLLBACK;

SELECT COUNT(*) AS memes_after_rollback
FROM memes;


-- 11. Как изменить индекс вирусности мема и проверить результат?
-- expect: value 0
BEGIN;

SELECT id, title, viral_index AS before
FROM memes
WHERE id = 1;

UPDATE memes
SET viral_index = viral_index + 5
WHERE id = 1
RETURNING id, title, viral_index AS updated_index;

SELECT id, viral_index AS after_update
FROM memes
WHERE id = 1;

ROLLBACK;

SELECT viral_index AS after_rollback
FROM memes
WHERE id = 1;

-- 12. Как удалить связь между мемом и тегом?
-- expect: value 1
BEGIN;

-- Проверяем связь до удаления
SELECT
    m.title AS meme,
    t.name AS tag
FROM meme_tags mt
JOIN memes m ON m.id = mt.meme_id
JOIN tags t ON t.id = mt.tag_id
WHERE mt.meme_id = 1
  AND mt.tag_id = 1;

-- Удаляем связь
DELETE FROM meme_tags
WHERE meme_id = 1
  AND tag_id = 1
RETURNING meme_id, tag_id;

-- Проверяем, что связь удалена
SELECT COUNT(*) AS links_after_delete
FROM meme_tags
WHERE meme_id = 1
  AND tag_id = 1;

ROLLBACK;

-- Проверяем, что связь восстановлена
SELECT COUNT(*) AS links_after_rollback
FROM meme_tags
WHERE meme_id = 1
  AND tag_id = 1;

  -- 13. Какие три последних добавленных мема есть в каждой категории?
-- expect: rows 18
WITH ranked_memes AS (
    SELECT
        t.name AS category,
        m.id AS meme_id,
        m.title,
        m.created_at,
        ROW_NUMBER() OVER (
            PARTITION BY t.id
            ORDER BY m.created_at DESC, m.id DESC
        ) AS position
    FROM tags t
    JOIN meme_tags mt ON mt.tag_id = t.id
    JOIN memes m ON m.id = mt.meme_id
)
SELECT
    category,
    meme_id,
    title,
    position
FROM ranked_memes
WHERE position <= 3
ORDER BY category, position;

-- 14. Какой мем был опубликован перед каждым мемом?
-- expect: rows 10
SELECT
    r.id AS repost_id,
    m.title AS current_meme,
    r.platform,
    r.reposted_at,
    LAG(m.title) OVER (
        ORDER BY r.reposted_at, r.id
    ) AS previous_meme,
    LAG(r.platform) OVER (
        ORDER BY r.reposted_at, r.id
    ) AS previous_platform
FROM reposts r
JOIN memes m ON m.id = r.meme_id
ORDER BY r.reposted_at, r.id;

-- 15. Сколько мемов по каждому тегу имеют репосты в Instagram и реакцию laugh?
-- expect: rows 10
WITH meme_activity AS (
    SELECT
        mt.tag_id,
        m.id AS meme_id,
        EXISTS (
            SELECT 1
            FROM reposts r
            WHERE r.meme_id = m.id
              AND r.platform = 'instagram'
        ) AS has_instagram_repost,
        EXISTS (
            SELECT 1
            FROM reactions r
            WHERE r.meme_id = m.id
              AND r.reaction_type = 'laugh'
        ) AS has_laugh_reaction
    FROM meme_tags mt
    JOIN memes m ON m.id = mt.meme_id
)
SELECT
    t.name AS tag,
    COUNT(ma.meme_id) AS memes_total,
    COUNT(*) FILTER (
        WHERE ma.has_instagram_repost
    ) AS memes_with_instagram,
    COUNT(*) FILTER (
        WHERE ma.has_laugh_reaction
    ) AS memes_with_laugh,
    COALESCE(
        ROUND(
            100.0 * COUNT(*) FILTER (
                WHERE ma.has_instagram_repost
            ) / NULLIF(COUNT(ma.meme_id), 0),
            1
        ),
        0
    ) AS instagram_percent
FROM tags t
LEFT JOIN meme_activity ma ON ma.tag_id = t.id
GROUP BY t.id, t.name
ORDER BY t.name;