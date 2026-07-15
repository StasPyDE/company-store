-- employees
CREATE TABLE
  employees (
    employee_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_role VARCHAR(50) NOT NULL,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    sur_name VARCHAR(255),
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
  );


CREATE UNIQUE INDEX ux_employees_email ON employees (email);


CREATE UNIQUE INDEX ux_employees_phone ON employees (phone);


CREATE INDEX ix_employees_role_deleted ON employees (employee_role, is_deleted);


-- categories
CREATE TABLE
  categories (
    category_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    parent_category_id BIGINT REFERENCES categories (category_id) ON DELETE RESTRICT,
    description VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
  );


CREATE UNIQUE INDEX ux_categories_slug ON categories (slug);


-- delivery_slots
CREATE TABLE
  delivery_slots (
    delivery_slot_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    delivery_date DATE NOT NULL,
    starts_at TIMESTAMP WITH TIME ZONE NOT NULL,
    max_orders INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
  );


CREATE INDEX ix_delivery_slots_date ON delivery_slots (delivery_date);


-- delivery_addresses
CREATE TABLE
  delivery_addresses (
    address_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL REFERENCES employees (employee_id) ON DELETE RESTRICT,
    address_line VARCHAR(500) NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
  );


CREATE UNIQUE INDEX ux_delivery_addresses ON delivery_addresses (employee_id, address_line);


-- warehouses
CREATE TABLE
  warehouses (
    warehouse_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    warehouse_name VARCHAR(255) NOT NULL,
    address TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
  );


CREATE INDEX ix_warehouses_status ON warehouses (status);


-- suppliers
CREATE TABLE
  suppliers (
    supplier_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_name VARCHAR(255) NOT NULL,
    inn VARCHAR(20) NOT NULL UNIQUE,
    kpp VARCHAR(20),
    ogrn VARCHAR(20),
    email VARCHAR(255),
    legal_address TEXT,
    actual_address TEXT,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
  );


-- notifications
CREATE TABLE
  notifications (
    notification_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    recipient_id BIGINT NOT NULL REFERENCES employees (employee_id) ON DELETE RESTRICT,
    sender_id BIGINT REFERENCES employees (employee_id) ON DELETE RESTRICT,
    message VARCHAR(1000) NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
  );


CREATE INDEX ix_notifications_recipient_id ON notifications (recipient_id);


CREATE INDEX ix_notifications_sender_id ON notifications (sender_id);


CREATE INDEX ix_notifications_is_read ON notifications (is_read);


-- products
CREATE TABLE
  products (
    product_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id BIGINT NOT NULL REFERENCES categories (category_id) ON DELETE RESTRICT,
    sku VARCHAR(50) NOT NULL UNIQUE,
    product_name VARCHAR(200) NOT NULL,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    min_quantity INT NOT NULL DEFAULT 1,
    description VARCHAR(1000),
    seo_title VARCHAR(255),
    seo_description VARCHAR(1000),
    manufacturer VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
  );


CREATE UNIQUE INDEX ux_products_sku ON products (sku);


CREATE INDEX ix_products_category_id ON products (category_id);


CREATE INDEX ix_products_name ON products (product_name);


CREATE INDEX ix_products_price ON products (price);


CREATE INDEX ix_products_is_active ON products (is_active)
WHERE
  is_active = TRUE;


CREATE INDEX ix_products_active_price ON products (price)
WHERE
  is_active = TRUE;


-- product_attributes
CREATE TABLE
  product_attributes (
    attribute_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES products (product_id) ON DELETE RESTRICT,
    attribute_name VARCHAR(100) NOT NULL,
    attribute_value VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
  );


CREATE INDEX ix_product_attributes_product_id ON product_attributes (product_id);


-- product_images
CREATE TABLE
  product_images (
    image_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES products (product_id) ON DELETE RESTRICT,
    url VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
  );


CREATE INDEX ix_product_images_product_id ON product_images (product_id);


-- remaining_products
CREATE TABLE
  remaining_products (
    remaining_product_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES products (product_id) ON DELETE RESTRICT,
    warehouse_id BIGINT NOT NULL REFERENCES warehouses (warehouse_id) ON DELETE RESTRICT,
    quantity INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    booked INT NOT NULL DEFAULT 0 CHECK (booked >= 0),
    status VARCHAR(50) NOT NULL DEFAULT 'AVAILABLE',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
  );


CREATE INDEX ix_remaining_products_product_id ON remaining_products (product_id);


CREATE INDEX ix_remaining_products_warehouse_id ON remaining_products (warehouse_id);


CREATE INDEX ix_remaining_products_status ON remaining_products (status);


-- cells
CREATE TABLE
  cells (
    cell_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    warehouse_id BIGINT NOT NULL REFERENCES warehouses (warehouse_id) ON DELETE RESTRICT,
    cell_number INT NOT NULL,
    cell_size VARCHAR(20) NOT NULL,
    cell_location VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
  );


CREATE UNIQUE INDEX ux_cells_warehouse_number ON cells (warehouse_id, cell_number);


-- remaining_product_cells
CREATE TABLE
  remaining_product_cells (
    remaining_product_cell_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    remaining_product_id BIGINT NOT NULL REFERENCES remaining_products (remaining_product_id) ON DELETE RESTRICT,
    cell_id BIGINT NOT NULL REFERENCES cells (cell_id) ON DELETE RESTRICT,
    item_count INT NOT NULL DEFAULT 0,
    unit_cost DECIMAL(10, 2),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
  );


CREATE INDEX ix_remaining_product_cells_rem_prod_id ON remaining_product_cells (remaining_product_id);


CREATE INDEX ix_remaining_product_cells_cell_id ON remaining_product_cells (cell_id);


-- orders
CREATE TABLE
  orders (
    order_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL REFERENCES employees (employee_id) ON DELETE RESTRICT,
    delivery_slot_id BIGINT REFERENCES delivery_slots (delivery_slot_id) ON DELETE RESTRICT,
    address_id BIGINT REFERENCES delivery_addresses (address_id) ON DELETE RESTRICT,
    payment_type VARCHAR(20) NOT NULL,
    order_comment VARCHAR(255),
    online_payment_type VARCHAR(20),
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'CREATED',
    number INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
  );


CREATE UNIQUE INDEX ux_orders_number ON orders (number, created_at);


CREATE INDEX ix_orders_employee_id ON orders (employee_id);


CREATE INDEX ix_orders_status ON orders (status);


CREATE INDEX ix_orders_created_at ON orders (created_at);


CREATE INDEX ix_orders_delivery_slot_id ON orders (delivery_slot_id);


CREATE INDEX ix_orders_employee_created_at ON orders (employee_id, created_at DESC);


-- order_items
CREATE TABLE
  order_items (
    order_item_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES products (product_id) ON DELETE RESTRICT,
    order_id BIGINT NOT NULL REFERENCES orders (order_id) ON DELETE RESTRICT,
    quantity INT NOT NULL CHECK (quantity > 0),
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
  );


CREATE INDEX ix_order_items_order_product ON order_items (order_id, product_id);


-- order_status_changes
CREATE TABLE
  order_status_changes (
    status_change_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders (order_id) ON DELETE RESTRICT,
    employee_id BIGINT REFERENCES employees (employee_id) ON DELETE RESTRICT,
    change_type VARCHAR(50) NOT NULL,
    changed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
  );


CREATE INDEX ix_order_status_changes_order_id ON order_status_changes (order_id);


CREATE INDEX ix_order_status_changes_employee_id ON order_status_changes (employee_id);


CREATE INDEX ix_order_status_changes_changed_at ON order_status_changes (changed_at);


-- payments
CREATE TABLE
  payments (
    payment_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders (order_id) ON DELETE RESTRICT,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    payment_method VARCHAR(20) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    paid_at TIMESTAMP WITH TIME ZONE NULL,
    refund_amount DECIMAL(10, 2) NOT NULL DEFAULT 0 CHECK (refund_amount >= 0),
    refund_status VARCHAR(20),
    refund_created_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
  );


CREATE INDEX ix_payments_order_id ON payments (order_id);


CREATE INDEX ix_payments_payment_status ON payments (payment_status);


CREATE INDEX ix_payments_paid_at ON payments (paid_at);


-- supplies
CREATE TABLE
  supplies (
    supply_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_id BIGINT NOT NULL REFERENCES suppliers (supplier_id) ON DELETE RESTRICT,
    supply_number VARCHAR(50),
    price DECIMAL(10, 2),
    status VARCHAR(50) NOT NULL DEFAULT 'CREATED',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
  );


CREATE INDEX ix_supplies_created_at ON supplies (created_at);


CREATE INDEX ix_supplies_status ON supplies (status);


-- employee_supplies
CREATE TABLE
  employee_supplies (
    employee_supply_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL REFERENCES employees (employee_id) ON DELETE RESTRICT,
    supply_id BIGINT NOT NULL REFERENCES supplies (supply_id) ON DELETE RESTRICT,
    assigned_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
  );


CREATE INDEX ix_employee_supplies_employee_date ON employee_supplies (employee_id, assigned_at DESC);


CREATE INDEX ix_employee_supplies_date ON employee_supplies (assigned_at DESC);


-- supply_products
CREATE TABLE
  supply_products (
    supply_product_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supply_id BIGINT NOT NULL REFERENCES supplies (supply_id) ON DELETE RESTRICT,
    remaining_product_id BIGINT NOT NULL REFERENCES remaining_products (remaining_product_id) ON DELETE RESTRICT,
    quantity INT NOT NULL DEFAULT 0,
    price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
  );


CREATE INDEX ix_supply_products_supply_id ON supply_products (supply_id);


CREATE INDEX ix_supply_products_rem_product_id ON supply_products (remaining_product_id);


-- write_off_products
CREATE TABLE
  write_off_products (
    write_off_product_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL REFERENCES employees (employee_id) ON DELETE RESTRICT,
    remaining_product_id BIGINT NOT NULL REFERENCES remaining_products (remaining_product_id) ON DELETE RESTRICT,
    quantity INT NOT NULL,
    reason TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'CREATED',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
  );


CREATE INDEX ix_write_off_products_created_at ON write_off_products (created_at);


-- employee_write_off_products
CREATE TABLE
  employee_write_off_products (
    employee_write_off_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL REFERENCES employees (employee_id) ON DELETE RESTRICT,
    write_off_product_id BIGINT NOT NULL REFERENCES write_off_products (write_off_product_id) ON DELETE RESTRICT,
    write_off_date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
  );


CREATE INDEX ix_employee_write_off_products_employee_date ON employee_write_off_products (employee_id, write_off_date DESC);


CREATE INDEX ix_employee_write_off_products_product ON employee_write_off_products (write_off_product_id);


-- promotions
CREATE TABLE
  promotions (
    promotion_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    promotion_name VARCHAR(100) NOT NULL,
    promotion_type VARCHAR(20) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    min_order_amount DECIMAL(10, 2) NOT NULL DEFAULT 0 CHECK (min_order_amount >= 0),
    start_at TIMESTAMP WITH TIME ZONE NOT NULL,
    end_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
  );


CREATE INDEX ix_promotions_start_end ON promotions (start_at, end_at);


CREATE INDEX ix_promotions_is_active ON promotions (is_active)
WHERE
  is_active = TRUE;


-- promotion_categories
CREATE TABLE
  promotion_categories (
  	promotion_category BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    promotion_id BIGINT NOT NULL REFERENCES promotions (promotion_id) ON DELETE RESTRICT,
    category_id BIGINT NOT NULL REFERENCES categories (category_id) ON DELETE RESTRICT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
  );


CREATE INDEX ix_promotion_categories_category_id ON promotion_categories (category_id);


-- promotion_products
CREATE TABLE
  promotion_products (
    promotion_product_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    promotion_id BIGINT NOT NULL REFERENCES promotions (promotion_id) ON DELETE RESTRICT,
    product_id BIGINT NOT NULL REFERENCES products (product_id) ON DELETE RESTRICT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
  );


-- coupons
CREATE TABLE
  coupons (
    coupon_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(50) NOT NULL,
    coupon_type VARCHAR(20) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount >= 0),
    min_order_amount DECIMAL(10, 2),
    start_at TIMESTAMP WITH TIME ZONE NOT NULL,
    end_at TIMESTAMP WITH TIME ZONE NOT NULL,
    usage_limit INT CHECK (
      usage_limit IS NULL
      OR usage_limit > 0
    ),
    usage_count INT NOT NULL DEFAULT 0 CHECK (usage_count >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
  );


CREATE UNIQUE INDEX ux_coupons_code ON coupons (code);


CREATE INDEX ix_coupons_active_end ON coupons (end_at)
WHERE
  is_active = TRUE;


-- bonus_transactions
CREATE TABLE
  bonus_transactions (
    bonus_transaction_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL REFERENCES employees (employee_id) ON DELETE RESTRICT,
    order_id BIGINT NOT NULL REFERENCES orders (order_id) ON DELETE RESTRICT,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('EARNED', 'SPENT')),
    description VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
  );


CREATE INDEX ix_bonus_transactions_employee_date ON bonus_transactions (employee_id, created_at DESC);


CREATE INDEX ix_bonus_transactions_order ON bonus_transactions (order_id);


-- inventories
CREATE TABLE
  inventories (
    inventory_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL REFERENCES employees (employee_id) ON DELETE RESTRICT,
    category_id BIGINT NOT NULL REFERENCES categories (category_id) ON DELETE RESTRICT,
    inventory_number INT NOT NULL CHECK (inventory_number >= 0),
    inventory_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PLANNED',
    warehouse_id BIGINT NOT NULL REFERENCES warehouses (warehouse_id) ON DELETE RESTRICT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
  );


CREATE INDEX ix_inventories_warehouse_category ON inventories (warehouse_id, category_id);


CREATE INDEX ix_inventories_employee_date ON inventories (employee_id, inventory_date DESC);


-- product_inventories
CREATE TABLE
  product_inventories (
    product_inventory_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    inventory_id BIGINT NOT NULL REFERENCES inventories (inventory_id) ON DELETE RESTRICT,
    remaining_product_id BIGINT NOT NULL REFERENCES remaining_products (remaining_product_id) ON DELETE RESTRICT,
    quantity_before INT NOT NULL,
    quantity_after INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
  );


CREATE INDEX ix_product_inventories_inventory_id ON product_inventories (inventory_id);


CREATE INDEX ix_product_inventories_rem_product_id ON product_inventories (remaining_product_id);


-- logs
CREATE TABLE
  logs (
    log_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    table_name VARCHAR(50) NOT NULL,
    record_id BIGINT NOT NULL,
    action_type VARCHAR(20) NOT NULL,
    old_value JSONB,
    new_value JSONB,
    employee_id BIGINT REFERENCES employees (employee_id) ON DELETE RESTRICT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (log_id, created_at)
  )
PARTITION BY
  RANGE (created_at);


CREATE INDEX ix_logs_table_name ON logs (table_name);


CREATE INDEX ix_logs_record_id ON logs (record_id);


CREATE INDEX ix_logs_employee_id ON logs (employee_id);


CREATE INDEX ix_logs_created_at ON logs USING BRIN (created_at);


CREATE TABLE
  logs_2026_06 PARTITION OF logs FOR
VALUES
FROM
  ('2026-06-01') TO ('2026-07-01');


CREATE TABLE
  logs_2026_07 PARTITION OF logs FOR
VALUES
FROM
  ('2026-07-01') TO ('2026-08-01');


CREATE TABLE
  logs_2026_08 PARTITION OF logs FOR
VALUES
FROM
  ('2026-08-01') TO ('2026-09-01');


CREATE TABLE
  logs_2026_09 PARTITION OF logs FOR
VALUES
FROM
  ('2026-09-01') TO ('2026-10-01');


CREATE TABLE
  logs_2026_10 PARTITION OF logs FOR
VALUES
FROM
  ('2026-10-01') TO ('2026-11-01');


CREATE TABLE
  logs_2026_11 PARTITION OF logs FOR
VALUES
FROM
  ('2026-11-01') TO ('2026-12-01');


CREATE TABLE
  logs_2026_12 PARTITION OF logs FOR
VALUES
FROM
  ('2026-12-01') TO ('2027-01-01');


CREATE TABLE
  logs_2027_01 PARTITION OF logs FOR
VALUES
FROM
  ('2027-01-01') TO ('2027-02-01');


CREATE TABLE
  logs_2027_02 PARTITION OF logs FOR
VALUES
FROM
  ('2027-02-01') TO ('2027-03-01');


CREATE TABLE
  logs_2027_03 PARTITION OF logs FOR
VALUES
FROM
  ('2027-03-01') TO ('2027-04-01');


CREATE TABLE
  logs_2027_04 PARTITION OF logs FOR
VALUES
FROM
  ('2027-04-01') TO ('2027-05-01');


CREATE TABLE
  logs_2027_05 PARTITION OF logs FOR
VALUES
FROM
  ('2027-05-01') TO ('2027-06-01');


CREATE TABLE
  logs_default PARTITION OF logs DEFAULT;
