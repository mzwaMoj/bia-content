-- ============================================================================
-- Introduction to SQL & Basic Querying: Day 1 class script (MySQL 8.0)
-- Every statement from the practical workbook, in the same order.
--
-- Run as root, one statement at a time (Ctrl+Enter), following the workbook.
-- Statements that are meant to fail, or that must be run while logged in as
-- another user, are commented out with a note saying so.
-- Before Part 5, change the file path in LOAD DATA to where you saved
-- sales_orders.csv, or load the data with the import wizard or
-- sales_raw_inserts.sql and skip that statement.
-- ============================================================================


-- ============================================================================
-- PART 1: CREATING A DATABASE
-- ============================================================================

CREATE DATABASE sales_db;

SHOW DATABASES;

USE sales_db;
SELECT DATABASE();

-- ---- Running it twice ----------------------------------------------------

-- Expected to fail (error demonstration). Uncomment to try it:
-- CREATE DATABASE sales_db;

CREATE DATABASE IF NOT EXISTS sales_db;


-- ============================================================================
-- PART 2: CREATING A TABLE
-- ============================================================================

-- ---- Our first table: a copy of the spreadsheet --------------------------

CREATE TABLE sales_raw (
    order_id        VARCHAR(20),
    order_date      DATE,
    ship_date       DATE,
    ship_mode       VARCHAR(20),
    customer_id     VARCHAR(10),
    customer_name   VARCHAR(100),
    segment         VARCHAR(20),
    country         VARCHAR(50),
    city            VARCHAR(50),
    state           VARCHAR(50),
    postal_code     VARCHAR(10),
    region          VARCHAR(20),
    product_id      VARCHAR(20),
    category        VARCHAR(30),
    sub_category    VARCHAR(30),
    product_name    VARCHAR(255),
    sales           DECIMAL(10,4),
    quantity        INT,
    discount        DECIMAL(4,2),
    profit          DECIMAL(10,4),
    sales_category  VARCHAR(10)
);

SHOW TABLES;

DESCRIBE sales_raw;


-- ============================================================================
-- PART 3: DATA TYPES
-- ============================================================================


-- ---- Five decisions behind the sales_raw table ---------------------------

SELECT 0.1E0 + 0.2E0 AS float_sum,
       0.1   + 0.2   AS decimal_sum;

SELECT DATEDIFF('2016-11-11', '2016-11-08') AS days_between;


-- ============================================================================
-- PART 4: DATA MODELS, ER DIAGRAMS AND DESIGNING THE SCHEMA
-- ============================================================================


-- ---- Step 5: create the tables -------------------------------------------

CREATE TABLE customers (
    customer_id    VARCHAR(10)   PRIMARY KEY,
    customer_name  VARCHAR(100)  NOT NULL,
    segment        VARCHAR(20)   NOT NULL
);

CREATE TABLE products (
    product_id    VARCHAR(20)   PRIMARY KEY,
    product_name  VARCHAR(255)  NOT NULL,
    category      VARCHAR(30)   NOT NULL,
    sub_category  VARCHAR(30)   NOT NULL
);

CREATE TABLE orders (
    order_id     VARCHAR(20)  PRIMARY KEY,
    order_date   DATE         NOT NULL,
    ship_date    DATE,
    ship_mode    VARCHAR(20),
    customer_id  VARCHAR(10)  NOT NULL,
    country      VARCHAR(50),
    city         VARCHAR(50),
    state        VARCHAR(50),
    postal_code  CHAR(5),
    region       VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
);

CREATE TABLE order_items (
    order_item_id  INT            AUTO_INCREMENT PRIMARY KEY,
    order_id       VARCHAR(20)    NOT NULL,
    product_id     VARCHAR(20)    NOT NULL,
    sales          DECIMAL(10,4)  NOT NULL,
    quantity       INT            NOT NULL,
    discount       DECIMAL(4,2)   NOT NULL DEFAULT 0,
    profit         DECIMAL(10,4),
    FOREIGN KEY (order_id)   REFERENCES orders (order_id),
    FOREIGN KEY (product_id) REFERENCES products (product_id)
);

SHOW TABLES;

DESCRIBE order_items;


-- ============================================================================
-- PART 5: INSERTING DATA
-- ============================================================================

-- ---- One row -------------------------------------------------------------

INSERT INTO customers (customer_id, customer_name, segment)
VALUES ('CG-12520', 'Claire Gute', 'Consumer');

-- ---- Several rows in one statement ---------------------------------------

INSERT INTO customers (customer_id, customer_name, segment)
VALUES
    ('DV-13045', 'Darrin Van Huff', 'Corporate'),
    ('SO-20335', 'Sean O''Donnell', 'Consumer');

SELECT * FROM customers;

-- ---- A row that refers to another table ----------------------------------

INSERT INTO orders (order_id, order_date, ship_date, ship_mode, customer_id,
                    country, city, state, postal_code, region)
VALUES ('CA-2016-152156', '2016-11-08', '2016-11-11', 'Second Class', 'CG-12520',
        'United States', 'Henderson', 'Kentucky', '42420', 'South');

-- ---- What the database refuses -------------------------------------------

-- Expected to fail (error demonstration). Uncomment to try it:
-- INSERT INTO customers (customer_id, customer_name, segment)
-- VALUES ('CG-12520', 'Claire Gute', 'Consumer');

-- Expected to fail (error demonstration). Uncomment to try it:
-- INSERT INTO orders (order_id, order_date, customer_id)
-- VALUES ('ZA-2026-000001', '2026-10-05', 'XX-99999');

-- ---- Removing the practice rows ------------------------------------------

DELETE FROM orders
WHERE order_id = 'CA-2016-152156';

DELETE FROM customers
WHERE customer_id IN ('CG-12520', 'DV-13045', 'SO-20335');


-- ---- Step 2: import the CSV into sales_raw -------------------------------

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'C:/sql_class/sales_orders.csv'
INTO TABLE sales_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- ---- Check the import ----------------------------------------------------

SELECT COUNT(*) AS rows_loaded
FROM sales_raw;

SELECT order_id, order_date, customer_name, product_id, sales
FROM sales_raw
LIMIT 5;

-- ---- Step 3: fill the four tables from sales_raw -------------------------

INSERT INTO customers (customer_id, customer_name, segment)
SELECT DISTINCT customer_id, customer_name, segment
FROM sales_raw;

-- Expected to fail (error demonstration). Uncomment to try it:
-- INSERT INTO products (product_id, product_name, category, sub_category)
-- SELECT DISTINCT product_id, product_name, category, sub_category
-- FROM sales_raw;

SELECT DISTINCT product_id, product_name
FROM sales_raw
WHERE product_id = 'FUR-CH-10001146';

INSERT INTO products (product_id, product_name, category, sub_category)
SELECT product_id, MIN(product_name), category, sub_category
FROM sales_raw
GROUP BY product_id, category, sub_category;

INSERT INTO orders (order_id, order_date, ship_date, ship_mode, customer_id,
                    country, city, state, postal_code, region)
SELECT DISTINCT order_id, order_date, ship_date, ship_mode, customer_id,
                country, city, state, LPAD(postal_code, 5, '0'), region
FROM sales_raw;

INSERT INTO order_items (order_id, product_id, sales, quantity, discount, profit)
SELECT order_id, product_id, sales, quantity, discount, profit
FROM sales_raw;

-- ---- Step 4: verify the load ---------------------------------------------

SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;

SELECT SUM(sales) AS total_sales FROM sales_raw;
SELECT SUM(sales) AS total_sales FROM order_items;

SELECT DISTINCT city, state, postal_code
FROM orders
WHERE state = 'Massachusetts'
ORDER BY city
LIMIT 5;


-- ============================================================================
-- PART 6: CREATING A USER
-- ============================================================================

CREATE USER 'sales_analyst'@'localhost' IDENTIFIED BY 'Analyst#2026';
CREATE USER 'order_clerk'@'localhost'   IDENTIFIED BY 'Clerk#2026';
CREATE USER 'sales_admin'@'localhost'   IDENTIFIED BY 'Admin#2026';

SELECT user, host
FROM mysql.user;

-- ---- A new user can log in, and nothing else -----------------------------

-- Run in a separate connection logged in as sales_analyst:
-- SHOW DATABASES;

-- Run in a separate connection logged in as sales_analyst (this one is expected to fail):
-- USE sales_db;


-- ============================================================================
-- PART 7: GRANTING PERMISSIONS
-- ============================================================================

-- ---- A read-only analyst -------------------------------------------------

GRANT SELECT ON sales_db.* TO 'sales_analyst'@'localhost';

-- ---- A clerk who captures orders -----------------------------------------

GRANT SELECT ON sales_db.* TO 'order_clerk'@'localhost';
GRANT INSERT, UPDATE ON sales_db.orders      TO 'order_clerk'@'localhost';
GRANT INSERT, UPDATE ON sales_db.order_items TO 'order_clerk'@'localhost';

-- ---- An administrator for this database ----------------------------------

GRANT ALL PRIVILEGES ON sales_db.* TO 'sales_admin'@'localhost';

-- ---- Checking what a user can do -----------------------------------------

SHOW GRANTS FOR 'order_clerk'@'localhost';

-- ---- Testing the permissions ---------------------------------------------

-- Run in a separate connection logged in as sales_analyst:
-- USE sales_db;
-- SELECT COUNT(*) AS orders FROM orders;

-- Run in a separate connection logged in as sales_analyst (this one is expected to fail):
-- DELETE FROM customers
-- WHERE customer_id = 'CG-12520';

-- ---- Taking a permission away --------------------------------------------

REVOKE UPDATE ON sales_db.orders FROM 'order_clerk'@'localhost';
SHOW GRANTS FOR 'order_clerk'@'localhost';


-- ============================================================================
-- PART 8: DATA RETRIEVAL
-- ============================================================================

-- ---- Choosing columns ----------------------------------------------------

SELECT customer_name, segment
FROM customers
LIMIT 5;

-- ---- All columns ---------------------------------------------------------

SELECT *
FROM products
LIMIT 3;

-- ---- DISTINCT: removing duplicates ---------------------------------------

SELECT DISTINCT segment
FROM customers;

SELECT DISTINCT category, sub_category
FROM products
ORDER BY category, sub_category;

-- ---- WHERE: choosing rows ------------------------------------------------

SELECT order_id, order_date, city
FROM orders
WHERE state = 'Texas'
LIMIT 5;

SELECT order_id, product_id, sales, profit
FROM order_items
WHERE sales > 8000;

SELECT order_id, order_date, ship_mode, city
FROM orders
WHERE order_date >= '2017-12-29'
  AND ship_mode = 'Standard Class';

-- ---- ORDER BY: sorting ---------------------------------------------------

SELECT order_id, product_id, sales
FROM order_items
ORDER BY sales DESC
LIMIT 5;


-- ============================================================================
-- PART 9: USING ALIASES FOR COLUMN NAMES
-- ============================================================================

SELECT customer_name AS customer,
       segment       AS customer_type
FROM customers
LIMIT 3;

-- ---- Naming a calculation ------------------------------------------------

SELECT order_id,
       sales,
       profit,
       sales - profit AS cost
FROM order_items
ORDER BY sales DESC
LIMIT 3;

SELECT order_id,
       order_date,
       ship_date,
       DATEDIFF(ship_date, order_date) AS days_to_ship
FROM orders
ORDER BY days_to_ship DESC, order_id
LIMIT 3;

-- ---- An alias cannot be used in WHERE ------------------------------------

-- Expected to fail (error demonstration). Uncomment to try it:
-- SELECT order_id,
--        DATEDIFF(ship_date, order_date) AS days_to_ship
-- FROM orders
-- WHERE days_to_ship = 7;

SELECT order_id,
       DATEDIFF(ship_date, order_date) AS days_to_ship
FROM orders
WHERE DATEDIFF(ship_date, order_date) = 7
ORDER BY order_id
LIMIT 3;

-- ---- Table aliases -------------------------------------------------------

SELECT o.order_id, o.order_date, o.city
FROM orders AS o
WHERE o.region = 'South'
ORDER BY o.order_date
LIMIT 3;


-- ============================================================================
-- PART 10: COMMENTS IN SQL
-- ============================================================================

-- A single-line comment starts with two dashes and a space
SELECT customer_name, segment      -- a comment can follow code on the same line
FROM customers
LIMIT 3;

/* A multi-line comment starts with slash-star
   and carries on over as many lines as needed
   until star-slash. */
SELECT customer_name, segment
FROM customers
LIMIT 3;

-- ---- Switching a line off while testing ----------------------------------

SELECT order_id, order_date, city, state
FROM orders
WHERE region = 'West'
-- AND state = 'California'
ORDER BY order_date
LIMIT 3;

-- ---- Documenting a saved script ------------------------------------------

/*
  Script : top_order_lines.sql
  Purpose: the five largest order lines, for the weekly sales review
*/
SELECT order_id, product_id, sales
FROM order_items
-- Full-price lines only: discounted lines are reviewed separately
WHERE discount = 0
ORDER BY sales DESC
LIMIT 5;


-- ============================================================================
-- PART 11: TEMPORARY TABLES
-- ============================================================================

-- ---- Creating one from a query -------------------------------------------

CREATE TEMPORARY TABLE tmp_west_orders AS
SELECT order_id, order_date, customer_id, city, state
FROM orders
WHERE region = 'West';

SELECT COUNT(*) AS west_orders
FROM tmp_west_orders;

SELECT DISTINCT state
FROM tmp_west_orders
ORDER BY state
LIMIT 5;

-- ---- Defining the columns first ------------------------------------------

CREATE TEMPORARY TABLE tmp_big_lines (
    order_id    VARCHAR(20),
    product_id  VARCHAR(20),
    sales       DECIMAL(10,4)
);

INSERT INTO tmp_big_lines (order_id, product_id, sales)
SELECT order_id, product_id, sales
FROM order_items
WHERE sales > 8000;

SELECT * FROM tmp_big_lines
ORDER BY sales DESC;

-- ---- How temporary tables behave -----------------------------------------

SHOW TABLES;

DROP TEMPORARY TABLE tmp_big_lines;


-- ============================================================================
-- PART 12: CTES (COMMON TABLE EXPRESSIONS)
-- ============================================================================

-- ---- A first CTE ---------------------------------------------------------

WITH west_orders AS (
    SELECT order_id, order_date, customer_id, city, state
    FROM orders
    WHERE region = 'West'
)
SELECT order_id, order_date, city
FROM west_orders
ORDER BY order_date DESC, order_id
LIMIT 3;

-- Expected to fail (error demonstration). Uncomment to try it:
-- SELECT * FROM west_orders;

-- ---- A CTE that prepares a calculation -----------------------------------

WITH order_totals AS (
    SELECT order_id,
           SUM(sales)  AS order_sales,
           SUM(profit) AS order_profit
    FROM order_items
    GROUP BY order_id
)
SELECT o.order_id,
       o.order_date,
       c.customer_name,
       t.order_sales,
       t.order_profit
FROM order_totals AS t
JOIN orders    AS o ON o.order_id    = t.order_id
JOIN customers AS c ON c.customer_id = o.customer_id
ORDER BY t.order_sales DESC
LIMIT 5;

-- ---- More than one CTE ---------------------------------------------------

WITH order_totals AS (
    SELECT order_id, SUM(sales) AS order_sales
    FROM order_items
    GROUP BY order_id
),
big_orders AS (
    SELECT order_id, order_sales
    FROM order_totals
    WHERE order_sales > 5000
)
SELECT COUNT(*) AS big_order_count
FROM big_orders;


-- ============================================================================
-- APPENDIX B: ANSWERS TO THE EXERCISES
-- ============================================================================

-- Part 1

CREATE DATABASE practice_db;
SHOW DATABASES;
DROP DATABASE practice_db;
USE sales_db;

-- Part 2

CREATE TABLE regions (
    region_name  VARCHAR(20),
    manager      VARCHAR(50)
);
DESCRIBE regions;
DROP TABLE regions;

-- Part 3: the answers are in the workbook (no code)

-- Part 4

CREATE TABLE returns (
    return_id      INT           AUTO_INCREMENT PRIMARY KEY,
    order_item_id  INT           NOT NULL,
    return_date    DATE          NOT NULL,
    reason         VARCHAR(255),
    FOREIGN KEY (order_item_id) REFERENCES order_items (order_item_id)
);

DROP TABLE returns;

-- Part 5

INSERT INTO customers (customer_id, customer_name, segment)
VALUES ('ZZ-00001', 'Your Name', 'Consumer');

SELECT * FROM customers
WHERE customer_id = 'ZZ-00001';

DELETE FROM customers
WHERE customer_id = 'ZZ-00001';

-- Part 7

CREATE USER 'report_viewer'@'localhost' IDENTIFIED BY 'Viewer#2026';
GRANT SELECT ON sales_db.products TO 'report_viewer'@'localhost';
SHOW GRANTS FOR 'report_viewer'@'localhost';
DROP USER 'report_viewer'@'localhost';

-- Part 8

-- (a)
SELECT DISTINCT region
FROM orders;

-- (b)
SELECT order_id, order_date, city
FROM orders
ORDER BY order_date DESC
LIMIT 5;

-- (c)
SELECT product_name
FROM products
WHERE sub_category = 'Copiers';

-- Part 9

SELECT order_id,
       sales,
       quantity,
       sales / quantity AS unit_price
FROM order_items
ORDER BY unit_price DESC
LIMIT 5;

-- Parts 11 and 12

-- (a)
CREATE TEMPORARY TABLE tmp_tech_products AS
SELECT product_id, product_name
FROM products
WHERE category = 'Technology';

SELECT COUNT(*) AS tech_products
FROM tmp_tech_products;

-- (b)
WITH big_lines AS (
    SELECT order_id, product_id, sales
    FROM order_items
    WHERE sales > 5000
)
SELECT *
FROM big_lines
ORDER BY sales DESC;
