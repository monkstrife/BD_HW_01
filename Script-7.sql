
-- customers
CREATE TABLE staging.customers (
    customer_id TEXT,
    first_name TEXT,
    last_name TEXT,
    gender TEXT,
    dob TEXT,
    job_title TEXT,
    job_industry_category TEXT,
    wealth_segment TEXT,
    deceased_indicator TEXT,
    owns_car TEXT,
    address TEXT,
    postcode TEXT,
    state TEXT,
    country TEXT,
    property_valuation TEXT
);

-- проверка на дубли
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_ids,
    COUNT(*) - COUNT(DISTINCT customer_id)
        AS duplicate_or_null_ids
FROM staging.customers;

-- проверка на пустые строки ''
SELECT COUNT(*) AS missing_ids
FROM staging.customers
WHERE customer_id IS NULL
   OR TRIM(customer_id) = '';
   
  
  
-- products
CREATE TABLE staging.products (
    product_id TEXT,
    brand TEXT,
    product_line TEXT,
    product_class TEXT,
    product_size TEXT,
    list_price TEXT,
    standard_cost TEXT
);

-- проверка на дубли
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS unique_ids,
    COUNT(*) - COUNT(DISTINCT product_id)
        AS duplicate_or_null_ids
FROM staging.products;

-- проверка на пустые строки ''
SELECT COUNT(*) AS missing_ids
FROM staging.products
WHERE product_id IS NULL
   OR TRIM(product_id) = '';
  
  
  
  
-- orders
CREATE TABLE staging.orders (
    order_id TEXT,
    customer_id TEXT,
    order_date TEXT,
    online_order TEXT,
    order_status TEXT
);


-- проверка на дубли
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_ids,
    COUNT(*) - COUNT(DISTINCT order_id)
        AS duplicate_or_null_ids
FROM staging.orders;

-- проверка на пустые строки ''
SELECT COUNT(*) AS missing_ids
FROM staging.orders
WHERE order_id IS NULL
   OR TRIM(order_id) = '';
  
  
-- order_items
CREATE TABLE staging.order_items (
    order_item_id TEXT,
    order_id TEXT,
    product_id TEXT,
    quantity TEXT,
    item_list_price_at_sale TEXT,
    item_standard_cost_at_sale TEXT
);

-- проверка на дубли
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_item_id) AS unique_ids,
    COUNT(*) - COUNT(DISTINCT order_item_id)
        AS duplicate_or_null_ids
FROM staging.order_items;

-- проверка на пустые строки ''
SELECT COUNT(*) AS missing_ids
FROM staging.order_items
WHERE order_item_id IS NULL
   OR TRIM(order_item_id) = '';
  
  
-- Переходим к основной схеме public

-- states
CREATE TABLE public.states (
    state VARCHAR(3) PRIMARY KEY,
    country TEXT NOT NULL
);

-- заполняю
INSERT INTO public.states (state, country)
SELECT DISTINCT
    TRIM(state),
    TRIM(country)
FROM staging.customers;


-- customers
CREATE TABLE public.customers (
    customer_id INTEGER PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    gender TEXT,
    dob DATE,
    job_title TEXT,
    job_industry_category TEXT,
    wealth_segment TEXT,
    deceased_indicator BOOLEAN,
    owns_car BOOLEAN,
    address TEXT,
    postcode VARCHAR(20),
    state VARCHAR(3),
    property_valuation NUMERIC(10, 2),

    CONSTRAINT fk_customers_state
        FOREIGN KEY (state)
        REFERENCES public.states(state)
);

-- заполняю
INSERT INTO public.customers (
    customer_id,
    first_name,
    last_name,
    gender,
    dob,
    job_title,
    job_industry_category,
    wealth_segment,
    deceased_indicator,
    owns_car,
    address,
    postcode,
    state,
    property_valuation
)
SELECT
    customer_id::INTEGER,
    first_name,
    last_name,
    gender,
    dob::DATE,
    job_title,
    job_industry_category,
    wealth_segment,
    deceased_indicator::BOOLEAN,
    owns_car::BOOLEAN,
    address,
    postcode,
    state,
    property_valuation::NUMERIC(10, 2)
FROM staging.customers;

-- products
CREATE TABLE public.products (
    product_id INTEGER PRIMARY KEY,
    brand TEXT,
    product_line TEXT,
    product_class TEXT,
    product_size TEXT,
    list_price NUMERIC(12, 2),
    standard_cost NUMERIC(12, 2)
);

-- заполняю
INSERT INTO public.products (
    product_id,
    brand,
    product_line,
    product_class,
    product_size,
    list_price,
    standard_cost
)
SELECT
    product_id::INTEGER,
    brand,
    product_line,
    product_class,
    product_size,
    list_price::NUMERIC(12, 2),
    standard_cost::NUMERIC(12, 2)
FROM staging.products;

-- orders
CREATE TABLE public.orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    order_date TIMESTAMP,
    online_order BOOLEAN,
    order_status TEXT,

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES public.customers(customer_id)
);

-- заполняю
INSERT INTO public.orders (
    order_id,
    customer_id,
    order_date,
    online_order,
    order_status
)
SELECT
    order_id::INTEGER,
    customer_id::INTEGER,
    order_date::TIMESTAMP,
    online_order::BOOLEAN,
    order_status
FROM staging.orders;


-- order_items
CREATE TABLE public.order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    item_list_price_at_sale NUMERIC(12, 2),
    item_standard_cost_at_sale NUMERIC(12, 2),

    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES public.orders(order_id),

    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES public.products(product_id),

    CONSTRAINT chk_quantity_positive
        CHECK (quantity > 0)
);

-- заполняю
INSERT INTO public.order_items (
    order_item_id,
    order_id,
    product_id,
    quantity,
    item_list_price_at_sale,
    item_standard_cost_at_sale
)
SELECT
    order_item_id::INTEGER,
    order_id::INTEGER,
    product_id::INTEGER,
    quantity::INTEGER,
    item_list_price_at_sale::NUMERIC(12, 2),
    item_standard_cost_at_sale::NUMERIC(12, 2)
FROM staging.order_items;

-- проверю перенос
SELECT 'customers' AS table_name, COUNT(*) AS total_rows
FROM public.customers

UNION ALL

SELECT 'products', COUNT(*)
FROM public.products

UNION ALL

SELECT 'orders', COUNT(*)
FROM public.orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM public.order_items

UNION ALL

SELECT 'states', COUNT(*)
FROM public.states;




-- ЗАПРОСЫ

-- 1
SELECT
    product_id,
    ROUND(AVG(item_list_price_at_sale), 2) AS avg_sale_price
FROM public.order_items
GROUP BY product_id
ORDER BY avg_sale_price DESC
LIMIT 5;

-- 2
SELECT
    p.brand,
    SUM(oi.item_list_price_at_sale * oi.quantity) AS total_sales
FROM public.order_items oi
JOIN public.products p
    ON oi.product_id = p.product_id
GROUP BY p.brand
ORDER BY total_sales DESC;

-- 3
SELECT
    EXTRACT(YEAR FROM order_date)::INTEGER AS year,
    EXTRACT(MONTH FROM order_date)::INTEGER AS month,
    COUNT(*) AS order_count
FROM public.orders
GROUP BY
    EXTRACT(YEAR FROM order_date),
    EXTRACT(MONTH FROM order_date)
ORDER BY year, month;

-- 4
WITH ranked_products AS (
    SELECT
        product_id,
        product_line,
        standard_cost,
        ROW_NUMBER() OVER (
            PARTITION BY product_line
            ORDER BY standard_cost DESC NULLS LAST, product_id
        ) AS rn
    FROM public.products
)
SELECT
    product_id,
    product_line,
    standard_cost
FROM ranked_products
WHERE rn = 1
ORDER BY product_line;


-- 5
SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(oi.item_list_price_at_sale * oi.quantity) AS total_amount
FROM public.orders o
JOIN public.order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.order_status
ORDER BY total_amount DESC;

-- 6
SELECT
    c.customer_id,
    c.last_name,
    c.first_name
FROM public.customers c
LEFT JOIN public.orders o
    ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;


-- 7
WITH ranked_customers AS (
    SELECT
        state,
        property_valuation,
        last_name,
        first_name,
        RANK() OVER (
            PARTITION BY state
            ORDER BY property_valuation DESC
        ) AS rank_max,
        RANK() OVER (
            PARTITION BY state
            ORDER BY property_valuation ASC
        ) AS rank_min
    FROM public.customers
    WHERE property_valuation IS NOT NULL
)
SELECT
    state,
    property_valuation,
    last_name,
    first_name
FROM ranked_customers
WHERE rank_max = 1 OR rank_min = 1
ORDER BY state, property_valuation DESC;


-- 8
SELECT
    o.customer_id,
    MAX(p.product_line) AS product_line,
    COUNT(DISTINCT o.order_id) AS order_count
FROM public.orders o
JOIN public.order_items oi
    ON o.order_id = oi.order_id
JOIN public.products p
    ON oi.product_id = p.product_id
GROUP BY o.customer_id
HAVING COUNT(DISTINCT p.product_line) = 1
   AND COUNT(*) = COUNT(p.product_line)
ORDER BY order_count DESC, o.customer_id;


-- 9
SELECT
    p.product_class,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.order_id) FILTER (
        WHERE o.order_status = 'Cancelled'
    ) AS cancelled_orders,
    ROUND(
        100.0 * COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.order_status = 'Cancelled'
        ) / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS cancellation_percentage
FROM public.products p
JOIN public.order_items oi
    ON p.product_id = oi.product_id
JOIN public.orders o
    ON oi.order_id = o.order_id
GROUP BY p.product_class
ORDER BY cancellation_percentage DESC;


-- 10
WITH customer_orders AS (
    SELECT
        c.customer_id,
        COUNT(o.order_id) AS order_count
    FROM public.customers c
    LEFT JOIN public.orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_id
),
customer_segments AS (
    SELECT
        customer_id,
        CASE
            WHEN order_count > 10 THEN 'High'
            WHEN order_count BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'Low'
        END AS segment
    FROM customer_orders
)
SELECT
    segment,
    COUNT(*) AS customer_count
FROM customer_segments
GROUP BY segment
ORDER BY
    CASE segment
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'Low' THEN 3
    END;
   
-- 11
WITH ordered_orders AS (
    SELECT
        customer_id,
        order_date,
        LAG(order_date) OVER (
            PARTITION BY customer_id
            ORDER BY order_date, order_id
        ) AS prev_order_date
    FROM public.orders
    WHERE order_date IS NOT NULL
)
SELECT
    c.first_name,
    c.last_name,
    c.job_title,
    ROUND(
        MAX(
            EXTRACT(EPOCH FROM (
                o.order_date - o.prev_order_date
            )) / 86400
        ),
        2
    ) AS max_interval_days
FROM ordered_orders o
JOIN public.customers c
    ON o.customer_id = c.customer_id
WHERE o.prev_order_date IS NOT NULL
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.job_title
ORDER BY max_interval_days DESC;



