
-- Lab 1: Meme Registry error tests

-- 1. Duplicate author username
-- expect: error unique
INSERT INTO authors (display_name, username)
VALUES ('Another Alex', 'alex_memes');

-- 2. Negative viral index
-- expect: error check
INSERT INTO memes
    (title, media_url, author_id, template_id, viral_index)
VALUES
    ('Invalid viral index',
     'https://example.com/invalid.jpg',
     1, 1, -1);

-- 3. Reference to a non-existent author
-- expect: error fk
INSERT INTO memes
    (title, media_url, author_id, template_id)
VALUES
    ('Missing author',
     'https://example.com/missing.jpg',
     999999, 1);
