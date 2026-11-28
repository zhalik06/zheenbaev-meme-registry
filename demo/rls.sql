
-- Лаба 4: проверка Row Level Security.

-- 1. Проверяем, что первый автор видит только свои мемы.
SET ROLE rls_author_1;

SELECT count(*) FROM memes;
-- expect: value 1

RESET ROLE;

-- 2. Проверяем, что второй автор видит только свои мемы.
SET ROLE rls_author_2;

SELECT count(*) FROM memes;
-- expect: value 1

RESET ROLE;

-- 3. Проверяем, что суперпользователь видит все мемы.
SELECT count(*) FROM memes;
-- expect: value 10
