-- Функция: get_product_by_id
-- Назначение: Получение одного товара по его ID
-- Используется для: GET /api/products/{id}

CREATE OR REPLACE FUNCTION get_product_by_id(
    p_product_id INTEGER -- Входной параметр: ID товара
)
-- Описание структуры возвращаемой таблицы
RETURNS TABLE (
    id INTEGER, -- ID товара
    name VARCHAR, -- Название товара
    category_id INTEGER, -- ID категории
    category_name VARCHAR, -- Название категории (получаем через JOIN)
    description VARCHAR, -- Описание товара
    price_coins INTEGER, -- Цена
    has_variants BOOLEAN, -- Флаг: есть ли варианты у товара
    image_url VARCHAR, -- Ссылка на изображение
    is_active BOOLEAN, -- Активен ли товар
    variants JSONB -- JSON-массив с вариантами товара
) AS $$
BEGIN

	-- Проверка корректный ли ID товара введён (т.е не NULL и больше нуля)
	IF p_product_id IS NULL OR p_product_id <= 0 THEN
        RETURN;
	END IF;

	-- Проверка существует ли вообще продукт с таким ID
	IF NOT EXISTS (SELECT 1 FROM products WHERE products.id = p_product_id AND products.is_active = TRUE) THEN
        RETURN;
	END IF;

	-- Если все проверки пройдены, формируем и возвращаем результат
    RETURN QUERY
    SELECT 
        p.id,
        p.name,
        p.category_id,
        c.name AS category_name,
        p.description,
        p.price_coins,
        p.has_variants,
        p.image_url,
        p.is_active,
        COALESCE(
            (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'id', pv.id,
                        'name', pv.name,
                        'price_coins', pv.price_coins,
                        'stock_quantity', pv.stock_quantity,
                        'is_active', pv.is_active
                    ) ORDER BY pv.id
                )
                FROM product_variants pv
                WHERE pv.product_id = p.id AND pv.is_active = TRUE
            ), 
            '[]'::jsonb
        ) AS variants
    FROM 
        products p
    LEFT JOIN 
        categories c ON p.category_id = c.id
    WHERE 
        p.id = p_product_id AND p.is_active = TRUE;
END;
$$ LANGUAGE plpgsql;
