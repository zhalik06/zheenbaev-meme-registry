-- [setup]
-- Prepare a separate test meme.
DELETE FROM memes
WHERE title = 'lab4_race_fixed_test';

INSERT INTO memes (
    title, description, media_url, author_id, template_id, viral_index
)
SELECT
    'lab4_race_fixed_test',
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
    (SELECT id FROM memes WHERE title = 'lab4_race_fixed_test'),
    'instagram'
);

-- [B]
BEGIN;

SELECT register_repost(
    (SELECT id FROM memes WHERE title = 'lab4_race_fixed_test'),
    'reddit'
);
-- expect: blocked

-- [A]
COMMIT;

-- [B]
COMMIT;

-- [check]
SELECT (
    (SELECT viral_index
     FROM memes
     WHERE title = 'lab4_race_fixed_test')
    =
    meme_viral_score(
        (SELECT id
         FROM memes
         WHERE title = 'lab4_race_fixed_test')
    )
) AS rule_holds;
-- expect: true

-- [cleanup]
DELETE FROM memes
WHERE title = 'lab4_race_fixed_test';