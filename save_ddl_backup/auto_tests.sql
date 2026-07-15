-- ТЕСТИРОВАНИЕ СИСТЕМЫ БЭКАПА ФУНКЦИЙ

BEGIN;

DO $TEST$
DECLARE
    v_count INTEGER;
    v_version INTEGER;
    v_result TEXT;
    v_is_current BOOLEAN;
    v_func_name TEXT := 'do_nothing';
    v_schema TEXT := 'simbirstore_test';
BEGIN
    -- =============================================
    -- 1. Создание функции без аргументов
    -- =============================================
    RAISE NOTICE '1. Создание do_nothing()';
    
    PERFORM simbirstore_test.safe_create($FUNC$
    CREATE OR REPLACE FUNCTION simbirstore_test.do_nothing()
    RETURNS TEXT AS $$
    BEGIN
        RETURN 'Привет, я ничего не умею делать :)';
    END;
    $$ LANGUAGE plpgsql;
    $FUNC$);
    
    -- Проверка в таблице бэкапа
    SELECT COUNT(*) INTO v_count 
    FROM simbirstore_test.functions_backup 
    WHERE function_name = v_func_name 
      AND schema_name = v_schema
      AND function_args = '';
    
    ASSERT v_count = 1, 'do_nothing() не сохранилась в бэкапе. Ожидалось 1, получено ' || v_count;
    
    -- Проверка физического существования в pg_proc
    SELECT COUNT(*) INTO v_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = v_schema
      AND p.proname = v_func_name
      AND pg_get_function_arguments(p.oid) = '';
    
    ASSERT v_count = 1, 'do_nothing() физически не создана в pg_proc';
    
    -- Проверка выполнения
    SELECT simbirstore_test.do_nothing() INTO v_result;
    ASSERT v_result = 'Привет, я ничего не умею делать :)', 
        'Неверный результат do_nothing(): ' || v_result;
    
    RAISE NOTICE '✅ do_nothing() создана (бэкап + физически + выполняется)';

    -- =============================================
    -- 2. Создание функции с аргументом
    -- =============================================
    RAISE NOTICE '2. Создание do_nothing(p_message TEXT)';
    
    PERFORM simbirstore_test.safe_create($FUNC$
    CREATE OR REPLACE FUNCTION simbirstore_test.do_nothing(p_message TEXT)
    RETURNS TEXT AS $$
    BEGIN
        RETURN 'Привет, я ничего не умею делать :) ' || p_message;
    END;
    $$ LANGUAGE plpgsql;
    $FUNC$);
    
    -- Проверка в таблице бэкапа
    SELECT COUNT(*) INTO v_count 
    FROM simbirstore_test.functions_backup 
    WHERE function_name = v_func_name 
      AND schema_name = v_schema
      AND function_args = 'p_message text';
    
    ASSERT v_count = 1, 'do_nothing(TEXT) не сохранилась в бэкапе. Ожидалось 1, получено ' || v_count;
    
    -- Проверка физического существования в pg_proc
    SELECT COUNT(*) INTO v_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = v_schema
      AND p.proname = v_func_name
      AND pg_get_function_arguments(p.oid) = 'p_message text';
    
    ASSERT v_count = 1, 'do_nothing(TEXT) физически не создана в pg_proc';
    
    -- Проверка выполнения
    SELECT simbirstore_test.do_nothing('тест') INTO v_result;
    ASSERT v_result = 'Привет, я ничего не умею делать :) тест', 
        'Неверный результат do_nothing(TEXT): ' || v_result;
    
    RAISE NOTICE '✅ do_nothing(TEXT) создана (бэкап + физически + выполняется)';

    -- =============================================
    -- 3. Изменение функции (новая версия do_nothing())
    -- =============================================
    RAISE NOTICE '3. Изменение do_nothing() (версия 2)';
    
    PERFORM simbirstore_test.safe_create($FUNC$
    CREATE OR REPLACE FUNCTION simbirstore_test.do_nothing()
    RETURNS TEXT AS $$
    BEGIN
        RETURN 'Привет, я ВООБЩЕ ничего не умею делать :)';
    END;
    $$ LANGUAGE plpgsql;
    $FUNC$);
    
    -- Проверка в таблице бэкапа (должно быть 2 версии)
    SELECT COUNT(*) INTO v_count 
    FROM simbirstore_test.functions_backup 
    WHERE function_name = v_func_name 
      AND schema_name = v_schema
      AND function_args = '';
    
    ASSERT v_count = 2, 'Новая версия do_nothing() не создалась в бэкапе. Ожидалось 2, получено ' || v_count;
    
    -- Проверка физического существования (должна быть 1 функция в pg_proc)
    SELECT COUNT(*) INTO v_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = v_schema
      AND p.proname = v_func_name
      AND pg_get_function_arguments(p.oid) = '';
    
    ASSERT v_count = 1, 'do_nothing() должна физически существовать в единственном экземпляре в pg_proc';
    
    -- Проверка выполнения новой версии
    SELECT simbirstore_test.do_nothing() INTO v_result;
    ASSERT v_result = 'Привет, я ВООБЩЕ ничего не умею делать :)', 
        'Неверный результат do_nothing() версии 2: ' || v_result;
    
    RAISE NOTICE '✅ do_nothing() версия 2 создана (бэкап: 2 версии + физически: 1 функция + выполняется)';

    -- =============================================
    -- 4. Проверка количества is_current (актуальная версия)
    -- =============================================
    RAISE NOTICE '4. Проверка количества is_current';
    
    SELECT COUNT(*) INTO v_count 
    FROM simbirstore_test.functions_backup 
    WHERE function_name = v_func_name 
      AND schema_name = v_schema
      AND function_args = ''
      AND is_current = TRUE;
    
    ASSERT v_count = 1, 'У do_nothing() должна быть 1 актуальная версия в бэкапе. Найдено ' || v_count;
    
    SELECT COUNT(*) INTO v_count 
    FROM simbirstore_test.functions_backup 
    WHERE function_name = v_func_name 
      AND schema_name = v_schema
      AND function_args = 'p_message text'
      AND is_current = TRUE;
    
    ASSERT v_count = 1, 'У do_nothing(TEXT) должна быть 1 актуальная версия в бэкапе. Найдено ' || v_count;
    
    -- Проверка физического существования обеих функций
    SELECT COUNT(*) INTO v_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = v_schema
      AND p.proname = v_func_name;
    
    ASSERT v_count = 2, 'Должны физически существовать 2 функции do_nothing в pg_proc. Найдено ' || v_count;
    
    RAISE NOTICE '✅ Количество is_current корректно (бэкап + физически существуют обе функции)';

    -- =============================================
    -- 5. Проверка установки is_current
    -- =============================================
    RAISE NOTICE '5. Проверка установки is_current';
    
    SELECT version INTO v_version 
    FROM simbirstore_test.functions_backup 
    WHERE function_name = v_func_name 
      AND schema_name = v_schema
      AND function_args = ''
      AND is_current = TRUE;
    
    ASSERT v_version = 2, 'У do_nothing() должна быть актуальная версия = 2. Актуальная версия = ' || v_version;
    
    SELECT version INTO v_version 
    FROM simbirstore_test.functions_backup 
    WHERE function_name = v_func_name 
      AND schema_name = v_schema
      AND function_args = 'p_message text'
      AND is_current = TRUE;
    
    ASSERT v_version = 1, 'У do_nothing(TEXT) должна быть актуальная версия = 1. Актуальная версия = ' || v_version;
    
    -- Дополнительная проверка: выполняются правильные версии
    SELECT simbirstore_test.do_nothing() INTO v_result;
    ASSERT v_result = 'Привет, я ВООБЩЕ ничего не умею делать :)', 
        'Выполняется неверная версия do_nothing(): ' || v_result;
    
    SELECT simbirstore_test.do_nothing('проверка') INTO v_result;
    ASSERT v_result = 'Привет, я ничего не умею делать :) проверка', 
        'Выполняется неверная версия do_nothing(TEXT): ' || v_result;
    
    RAISE NOTICE '✅ is_current установлен корректно (версии совпадают с выполняемыми функциями)';

    -- =============================================
    -- 6. Тест safe_drop для do_nothing()
    -- =============================================
    RAISE NOTICE '6. Тест safe_drop для do_nothing()';
    
    -- Проверка физического существования до удаления
    SELECT COUNT(*) INTO v_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = v_schema
      AND p.proname = v_func_name
      AND pg_get_function_arguments(p.oid) = '';
    
    ASSERT v_count = 1, 'do_nothing() должна физически существовать до safe_drop';
    
    PERFORM simbirstore_test.safe_drop('DROP FUNCTION IF EXISTS simbirstore_test.do_nothing();');
    
    -- Проверяем, что после удаления нет активной (is_current = TRUE) версии в бэкапе
    SELECT COUNT(*) INTO v_count
    FROM simbirstore_test.functions_backup 
    WHERE function_name = v_func_name 
      AND schema_name = v_schema
      AND function_args = ''
      AND is_current = TRUE;
    
    ASSERT v_count = 0, 'do_nothing() не должна иметь is_current = TRUE в бэкапе после safe_drop. Найдено ' || v_count;
    
    -- Проверяем, что функция физически удалена из pg_proc
    SELECT COUNT(*) INTO v_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = v_schema
      AND p.proname = v_func_name
      AND pg_get_function_arguments(p.oid) = '';
    
    ASSERT v_count = 0, 'do_nothing() должна быть физически удалена из pg_proc. Найдено ' || v_count;
    
    RAISE NOTICE '✅ safe_drop для do_nothing() работает корректно (is_current=TRUE отсутствует + физически удалена)';

    -- =============================================
    -- 7. Тест safe_drop для do_nothing(TEXT)
    -- =============================================
    RAISE NOTICE '7. Тест safe_drop для do_nothing(p_message TEXT)';
    
    -- Проверка физического существования до удаления
    SELECT COUNT(*) INTO v_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = v_schema
      AND p.proname = v_func_name
      AND pg_get_function_arguments(p.oid) = 'p_message text';
    
    ASSERT v_count = 1, 'do_nothing(TEXT) должна физически существовать до safe_drop';
    
    PERFORM simbirstore_test.safe_drop('DROP FUNCTION IF EXISTS simbirstore_test.do_nothing(p_message text);');
    
    -- Проверяем, что после удаления нет активной (is_current = TRUE) версии в бэкапе
    SELECT COUNT(*) INTO v_count
    FROM simbirstore_test.functions_backup 
    WHERE function_name = v_func_name 
      AND schema_name = v_schema
      AND function_args = 'p_message text'
      AND is_current = TRUE;
    
    ASSERT v_count = 0, 'do_nothing(TEXT) не должна иметь is_current = TRUE в бэкапе после safe_drop. Найдено ' || v_count;
    
    -- Проверяем, что функция физически удалена из pg_proc
    SELECT COUNT(*) INTO v_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = v_schema
      AND p.proname = v_func_name
      AND pg_get_function_arguments(p.oid) = 'p_message text';
    
    ASSERT v_count = 0, 'do_nothing(TEXT) должна быть физически удалена из pg_proc. Найдено ' || v_count;
    
    RAISE NOTICE '✅ safe_drop для do_nothing(TEXT) работает корректно (is_current=TRUE отсутствует + физически удалена)';

    -- =============================================
    -- 8. Тест restore_function для do_nothing() версия 1
    -- =============================================
    RAISE NOTICE '8. Тест restore_function для do_nothing() версия 1';
    
    -- Проверяем, что функция физически отсутствует перед восстановлением
    SELECT COUNT(*) INTO v_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = v_schema
      AND p.proname = v_func_name
      AND pg_get_function_arguments(p.oid) = '';
    
    ASSERT v_count = 0, 'do_nothing() должна отсутствовать в pg_proc перед restore';
    
    PERFORM simbirstore_test.restore_function(v_func_name, 1, v_schema, '');
    
    -- Проверяем, что функция восстановлена физически в pg_proc
    SELECT COUNT(*) INTO v_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = v_schema
      AND p.proname = v_func_name
      AND pg_get_function_arguments(p.oid) = '';
    
    ASSERT v_count = 1, 'do_nothing() версия 1 должна быть физически восстановлена в pg_proc';
    
    -- Проверяем, что восстановленная версия стала текущей в бэкапе
    SELECT version INTO v_version
    FROM simbirstore_test.functions_backup 
    WHERE function_name = v_func_name 
      AND schema_name = v_schema
      AND function_args = ''
      AND is_current = TRUE;
    
    ASSERT v_version = 1, 'После восстановления do_nothing() актуальная версия в бэкапе должна быть 1. Сейчас: ' || v_version;
    
    -- Проверяем is_current
    SELECT is_current INTO v_is_current
    FROM simbirstore_test.functions_backup 
    WHERE function_name = v_func_name 
      AND schema_name = v_schema
      AND function_args = ''
      AND is_current = TRUE;
    
    ASSERT v_is_current = TRUE, 'Восстановленная do_nothing() должна быть активна в бэкапе';
    
    -- Проверяем выполнение восстановленной функции
    SELECT simbirstore_test.do_nothing() INTO v_result;
    ASSERT v_result = 'Привет, я ничего не умею делать :)', 
        'Неверный результат восстановленной функции: ' || v_result;
    
    RAISE NOTICE '✅ restore_function для do_nothing() версии 1 (физически восстановлена + бэкап + выполняется)';

    -- =============================================
    -- 9. Тест restore_function для do_nothing() версия 2
    -- =============================================
    RAISE NOTICE '9. Тест restore_function для do_nothing() версия 2';
    
    -- Проверяем, что версия 1 физически существует сейчас
    SELECT COUNT(*) INTO v_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = v_schema
      AND p.proname = v_func_name
      AND pg_get_function_arguments(p.oid) = '';
    
    ASSERT v_count = 1, 'do_nothing() версия 1 должна физически существовать перед восстановлением версии 2';
    
    PERFORM simbirstore_test.restore_function(v_func_name, 2, v_schema, '');
    
    -- Проверяем, что функция физически существует в pg_proc (должна быть одна)
    SELECT COUNT(*) INTO v_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = v_schema
      AND p.proname = v_func_name
      AND pg_get_function_arguments(p.oid) = '';
    
    ASSERT v_count = 1, 'do_nothing() версия 2 должна физически существовать в pg_proc в единственном экземпляре';
    
    -- Проверяем, что восстановленная версия стала текущей в бэкапе
    SELECT version INTO v_version
    FROM simbirstore_test.functions_backup 
    WHERE function_name = v_func_name 
      AND schema_name = v_schema
      AND function_args = ''
      AND is_current = TRUE;
    
    ASSERT v_version = 2, 'После восстановления do_nothing() актуальная версия в бэкапе должна быть 2. Сейчас: ' || v_version;
    
    -- Проверяем is_current
    SELECT is_current INTO v_is_current
    FROM simbirstore_test.functions_backup 
    WHERE function_name = v_func_name 
      AND schema_name = v_schema
      AND function_args = ''
      AND is_current = TRUE;
    
    ASSERT v_is_current = TRUE, 'Восстановленная do_nothing() версии 2 должна быть активна в бэкапе';
    
    -- Проверяем, что версия 1 теперь неактивна
    SELECT is_current INTO v_is_current
    FROM simbirstore_test.functions_backup 
    WHERE function_name = v_func_name 
      AND schema_name = v_schema
      AND function_args = ''
      AND version = 1;
    
    ASSERT v_is_current = FALSE, 'do_nothing() версия 1 должна стать неактивной после восстановления версии 2';
    
    -- Проверяем выполнение восстановленной функции
    SELECT simbirstore_test.do_nothing() INTO v_result;
    ASSERT v_result = 'Привет, я ВООБЩЕ ничего не умею делать :)', 
        'Неверный результат восстановленной функции: ' || v_result;
    
    RAISE NOTICE '✅ restore_function для do_nothing() версии 2 (физически заменена + бэкап обновлён + старая версия неактивна)';

        -- =============================================
    -- 10. Тест mark_deleted_functions (ручное удаление без safe_drop)
    -- =============================================
    RAISE NOTICE '10. Тест mark_deleted_functions (ручное удаление)';
    
    -- Сначала удаляем текущую do_nothing() через обычный DROP (без safe_drop)
    -- is_current в бэкапе останется TRUE, потому что safe_drop не вызывался
    DROP FUNCTION IF EXISTS simbirstore_test.do_nothing();
    
    -- Проверяем, что is_current всё ещё TRUE (safe_drop не использовали)
    SELECT COUNT(*) INTO v_count
    FROM simbirstore_test.functions_backup 
    WHERE function_name = v_func_name 
      AND schema_name = v_schema
      AND function_args = ''
      AND is_current = TRUE;
    
    ASSERT v_count = 1, 'После ручного DROP должен остаться is_current = TRUE. Найдено ' || v_count;
    
    -- Вызываем mark_deleted_functions
    SELECT simbirstore_test.mark_deleted_functions() INTO v_result;
    RAISE NOTICE 'mark_deleted_functions: %', v_result;
    
    -- Проверяем, что is_current стал FALSE
    SELECT COUNT(*) INTO v_count
    FROM simbirstore_test.functions_backup 
    WHERE function_name = v_func_name 
      AND schema_name = v_schema
      AND function_args = ''
      AND is_current = TRUE;
    
    ASSERT v_count = 0, 'После mark_deleted_functions is_current должен быть FALSE. Найдено ' || v_count;
    
    -- Проверяем, что записи в бэкапе сохранились
    SELECT COUNT(*) INTO v_count
    FROM simbirstore_test.functions_backup 
    WHERE function_name = v_func_name 
      AND schema_name = v_schema
      AND function_args = '';
    
    ASSERT v_count = 2, 'В бэкапе должно быть 2 версии do_nothing(). Найдено ' || v_count;
    
    RAISE NOTICE '✅ mark_deleted_functions работает корректно (ручной DROP + mark_deleted)';

    RAISE NOTICE '';
    RAISE NOTICE '✅✅✅ ВСЕ ТЕСТЫ ПРОЙДЕНЫ ✅✅✅';
END;
$TEST$;

ROLLBACK;
