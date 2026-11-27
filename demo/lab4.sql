
-- Lab 4: transactions and application roles.

-- 1. Remember the number of reposts before the transaction.
SELECT count(*) AS reposts_before
FROM reposts
WHERE meme_id = 1;

-- 2. Transaction fails on the second insert.
BEGIN;

INSERT INTO reposts (meme_id, platform)
VALUES (1, 'instagram');

INSERT INTO reposts (meme_id, platform)
VALUES (1, 'invalid_platform');

COMMIT;
-- expect: error check

-- 3. Verify that the repost count did not change.
SELECT count(*)
FROM reposts
WHERE meme_id = 1;
-- expect: same 1

-- 4. Test app_reader can read views.
SET ROLE app_reader;

SELECT * FROM v_meme_cards LIMIT 1;

SELECT * FROM v_meme_engagement LIMIT 1;

RESET ROLE;

-- 5. Test that app_reader cannot modify data.
SET ROLE app_reader;

INSERT INTO memes (title, author_id)
VALUES ('forbidden_reader_insert', 1);
-- expect: error

RESET ROLE;

-- 6. Test app_writer can call the business function.
SET ROLE app_writer;

SELECT register_repost(1, 'instagram');

RESET ROLE;

-- 7. Test that app_writer cannot modify tables directly.
SET ROLE app_writer;

UPDATE memes
SET title = 'forbidden_writer_update'
WHERE id = 1;
-- expect: error

RESET ROLE;
