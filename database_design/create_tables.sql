-- Таблица: bonus_settings
CREATE TABLE bonus_settings (
  bonus_setting_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, 
  earn_percent DECIMAL(5, 2) NOT NULL, 
  max_spend_percent DECIMAL(5, 2) NOT NULL, 
  no_bonus_on_promo BOOLEAN NOT NULL, 
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);


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
