-- Lab 3: views and materialized report for Meme Registry

-- Service timestamp for the main table. Existing rows receive the current time.
ALTER TABLE memes
    ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT clock_timestamp();

-- A compact card for the meme catalogue.
CREATE OR REPLACE VIEW v_meme_cards AS
SELECT
    m.id AS meme_id,
    m.title,
    m.description,
    m.media_url,
    a.id AS author_id,
    a.display_name AS author_name,
    a.username,
    t.name AS template_name,
    m.viral_index,
    m.created_at,
    m.updated_at
FROM memes m
JOIN authors a ON a.id = m.author_id
JOIN templates t ON t.id = m.template_id;

-- Engagement counters are aggregated separately to avoid multiplying rows
-- when a meme has several reposts, reactions, and tags.
CREATE OR REPLACE VIEW v_meme_engagement AS
SELECT
    m.id AS meme_id,
    m.title,
    m.viral_index,
    COALESCE(r.reposts_count, 0) AS reposts_count,
    COALESCE(rx.reactions_count, 0) AS reactions_count,
    COALESCE(mt.tags_count, 0) AS tags_count
FROM memes m
LEFT JOIN (
    SELECT meme_id, count(*) AS reposts_count
    FROM reposts
    GROUP BY meme_id
) r ON r.meme_id = m.id
LEFT JOIN (
    SELECT meme_id, count(*) AS reactions_count
    FROM reactions
    GROUP BY meme_id
) rx ON rx.meme_id = m.id
LEFT JOIN (
    SELECT meme_id, count(*) AS tags_count
    FROM meme_tags
    GROUP BY meme_id
) mt ON mt.meme_id = m.id;

-- Monthly report: memes by creation month and engagement received by them.
DROP MATERIALIZED VIEW IF EXISTS mv_monthly_meme_report;
CREATE MATERIALIZED VIEW mv_monthly_meme_report AS
SELECT
    date_trunc('month', m.created_at)::date AS month,
    count(*) AS memes_count,
    COALESCE(sum(r.reposts_count), 0) AS reposts_count,
    COALESCE(sum(rx.reactions_count), 0) AS reactions_count,
    round(avg(m.viral_index)::numeric, 2) AS avg_viral_index
FROM memes m
LEFT JOIN (
    SELECT meme_id, count(*) AS reposts_count
    FROM reposts
    GROUP BY meme_id
) r ON r.meme_id = m.id
LEFT JOIN (
    SELECT meme_id, count(*) AS reactions_count
    FROM reactions
    GROUP BY meme_id
) rx ON rx.meme_id = m.id
GROUP BY date_trunc('month', m.created_at)::date;
