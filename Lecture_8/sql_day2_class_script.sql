-- ============================================================================
-- Advanced SQL Concepts & Data Manipulation: Day 2 class script (MySQL 8.0)
-- Every statement from the Day 2 workbook, in the same order.
--
-- Start with the quick checks. If any of them fails, run sql_day2_setup.sql
-- first, then come back here.
-- Run one statement at a time (Ctrl+Enter), following the workbook. A stored
-- procedure block (DELIMITER // ... DELIMITER ;) must be selected as a whole
-- and run with Ctrl+Shift+Enter.
-- Statements that are meant to fail are commented out with a note.
-- ============================================================================

-- ---- Before you start: quick checks --------------------------------------

-- Check 1: the tables exist.

USE sales_db;
SHOW TABLES;

-- Check 2: every table has its rows.

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items;

-- Check 3: the values are right.

SELECT SUM(sales)  AS total_sales,
       SUM(profit) AS total_profit
FROM order_items;


-- ============================================================================
-- PART 1: SORTING DATA WITH ORDER BY
-- ============================================================================

-- ---- Sorting by more than one column -------------------------------------

SELECT order_id, quantity, sales
FROM order_items
ORDER BY quantity DESC, sales DESC
LIMIT 5;

-- ---- Sorting by a calculation --------------------------------------------

SELECT order_id, product_id, profit
FROM order_items
ORDER BY ABS(profit) DESC
LIMIT 5;

-- ---- Sorting in a custom order with CASE ---------------------------------

SELECT DISTINCT ship_mode
FROM orders
ORDER BY CASE ship_mode
             WHEN 'Same Day'     THEN 1
             WHEN 'First Class'  THEN 2
             WHEN 'Second Class' THEN 3
             ELSE 4
         END;


-- ============================================================================
-- PART 2: FILTERING ROWS
-- ============================================================================

-- ---- AND: every condition must hold --------------------------------------

SELECT order_id, order_date, city
FROM orders
WHERE region = 'West'
  AND ship_mode = 'Same Day';

-- ---- OR, and the trap when it is mixed with AND --------------------------

SELECT COUNT(*) AS orders
FROM orders
WHERE state = 'Texas' OR state = 'Florida' AND ship_mode = 'Same Day';

SELECT COUNT(*) AS orders
FROM orders
WHERE (state = 'Texas' OR state = 'Florida')
  AND ship_mode = 'Same Day';

-- ---- IN: a tidier OR -----------------------------------------------------

SELECT COUNT(*) AS orders
FROM orders
WHERE state IN ('Texas', 'Florida')
  AND ship_mode = 'Same Day';

-- ---- NOT: everything except ----------------------------------------------

SELECT DISTINCT ship_mode
FROM orders
WHERE ship_mode NOT IN ('Standard Class', 'Second Class');

-- ---- BETWEEN: a range ----------------------------------------------------

SELECT COUNT(*) AS december_orders
FROM orders
WHERE order_date BETWEEN '2017-12-01' AND '2017-12-31';


-- ============================================================================
-- PART 3: LIMITING RESULTS WITH LIMIT
-- ============================================================================

SELECT order_id, product_id, sales
FROM order_items
ORDER BY sales DESC
LIMIT 3;

SELECT order_id, product_id, sales
FROM order_items
ORDER BY sales DESC
LIMIT 3 OFFSET 3;


-- ============================================================================
-- PART 4: AGGREGATE FUNCTIONS AND GROUP BY
-- ============================================================================

SELECT COUNT(*)                   AS order_lines,
       COUNT(DISTINCT product_id) AS products_sold,
       SUM(sales)                 AS total_sales,
       AVG(sales)                 AS average_sale,
       MAX(sales)                 AS largest_sale
FROM order_items;

-- ---- GROUP BY: one row per group -----------------------------------------

SELECT region, COUNT(*) AS orders
FROM orders
GROUP BY region
ORDER BY orders DESC;

SELECT ship_mode,
       COUNT(*)                             AS orders,
       AVG(DATEDIFF(ship_date, order_date)) AS avg_days_to_ship
FROM orders
GROUP BY ship_mode
ORDER BY avg_days_to_ship;

-- ---- Grouping by two columns ---------------------------------------------

SELECT region, ship_mode, COUNT(*) AS orders
FROM orders
GROUP BY region, ship_mode
ORDER BY region, orders DESC;

-- ---- The rule that catches everyone --------------------------------------

-- Expected to fail (error demonstration). Uncomment to try it:
-- SELECT region, state, COUNT(*) AS orders
-- FROM orders
-- GROUP BY region;

-- ---- HAVING: filtering groups --------------------------------------------

SELECT customer_id, COUNT(*) AS orders
FROM orders
GROUP BY customer_id
HAVING COUNT(*) >= 8
ORDER BY orders DESC;

SELECT customer_id, COUNT(*) AS orders_in_2017
FROM orders
WHERE order_date >= '2017-01-01'
GROUP BY customer_id
HAVING COUNT(*) >= 5;


-- ============================================================================
-- PART 5: MATHEMATICAL OPERATIONS
-- ============================================================================

SELECT order_id,
       sales,
       quantity,
       profit,
       ROUND(sales / quantity, 2)     AS unit_price,
       ROUND(profit / sales * 100, 1) AS margin_pct
FROM order_items
ORDER BY sales DESC
LIMIT 4;

-- ---- Calculating with aggregates -----------------------------------------

SELECT ROUND(SUM(profit) / SUM(sales) * 100, 1) AS overall_margin_pct
FROM order_items;

-- ---- CASE: a calculation with rules --------------------------------------

SELECT order_id,
       sales,
       CASE
           WHEN sales > 1000 THEN 'High'
           WHEN sales > 100  THEN 'Medium'
           ELSE 'Low'
       END AS sales_band
FROM order_items
LIMIT 4;

SELECT CASE
           WHEN sales > 1000 THEN 'High'
           WHEN sales > 100  THEN 'Medium'
           ELSE 'Low'
       END      AS sales_band,
       COUNT(*) AS order_lines
FROM order_items
GROUP BY sales_band
ORDER BY order_lines DESC;


-- ============================================================================
-- PART 6: ORDER OF OPERATIONS
-- ============================================================================

SELECT region, COUNT(*) AS same_day_orders     -- 5
FROM orders                                    -- 1
WHERE ship_mode = 'Same Day'                   -- 2
GROUP BY region                                -- 3
HAVING COUNT(*) >= 20                          -- 4
ORDER BY same_day_orders DESC                  -- 6
LIMIT 2;                                       -- 7

-- Expected to fail (error demonstration). Uncomment to try it:
-- SELECT customer_id, COUNT(*) AS orders
-- FROM orders
-- WHERE COUNT(*) >= 8
-- GROUP BY customer_id;


-- ============================================================================
-- PART 7: SUBQUERIES
-- ============================================================================

-- ---- A subquery that returns one value -----------------------------------

SELECT order_id, product_id, sales
FROM order_items
WHERE sales > (SELECT AVG(sales) FROM order_items)
ORDER BY sales;

-- ---- A subquery that returns a list --------------------------------------

SELECT customer_id, customer_name
FROM customers
WHERE customer_id IN (SELECT customer_id
                      FROM orders
                      WHERE order_date >= '2017-12-01')
ORDER BY customer_name;

-- ---- A subquery used as a table ------------------------------------------

SELECT ROUND(AVG(order_total), 2) AS average_order_value
FROM (SELECT order_id, SUM(sales) AS order_total
      FROM order_items
      GROUP BY order_id) AS order_totals;

-- ---- A correlated subquery -----------------------------------------------

SELECT oi.order_id, oi.product_id, oi.sales
FROM order_items AS oi
WHERE oi.sales > (SELECT AVG(sales)
                  FROM order_items
                  WHERE product_id = oi.product_id)
ORDER BY oi.sales DESC
LIMIT 3;


-- ============================================================================
-- PART 8: JOINS
-- ============================================================================

-- ---- INNER JOIN: rows that match in both tables --------------------------

SELECT o.order_id, o.order_date, c.customer_name
FROM orders AS o
INNER JOIN customers AS c ON c.customer_id = o.customer_id
ORDER BY o.order_date DESC, o.order_id
LIMIT 3;

-- ---- Joining more than two tables ----------------------------------------

SELECT o.order_id, c.customer_name, p.product_name, oi.quantity, oi.sales
FROM orders AS o
JOIN customers   AS c  ON c.customer_id = o.customer_id
JOIN order_items AS oi ON oi.order_id   = o.order_id
JOIN products    AS p  ON p.product_id  = oi.product_id
WHERE o.order_id = 'CA-2016-152156';

-- ---- Joining and grouping ------------------------------------------------

SELECT p.category,
       COUNT(*)                                       AS order_lines,
       SUM(oi.sales)                                  AS total_sales,
       ROUND(SUM(oi.profit) / SUM(oi.sales) * 100, 1) AS margin_pct
FROM order_items AS oi
JOIN products AS p ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY total_sales DESC;

-- ---- LEFT JOIN: keep every row of the first table ------------------------

INSERT INTO customers (customer_id, customer_name, segment)
VALUES ('ZZ-00001', 'Thandi Nkosi', 'Consumer');

SELECT c.customer_id, c.customer_name, o.order_id
FROM customers AS c
LEFT JOIN orders AS o ON o.customer_id = c.customer_id
WHERE c.customer_id IN ('AB-10600', 'ZZ-00001');

SELECT c.customer_id, c.customer_name
FROM customers AS c
LEFT JOIN orders AS o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

-- ---- RIGHT JOIN ----------------------------------------------------------

SELECT c.customer_id, c.customer_name
FROM orders AS o
RIGHT JOIN customers AS c ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;


-- ============================================================================
-- PART 9: UPDATING AND DELETING DATA
-- ============================================================================

-- ---- UPDATE --------------------------------------------------------------

SELECT * FROM customers
WHERE customer_id = 'ZZ-00001';

UPDATE customers
SET customer_name = 'Thandi Nkosi-Smith',
    segment       = 'Corporate'
WHERE customer_id = 'ZZ-00001';

SELECT * FROM customers
WHERE customer_id = 'ZZ-00001';

-- ---- DELETE --------------------------------------------------------------

DELETE FROM customers
WHERE customer_id = 'ZZ-00001';

-- Expected to fail (error demonstration). Uncomment to try it:
-- DELETE FROM customers
-- WHERE customer_id = 'CG-12520';


-- ============================================================================
-- PART 10: STORED PROCEDURES
-- ============================================================================

-- ---- A procedure with one parameter --------------------------------------

DROP PROCEDURE IF EXISTS get_customer_orders;

DELIMITER //
CREATE PROCEDURE get_customer_orders (IN p_customer_id VARCHAR(10))
BEGIN
    SELECT order_id, order_date, ship_mode, city, state
    FROM orders
    WHERE customer_id = p_customer_id
    ORDER BY order_date;
END //
DELIMITER ;

CALL get_customer_orders('SO-20335');

-- ---- A procedure that summarises -----------------------------------------

DROP PROCEDURE IF EXISTS category_sales_for_year;

DELIMITER //
CREATE PROCEDURE category_sales_for_year (IN p_year INT)
BEGIN
    SELECT p.category,
           COUNT(DISTINCT o.order_id) AS orders,
           SUM(oi.sales)              AS total_sales
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id  = o.order_id
    JOIN products    AS p  ON p.product_id = oi.product_id
    WHERE YEAR(o.order_date) = p_year
    GROUP BY p.category
    ORDER BY total_sales DESC;
END //
DELIMITER ;

CALL category_sales_for_year(2017);

SHOW PROCEDURE STATUS WHERE Db = 'sales_db';


-- ============================================================================
-- PART 11: ETL WITH SQL
-- ============================================================================

-- ---- Step 1: write the transformation as a SELECT ------------------------

SELECT c.customer_id,
       c.customer_name,
       c.segment,
       COUNT(DISTINCT o.order_id) AS orders,
       SUM(oi.sales)              AS total_sales,
       SUM(oi.profit)             AS total_profit,
       MAX(o.order_date)          AS last_order
FROM customers AS c
JOIN orders      AS o  ON o.customer_id = c.customer_id
JOIN order_items AS oi ON oi.order_id   = o.order_id
GROUP BY c.customer_id, c.customer_name, c.segment
ORDER BY total_sales DESC
LIMIT 3;

-- ---- Step 2: create the target table and load it -------------------------

DROP TABLE IF EXISTS customer_summary;

CREATE TABLE customer_summary (
    customer_id      VARCHAR(10)    PRIMARY KEY,
    customer_name    VARCHAR(100)   NOT NULL,
    segment          VARCHAR(20)    NOT NULL,
    orders           INT            NOT NULL,
    total_sales      DECIMAL(12,4)  NOT NULL,
    total_profit     DECIMAL(12,4)  NOT NULL,
    last_order       DATE           NOT NULL
);

INSERT INTO customer_summary
    (customer_id, customer_name, segment, orders,
     total_sales, total_profit, last_order)
SELECT c.customer_id,
       c.customer_name,
       c.segment,
       COUNT(DISTINCT o.order_id),
       SUM(oi.sales),
       SUM(oi.profit),
       MAX(o.order_date)
FROM customers AS c
JOIN orders      AS o  ON o.customer_id = c.customer_id
JOIN order_items AS oi ON oi.order_id   = o.order_id
GROUP BY c.customer_id, c.customer_name, c.segment;

-- ---- Step 3: check the load ----------------------------------------------

SELECT COUNT(*)         AS customers,
       SUM(orders)      AS orders,
       SUM(total_sales) AS total_sales
FROM customer_summary;

SELECT segment,
       COUNT(*)                   AS customers,
       ROUND(AVG(total_sales), 2) AS avg_sales_per_customer
FROM customer_summary
GROUP BY segment
ORDER BY avg_sales_per_customer DESC;


-- ============================================================================
-- PART 12: ANALYSING DATA WITH SIMPLE STATISTICS
-- ============================================================================

SELECT COUNT(*)                     AS n,
       ROUND(AVG(sales), 2)         AS mean,
       MIN(sales)                   AS minimum,
       MAX(sales)                   AS maximum,
       MAX(sales) - MIN(sales)      AS value_range,
       ROUND(STDDEV_SAMP(sales), 2) AS std_dev
FROM order_items;

-- ---- Statistics per group ------------------------------------------------

SELECT p.category,
       COUNT(*)                        AS n,
       ROUND(AVG(oi.sales), 2)         AS mean,
       MIN(oi.sales)                   AS minimum,
       MAX(oi.sales)                   AS maximum,
       ROUND(STDDEV_SAMP(oi.sales), 2) AS std_dev
FROM order_items AS oi
JOIN products AS p ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY mean DESC;


-- ============================================================================
-- APPENDIX: ANSWERS TO THE EXERCISES
-- ============================================================================

-- Part 3

-- (a)
SELECT order_id, ship_date, city
FROM orders
WHERE region = 'East'
ORDER BY ship_date DESC
LIMIT 5;

-- (b)
SELECT COUNT(*) AS orders
FROM orders
WHERE region = 'East'
  AND ship_mode IN ('First Class', 'Same Day');

-- Part 4

-- (a)
SELECT state, COUNT(*) AS orders
FROM orders
GROUP BY state
ORDER BY orders DESC
LIMIT 5;

-- (b)
SELECT state, COUNT(*) AS orders
FROM orders
GROUP BY state
HAVING COUNT(*) > 150
ORDER BY orders DESC;

-- Part 5

SELECT CASE
           WHEN profit < 0 THEN 'Loss'
           ELSE 'Profit'
       END      AS result,
       COUNT(*) AS order_lines
FROM order_items
GROUP BY result;

-- Part 8

-- (a)
SELECT c.customer_name, SUM(oi.sales) AS total_sales
FROM customers AS c
JOIN orders      AS o  ON o.customer_id = c.customer_id
JOIN order_items AS oi ON oi.order_id   = o.order_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_sales DESC
LIMIT 5;

-- (b)
SELECT p.sub_category, SUM(oi.sales) AS total_sales
FROM order_items AS oi
JOIN products AS p ON p.product_id = oi.product_id
WHERE p.category = 'Technology'
GROUP BY p.sub_category
ORDER BY total_sales DESC;

-- Part 10

DROP PROCEDURE IF EXISTS orders_in_state;

DELIMITER //
CREATE PROCEDURE orders_in_state (IN p_state VARCHAR(50))
BEGIN
    SELECT order_id, order_date, city
    FROM orders
    WHERE state = p_state
    ORDER BY order_date;
END //
DELIMITER ;

CALL orders_in_state('Vermont');

-- Part 12

SELECT o.region,
       COUNT(*)                        AS n,
       ROUND(AVG(oi.sales), 2)         AS mean,
       ROUND(STDDEV_SAMP(oi.sales), 2) AS std_dev
FROM orders AS o
JOIN order_items AS oi ON oi.order_id = o.order_id
GROUP BY o.region
ORDER BY mean DESC;
