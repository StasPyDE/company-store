-- ТЕСТИРОВАНИЕ
-- Создаем простую функцию, которую буду использовать в тестах
SELECT safe_create('
CREATE OR REPLACE FUNCTION do_nothing()
RETURNS TEXT AS $$
BEGIN
    RETURN ''Привет, я ничего не умею делать :)'';
END;
$$ LANGUAGE plpgsql;
');

-- Проверяем появилась ли функция в таблице с бэкапом функций
SELECT * FROM functions_backup;

-- Создаем еще одну функцию с таким же именем, но только теперь с аргументом
SELECT safe_create('
CREATE OR REPLACE FUNCTION do_nothing(p_message TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN ''Привет, я ничего не умею делать :) '' || p_message;
END;
$$ LANGUAGE plpgsql;
');

-- Проверяем появилась ли новая функция в таблице с бэкапом функций
SELECT * FROM functions_backup;

-- Проверка выполнения функций после их создания оберткой
-- Первая функция
SELECT do_nothing();

-- Вторая функция
SELECT do_nothing('Хотя немного умею :D')

-- Попробуем изменить одну из функций разными способам
-- 1 способ: поменять возвращаемый текст
SELECT safe_create('
CREATE OR REPLACE FUNCTION do_nothing()
RETURNS TEXT AS $$
BEGIN
    RETURN ''Привет, я ВООБЩЕ ничего не умею делать :)'';
END;
$$ LANGUAGE plpgsql;
');

-- 2 способ: использовать переменные
SELECT safe_create('
CREATE OR REPLACE FUNCTION do_nothing()
RETURNS TEXT AS $$
DECLARE
    v_greeting TEXT := ''Привет, я умею использовать переменные!'';
BEGIN
    RETURN v_greeting;
END;
$$ LANGUAGE plpgsql;
');

-- 3 способ: сделать IMMUTABLE
SELECT safe_create('
CREATE OR REPLACE FUNCTION do_nothing()
RETURNS TEXT
IMMUTABLE  -- <-- Правильный атрибут
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN "Привет, я ничего не умею делать :)";
END;
$$;
');

-- 4 способ: изменить язык с plpgsql на sql
SELECT safe_create('
CREATE OR REPLACE FUNCTION do_nothing()
RETURNS TEXT
LANGUAGE sql
AS $$
    SELECT ''Привет от SQL функции!'';
$$');

-- 5 способ: добавить еще одну функцию с таким же именем но другими аргументами
SELECT safe_create('
CREATE OR REPLACE FUNCTION do_nothing(a INT, b INT)
RETURNS TEXT AS $$
BEGIN
    RETURN ''Сумма: '' || (a + b) || ''. Кроме это я ничего не умею делать :)'';
END;
$$ LANGUAGE plpgsql;
');

-- А что если выполнить 4 способ еще раз?
-- 4 способ: изменить язык с plpgsql на sql
SELECT safe_create('
CREATE OR REPLACE FUNCTION do_nothing()
RETURNS TEXT
LANGUAGE sql
AS $$
    SELECT ''Привет от SQL функции!'';
$$');

-- В таком случае ничего не должно поменяться в таблице functions_backup

-- Проверяем появились ли новые версии 
-- Должно быть 5 версий у функции do_nothing без аргументов
-- 1 версия у функции do_nothing с 1 аргументом
-- 1 версия у функции do_nothing с 2 аргументами
SELECT * FROM functions_backup
WHERE function_name = 'do_nothing';

-- Проверка удаления функций
SELECT safe_drop('
DROP FUNCTION IF EXISTS do_nothing();
');

SELECT safe_drop('DROP FUNCTION do_nothing(a integer, b integer);');

SELECT safe_drop('DROP FUNCTION do_nothing(p_message text);');

-- Попытка удаления несуществующей функции
SELECT safe_drop('DROP FUNCTION do_dont();');

-- Проверка восстановления функций
SELECT restore_function('do_nothing', 3, 'simbirstore_test', '');

SELECT restore_function('do_nothing', 5, 'simbirstore_test', '');

SELECT restore_function('do_nothing', 1, 'simbirstore_test', 'p_message text')

SELECT restore_function('do_nothing', 1, 'simbirstore_test', 'a integer, b integer')

-- Попытка восстановления несуществующей функции
SELECT restore_function('do_dont', 1, 'simbirstore_test', '');

-- Попытка совершить другую DDL-операции через функцию safe_create()
SELECT safe_create('CREATE TABLE test_table (id INT);');

-- Попытка совершить другие DDL-операции через функцию safe_drop()
SELECT safe_drop('DROP TABLE test_table;');

-- Зачем использовать CRON:
-- На случай если разработчик забыл использовать обертку:
-- При создании
CREATE OR REPLACE FUNCTION do_nothing()
RETURNS TEXT AS $$
BEGIN
    RETURN 'Создание функции без обертки';
END;
$$ LANGUAGE plpgsql;

-- При удалении
DROP FUNCTION do_nothing();

-- CRON запустится и сделает автоматический бэкап:
SELECT backup_all_functions();

-- Без оберток проблема CRON в том, что бэкап не мгновенный и имеются задержки. Из-за этого изменения могут быть пропущены.
