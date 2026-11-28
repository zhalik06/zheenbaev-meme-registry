
-- Лаба 4: проверка уровня изоляции REPEATABLE READ.

-- [setup]
-- Создаём отдельный тестовый мем с начальным индексом 100.
DELETE FROM memes
WHERE title = 'lab4_isolation_rr_test';

INSERT INTO memes (
    title, description, media_url, author_id, template_id, viral_index
)
SELECT
    'lab4_isolation_rr_test',
    description,
    media_url,
    author_id,
    template_id,
    100
FROM memes
WHERE id = 1;

-- [A]
-- Начинаем транзакцию с уровнем REPEATABLE READ.
BEGIN ISOLATION LEVEL REPEATABLE READ;

-- Первое чтение: индекс равен 100.
SELECT viral_index
FROM memes
WHERE title = 'lab4_isolation_rr_test';
-- expect: value 100

-- [B]
-- Другое подключение изменяет индекс и фиксирует транзакцию.
BEGIN;

UPDATE memes
SET viral_index = 200
WHERE title = 'lab4_isolation_rr_test';

COMMIT;

-- [A]
-- Второе чтение по-прежнему видит значение 100.
SELECT viral_index
FROM memes
WHERE title = 'lab4_isolation_rr_test';
-- expect: value 100

COMMIT;

-- [cleanup]
DELETE FROM memes
WHERE title = 'lab4_isolation_rr_test';
