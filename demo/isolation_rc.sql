
-- Лаба 4: проверка уровня изоляции READ COMMITTED.

-- [setup]
-- Создаём отдельный тестовый мем с начальным индексом 100.
DELETE FROM memes
WHERE title = 'lab4_isolation_rc_test';

INSERT INTO memes (
    title, description, media_url, author_id, template_id, viral_index
)
SELECT
    'lab4_isolation_rc_test',
    description,
    media_url,
    author_id,
    template_id,
    100
FROM memes
WHERE id = 1;

-- [A]
-- Начинаем транзакцию с уровнем READ COMMITTED.
BEGIN ISOLATION LEVEL READ COMMITTED;

-- Первое чтение: индекс равен 100.
SELECT viral_index
FROM memes
WHERE title = 'lab4_isolation_rc_test';
-- expect: value 100

-- [B]
-- Другое подключение изменяет индекс и фиксирует транзакцию.
BEGIN;

UPDATE memes
SET viral_index = 200
WHERE title = 'lab4_isolation_rc_test';

COMMIT;

-- [A]
-- Второе чтение видит новое зафиксированное значение 200.
SELECT viral_index
FROM memes
WHERE title = 'lab4_isolation_rc_test';
-- expect: value 200

COMMIT;

-- [cleanup]
DELETE FROM memes
WHERE title = 'lab4_isolation_rc_test';
