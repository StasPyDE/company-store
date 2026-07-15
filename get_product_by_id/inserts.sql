-- INSERT в таблицу products не осуществлялся, так как там уже были данные

INSERT INTO product_variants (product_id, name, price_coins, stock_quantity, is_active) VALUES
-- Варианты для Смартфон X (id=1, has_variants=true)
(1, 'Смартфон X 128GB Black', 50000, 15, TRUE),
(1, 'Смартфон X 256GB Black', 60000, 10, TRUE),
(1, 'Смартфон X 128GB White', 50000, 8, TRUE),
(1, 'Смартфон X 256GB White', 60000, 5, FALSE),

-- Варианты для Ноутбук Air (id=3, has_variants=true)
(3, 'Ноутбук Air 8GB/256GB', 80000, 20, TRUE),
(3, 'Ноутбук Air 16GB/512GB', 100000, 12, TRUE),
(3, 'Ноутбук Air 16GB/1TB', 120000, 7, TRUE),
(3, 'Ноутбук Air 32GB/1TB', 150000, 3, FALSE);

INSERT INTO categories (id, name, code, icon, description) VALUES
(1, 'Смартфоны и аудио', 'phones_audio', '📱', 'Смартфоны, наушники, колонки и аудиотехника'),
(2, 'Ноутбуки и периферия', 'laptops_peripherals', '💻', 'Ноутбуки, мыши, клавиатуры и компьютерные аксессуары');
