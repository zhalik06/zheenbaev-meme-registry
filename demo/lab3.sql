-- Lab 3: database logic for Meme Registry
-- The scenario runner rolls the whole file back at the end.

-- 1. Карточки мемов: автор и шаблон
-- expect: rows >= 10
SELECT *
FROM v_meme_cards
ORDER BY meme_id;

-- 2. Статистика активности по каждому мему
-- expect: rows >= 10
SELECT *
FROM v_meme_engagement
ORDER BY meme_id;

-- 3. Расчёт индекса вирусности: 10 баллов за репост и 1 за реакцию
-- expect: value 11
SELECT meme_viral_score(1);

-- 4. Бизнес-операция одной командой: зарегистрировать репост
-- expect: rows 1
SELECT register_repost(1, 'instagram') AS new_repost_id;

-- 5. После репоста триггер пересчитал индекс (два репоста и одна реакция)
-- expect: value 21
SELECT viral_index
FROM memes
WHERE id = 1;

-- 6. Нельзя зарегистрировать активность для несуществующего мема
-- expect: error "не найден"
INSERT INTO reposts (meme_id, platform)
VALUES (999999, 'instagram');

-- 7. Обновить материализованный отчёт и прочитать результат
-- expect: rows >= 1
REFRESH MATERIALIZED VIEW mv_monthly_meme_report;
SELECT *
FROM mv_monthly_meme_report
ORDER BY month;

-- 8. Поиск мемов с фильтром по тегу; остальные фильтры можно не задавать
-- expect: rows >= 1
SELECT *
FROM search_memes(p_tag => 'programming', p_min_viral => 0);

-- 9. Служебный триггер меняет updated_at при UPDATE
-- expect: rows 1
SELECT id, updated_at AS before_update
FROM memes
WHERE id = 2;

UPDATE memes
SET description = concat(COALESCE(description, ''), ' [lab3 test]')
WHERE id = 2;

SELECT id, updated_at AS after_update
FROM memes
WHERE id = 2;

-- 10. Журнал хранит JSON-снимок, пользователя и время изменения
-- expect: rows >= 1
SELECT operation, old_data, new_data, changed_by, changed_at
FROM meme_audit_log
WHERE meme_id = 2
ORDER BY id;

-- 11. Состояние мема на текущий момент по журналу изменений
-- expect: rows 1
SELECT meme_state_at(2, clock_timestamp()) AS meme_state;
