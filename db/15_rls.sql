
-- Лаба 4: настройка Row Level Security.

-- Создаём роли для проверки доступа авторов.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = 'rls_author_1'
    ) THEN
        CREATE ROLE rls_author_1 NOLOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = 'rls_author_2'
    ) THEN
        CREATE ROLE rls_author_2 NOLOGIN;
    END IF;
END;
$$;

-- Разрешаем ролям читать таблицу мемов.
GRANT USAGE ON SCHEMA public TO rls_author_1, rls_author_2;
GRANT SELECT ON memes TO rls_author_1, rls_author_2;

-- Включаем защиту на уровне строк.
ALTER TABLE memes ENABLE ROW LEVEL SECURITY;

-- Удаляем политику, если она уже существует.
DROP POLICY IF EXISTS memes_author_access ON memes;

-- Каждая роль видит только мемы своего автора.
CREATE POLICY memes_author_access
ON memes
FOR SELECT
USING (
    (current_user = 'rls_author_1' AND author_id = 1)
    OR
    (current_user = 'rls_author_2' AND author_id = 2)
);
