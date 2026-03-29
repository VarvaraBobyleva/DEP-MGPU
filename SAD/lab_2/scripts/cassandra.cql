-- 1. Создание пространства ключей (аналог базы данных)
CREATE KEYSPACE IF NOT EXISTS streaming_logs 
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

-- 2. Переключение на созданное пространство
USE streaming_logs;

-- 3. Создание таблицы логов активности пользователей
-- user_id - идентификатор пользователя
-- timestamp - время события
-- action - само действие (play, stop, pause и т.д.)
CREATE TABLE IF NOT EXISTS logs (
    user_id int,
    timestamp timestamp,
    action text,
    PRIMARY KEY (user_id, timestamp)
) WITH CLUSTERING ORDER BY (timestamp DESC);

-- 4. Наполнение тестовыми данными (Задание 1)
INSERT INTO logs (user_id, timestamp, action) VALUES (1, toTimestamp(now()), 'play_movie_101');
INSERT INTO logs (user_id, timestamp, action) VALUES (1, toTimestamp(now()), 'pause_movie_101');
INSERT INTO logs (user_id, timestamp, action) VALUES (2, toTimestamp(now()), 'view_movie_102');
INSERT INTO logs (user_id, timestamp, action) VALUES (1, toTimestamp(now()), 'stop_movie_101');
INSERT INTO logs (user_id, timestamp, action) VALUES (3, toTimestamp(now()), 'view_movie_104');

-- 5. Дополнительные данные для расширенной аналитики (Задание 3)
INSERT INTO logs (user_id, timestamp, action) VALUES (4, toTimestamp(now()), 'play_movie_106');
INSERT INTO logs (user_id, timestamp, action) VALUES (5, toTimestamp(now()), 'play_movie_108');
INSERT INTO logs (user_id, timestamp, action) VALUES (1, toTimestamp(now()), 'rate_movie_106');
INSERT INTO logs (user_id, timestamp, action) VALUES (6, toTimestamp(now()), 'play_movie_102');
INSERT INTO logs (user_id, timestamp, action) VALUES (7, toTimestamp(now()), 'play_movie_110');

-- 6. Проверка данных
SELECT * FROM logs LIMIT 10;
