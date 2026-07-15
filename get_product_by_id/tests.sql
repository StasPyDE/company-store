-- Тесты

-- Получение продукта, который активен и у которого есть варианты
SELECT * FROM get_product_by_id(1);

-- Получение продукта, который активен и у которого нет вариантов
SELECT * FROM get_product_by_id(2);

-- Получение продукта, который неактивен
SELECT * FROM get_product_by_id(4);

-- Получение продукта с некорректным ID
SELECT * FROM get_product_by_id(-1);
SELECT * FROM get_product_by_id('not number');

-- Получение продукта с несуществующим ID
SELECT * FROM get_product_by_id(99);
