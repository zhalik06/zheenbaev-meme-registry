
-- Лаба 4: проверка взаимной блокировки.

-- [setup]
-- Создаём два отдельных тестовых мема.
DELETE FROM memes
WHERE title IN (
    'lab4_deadlock_test_a',
    'lab4_deadlock_test_b',
    'lab4_deadlock_test_a_locked',
    'lab4_deadlock_test_b_locked'
);

INSERT INTO memes (
    title, description, media_url, author_id, template_id, viral_index
)
SELECT
    'lab4_deadlock_test_a',
    description,
    media_url,
    author_id,
    template_id,
    0
FROM memes
WHERE id = 1;

INSERT INTO memes (
    title, description, media_url, author_id, template_id, viral_index
)
SELECT
    'lab4_deadlock_test_b',
    description,
    media_url,
    author_id,
    template_id,
    0
FROM memes
WHERE id = 1;

-- [A]
-- Окно A блокирует первый мем.
BEGIN;

UPDATE memes
SET title = 'lab4_deadlock_test_a_locked'
WHERE title = 'lab4_deadlock_test_a';

-- [B]
-- Окно B блокирует второй мем.
BEGIN;

UPDATE memes
SET title = 'lab4_deadlock_test_b_locked'
WHERE title = 'lab4_deadlock_test_b';

-- [A]
-- Окно A пытается изменить второй мем и ожидает блокировку окна B.
UPDATE memes
SET description = 'Изменено окном A'
WHERE id = (
    SELECT id
    FROM memes
    WHERE title = 'lab4_deadlock_test_b'
);

-- [B]
-- Окно B пытается изменить первый мем.
-- Возникает взаимная блокировка.
UPDATE memes
SET description = 'Изменено окном B'
WHERE id = (
    SELECT id
    FROM memes
    WHERE title = 'lab4_deadlock_test_a'
);
-- expect: error deadlock

-- [A]
-- Окно A завершает транзакцию после отмены запроса окна B.
COMMIT;

-- [B]
-- Окно B откатывает прерванную транзакцию.
ROLLBACK;

-- [cleanup]
-- Удаляем тестовые мемы.
DELETE FROM memes
WHERE title IN (
    'lab4_deadlock_test_a',
    'lab4_deadlock_test_b',
    'lab4_deadlock_test_a_locked',
    'lab4_deadlock_test_b_locked'
);
