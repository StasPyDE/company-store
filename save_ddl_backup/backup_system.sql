-- Создание способа сохранения DDL функций

-- Таблица для бэкапа, в которой хранятся версии функций
DROP TABLE IF EXISTS simbirstore_test.functions_backup;
CREATE TABLE IF NOT EXISTS simbirstore_test.functions_backup (
    id SERIAL PRIMARY KEY,
    schema_name TEXT NOT NULL,
    function_name TEXT NOT NULL,
    function_args TEXT NOT NULL DEFAULT '',
    ddl TEXT NOT NULL,
    ddl_hash TEXT,
    version INTEGER DEFAULT 1,
    backup_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_current BOOLEAN DEFAULT TRUE,
    created_by TEXT DEFAULT current_user,
    UNIQUE(schema_name, function_name, function_args, version)
);

COMMENT ON TABLE simbirstore_test.functions_backup IS 
'Хранит историю версий всех созданных функций для возможности восстановления';

COMMENT ON COLUMN simbirstore_test.functions_backup.schema_name IS 'Схема функции';
COMMENT ON COLUMN simbirstore_test.functions_backup.function_name IS 'Имя функции';
COMMENT ON COLUMN simbirstore_test.functions_backup.function_args IS 'Аргументы функции (сигнатура)';
COMMENT ON COLUMN simbirstore_test.functions_backup.ddl IS 'DDL функции (CREATE OR REPLACE...)';
COMMENT ON COLUMN simbirstore_test.functions_backup.ddl_hash IS 'MD5 хеш DDL для отслеживания изменений';
COMMENT ON COLUMN simbirstore_test.functions_backup.version IS 'Номер версии функции';
COMMENT ON COLUMN simbirstore_test.functions_backup.backup_date IS 'Дата и время создания бэкапа';
COMMENT ON COLUMN simbirstore_test.functions_backup.is_current IS 'TRUE - текущая версия, FALSE - историческая';
COMMENT ON COLUMN simbirstore_test.functions_backup.created_by IS 'Пользователь, создавший эту версию';



-- Основная функция бэкапа всех функций
CREATE OR REPLACE FUNCTION simbirstore_test.backup_all_functions(p_schema TEXT DEFAULT 'simbirstore_test')
RETURNS TEXT AS $$
DECLARE
    v_func RECORD;
    v_new_hash TEXT;
    v_current_hash TEXT;
    v_max_version INTEGER;
    v_count INTEGER := 0;
    v_existing_id INTEGER;
    v_existing_version INTEGER;
BEGIN
    FOR v_func IN 
        SELECT 
            n.nspname as schema_name,
            p.proname as function_name,
            pg_get_function_arguments(p.oid) as args,
            pg_get_functiondef(p.oid) as ddl
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        JOIN pg_language l ON p.prolang = l.oid
        WHERE n.nspname = p_schema 
          AND l.lanname != 'c'
    LOOP
        v_new_hash := MD5(v_func.ddl);
        
        -- Проверяем, не изменилась ли функция
        SELECT ddl_hash INTO v_current_hash
        FROM simbirstore_test.functions_backup
        WHERE schema_name = v_func.schema_name
          AND function_name = v_func.function_name
          AND function_args = v_func.args
          AND is_current = TRUE
        LIMIT 1;
        
        -- Если не изменилась — пропускаем
        IF v_current_hash IS NOT NULL AND v_current_hash = v_new_hash THEN
            CONTINUE;
        END IF;
        
        -- Проверяем, есть ли функция в бэкапе (даже если is_current = FALSE)
        SELECT id, version INTO v_existing_id, v_existing_version
        FROM simbirstore_test.functions_backup
        WHERE schema_name = v_func.schema_name
          AND function_name = v_func.function_name
          AND function_args = v_func.args
          AND ddl_hash = v_new_hash
        ORDER BY version DESC
        LIMIT 1;
        
        -- Если функция уже есть в бэкапе с таким же хешем
        IF v_existing_id IS NOT NULL THEN
            -- Просто обновляем is_current = TRUE
            UPDATE simbirstore_test.functions_backup
            SET is_current = TRUE,
                backup_date = CURRENT_TIMESTAMP
            WHERE id = v_existing_id;
            
            -- Снимаем is_current со всех остальных версий
            UPDATE simbirstore_test.functions_backup
            SET is_current = FALSE
            WHERE schema_name = v_func.schema_name
              AND function_name = v_func.function_name
              AND function_args = v_func.args
              AND id != v_existing_id
              AND is_current = TRUE;
            
            v_count := v_count + 1;
            CONTINUE;
        END IF;
        
        -- Получаем следующую версию
        SELECT COALESCE(MAX(version), 0) + 1 INTO v_max_version
        FROM simbirstore_test.functions_backup
        WHERE schema_name = v_func.schema_name
          AND function_name = v_func.function_name
          AND function_args = v_func.args;
        
        -- Снимаем флаг текущей версии
        UPDATE simbirstore_test.functions_backup
        SET is_current = FALSE
        WHERE schema_name = v_func.schema_name
          AND function_name = v_func.function_name
          AND function_args = v_func.args
          AND is_current = TRUE;
        
        -- Сохраняем новую версию
        INSERT INTO simbirstore_test.functions_backup (schema_name, function_name, function_args, ddl, ddl_hash, version, is_current)
        VALUES (v_func.schema_name, v_func.function_name, v_func.args, v_func.ddl, v_new_hash, v_max_version, TRUE);
        
        v_count := v_count + 1;
    END LOOP;
    
    RETURN format('Бэкап завершен. Изменений сделано: %s', v_count);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION simbirstore_test.backup_all_functions(TEXT) IS 'Бэкап всех функций в схеме. Возвращает количество обновленных версий';



-- Функция восстановления функций
CREATE OR REPLACE FUNCTION simbirstore_test.restore_function(
    p_func_name TEXT,
    p_version INTEGER,
    p_schema TEXT DEFAULT 'simbirstore_test',
    p_args TEXT DEFAULT ''
) RETURNS TEXT AS $$
DECLARE
    v_ddl TEXT;
    v_current_version INTEGER;
BEGIN
	p_args := LOWER(p_args);

    -- Проверяем существование функции в бэкапе
    SELECT ddl INTO v_ddl
    FROM simbirstore_test.functions_backup
    WHERE schema_name = p_schema
      AND function_name = p_func_name
      AND function_args = p_args
      AND version = p_version;
    
    IF v_ddl IS NULL THEN
        RETURN format('Функция %s.%s(%s) версии %s не найдена в бэкапе', 
                      p_schema, p_func_name, p_args, p_version);
    END IF;
    
    -- Проверяем, существует ли функция сейчас в БД
    SELECT p.oid INTO v_current_version
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = p_schema
      AND p.proname = p_func_name
      AND pg_get_function_arguments(p.oid) = p_args;
    
    -- Восстанавливаем функцию (DDL уже содержит CREATE OR REPLACE)
    BEGIN
        EXECUTE v_ddl;
        
        -- сначала снимаем is_current со всех версий этой функции
        UPDATE simbirstore_test.functions_backup
        SET is_current = FALSE
        WHERE schema_name = p_schema 
          AND function_name = p_func_name 
          AND function_args = p_args;
        
        -- Затем устанавливаем is_current только для восстановленной версии
        UPDATE simbirstore_test.functions_backup
        SET is_current = TRUE
        WHERE schema_name = p_schema 
          AND function_name = p_func_name 
          AND function_args = p_args 
          AND version = p_version;
        
        RETURN format('Функция %s.%s(%s) успешно восстановлена до версии %s', 
                      p_schema, p_func_name, p_args, p_version);
    EXCEPTION WHEN OTHERS THEN
        -- В случае ошибки восстанавливаем предыдущее состояние is_current
        IF v_current_version IS NOT NULL THEN
            -- Если функция существовала, оставляем последнюю актуальную версию
            UPDATE simbirstore_test.functions_backup
            SET is_current = TRUE
            WHERE schema_name = p_schema 
              AND function_name = p_func_name 
              AND function_args = p_args 
              AND version = (
                  SELECT MAX(version) 
                  FROM simbirstore_test.functions_backup
                  WHERE schema_name = p_schema 
                    AND function_name = p_func_name 
                    AND function_args = p_args
              );
        END IF;
        
        RETURN format('Ошибка при восстановлении функции: %s', SQLERRM);
    END;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION simbirstore_test.restore_function(TEXT, INTEGER, TEXT, TEXT) IS 
'Восстанавливает функцию из бэкапа по версии. Параметры: имя_функции, версия, схема, аргументы';



-- Функция для создания функций с авто-бэкапом
CREATE OR REPLACE FUNCTION simbirstore_test.safe_create(p_ddl TEXT)
RETURNS TEXT AS $$
BEGIN
    -- Проверяем, что это CREATE FUNCTION
    IF p_ddl !~* 'CREATE\s+(OR\s+REPLACE\s+)?FUNCTION' THEN
        RETURN 'Ошибка: DDL должен содержать CREATE [OR REPLACE] FUNCTION';
    END IF;
    
    -- Выполняем DDL
    EXECUTE p_ddl;
    
    -- Делаем бэкап
    RETURN simbirstore_test.backup_all_functions();
EXCEPTION WHEN OTHERS THEN
    RETURN format('Ошибка при создании функции: %s', SQLERRM);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION simbirstore_test.safe_create(TEXT) IS 
'Безопасное создание функции с автоматическим бэкапом. Принимает DDL CREATE FUNCTION';



-- Обертка для удаления функций
CREATE OR REPLACE FUNCTION simbirstore_test.safe_drop(p_ddl TEXT)
RETURNS TEXT AS $$
DECLARE
    v_func_name TEXT;
    v_func_args TEXT;
    v_schema TEXT := 'simbirstore_test';
    v_updated INTEGER;
    v_clean_ddl TEXT;
    v_temp TEXT;
BEGIN
    -- Проверяем, что это DROP FUNCTION
    IF p_ddl !~* 'DROP\s+FUNCTION\s' THEN
        RETURN 'Ошибка: разрешено только DROP FUNCTION';
    END IF;
    
    -- Очищаем DDL от IF EXISTS и лишних пробелов
    v_clean_ddl := regexp_replace(p_ddl, 'IF\s+EXISTS\s+', '', 'gi');
    v_clean_ddl := regexp_replace(v_clean_ddl, '\s+', ' ', 'g');
    
    -- Извлекаем имя функции (между DROP FUNCTION и скобкой)
    v_temp := substring(v_clean_ddl FROM 'DROP\s+FUNCTION\s+([^\(]+)');
    IF v_temp IS NOT NULL THEN
        v_func_name := trim(v_temp);
    ELSE
        -- пытаемся извлечь по-другому
        v_func_name := substring(v_clean_ddl FROM 'DROP\s+FUNCTION\s+([^\s]+)');
    END IF;
    
    -- Извлекаем аргументы (все что внутри скобок)
	v_func_args := LOWER(COALESCE(
        trim(substring(v_clean_ddl FROM '\(([^)]*)\)')),
        ''
    ));

    -- Если имя содержит схему то разделяем
    IF v_func_name LIKE '%.%' THEN
        v_schema := split_part(v_func_name, '.', 1);
        v_func_name := split_part(v_func_name, '.', 2);
    END IF;

    -- Выполняем DROP (оригинальный DDL)
    EXECUTE p_ddl;
    
    -- Обновляем is_current
    UPDATE simbirstore_test.functions_backup
    SET is_current = FALSE
    WHERE schema_name = v_schema
      AND function_name = v_func_name
      AND function_args = v_func_args
      AND is_current = TRUE;
    
    -- Проверяем результат
    GET DIAGNOSTICS v_updated = ROW_COUNT;
    
    IF v_updated = 0 THEN
        RETURN format('Функция %s.%s(%s) удалена, но не найдена в бэкапе', 
                      v_schema, v_func_name, v_func_args);
    END IF;
    
    RETURN format('Функция %s.%s(%s) удалена и установлено is_current = FALSE', 
                  v_schema, v_func_name, v_func_args);
EXCEPTION WHEN OTHERS THEN
    RETURN format('Ошибка: %s', SQLERRM);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION simbirstore_test.safe_drop(TEXT) IS 
'Безопасное удаление функции с автоматическим бэкапом. Принимает DDL DROP FUNCTION';



-- Создаем функцию для проверки удаленных функций
CREATE OR REPLACE FUNCTION simbirstore_test.mark_deleted_functions(p_schema TEXT DEFAULT 'simbirstore_test')
RETURNS TEXT AS $$
DECLARE
    v_count INTEGER := 0;
BEGIN
    -- Обновляем is_current = FALSE для удаленных функций
    UPDATE simbirstore_test.functions_backup
    SET is_current = FALSE,
        backup_date = CURRENT_TIMESTAMP
    WHERE schema_name = p_schema
      AND is_current = TRUE
      AND NOT EXISTS (
          SELECT 1 FROM pg_proc p
          JOIN pg_namespace n ON p.pronamespace = n.oid
          WHERE n.nspname = functions_backup.schema_name
            AND p.proname = functions_backup.function_name
            AND pg_get_function_arguments(p.oid) = functions_backup.function_args
      );
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    
    RETURN format('Помечено как удаленные: %s', v_count);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION simbirstore_test.mark_deleted_functions(TEXT) IS 
'Помечает удаленные функции как is_current = FALSE. Используется в cron';



-- Настройка CRON (запуск раз в 5 минут)
SELECT cron.schedule(
    'backup-all-functions',
    '*/5 * * * *',
    $$
    SELECT simbirstore_test.backup_all_functions();
    SELECT simbirstore_test.mark_deleted_functions();
    $$
);
