USE restaurant_db;

-- 1. View the menu_items table and write a query to find the number of items on the menu
SELECT COUNT(*) AS total_number_of_items
FROM menu_items;

-- 2. What are the least and most expensive items on the menu?
(SELECT menu_item_id, item_name, category, price, "Most Expensive" AS item_type
FROM menu_items
ORDER BY price DESC
LIMIT 1)
UNION
(SELECT menu_item_id, item_name, category, price, "Least Expensive" AS item_type
FROM menu_items
ORDER BY price 
LIMIT 1);

-- 3. How many Italian dishes are on the menu? What are the least and most expensive Italian dishes on the menu?
SELECT COUNT(*)
FROM menu_items
WHERE category = "Italian";

(SELECT menu_item_id, item_name, category, price, "Most Expensive Italian" AS item_type
FROM menu_items
WHERE category = "Italian"
ORDER BY price DESC LIMIT 1)
UNION
(SELECT menu_item_id, item_name, category, price, "Least Expensive Italian" AS item_type
FROM menu_items
WHERE category = "Italian"
ORDER BY price LIMIT 1);

-- 4. How many dishes are in each category? What is the average dish price within each category?
SELECT category, COUNT(*) AS number_of_dishes, AVG(price) AS average_dish_price
FROM menu_items
GROUP BY category;

-- 5. View the order_details table. What is the date range of the table?
(SELECT order_id, order_date, order_time, "First Order Date" AS order_date_range
FROM order_details
ORDER BY order_date LIMIT 1)
UNION
(SELECT order_id, order_date, order_time, "Last Order Date" AS order_date_range
FROM order_details
ORDER BY order_date DESC LIMIT 1);

-- 6. How many orders were made within this date range? How many items were ordered within this date range?
SELECT COUNT(DISTINCT order_id)
FROM order_details;

SELECT COUNT(*)
FROM order_details;

-- 7. Which orders had the most number of items?
SELECT order_id, COUNT(item_id) AS number_of_items
FROM order_details
GROUP BY order_id
ORDER BY number_of_items DESC;

-- 8. How many orders had more than 12 items?
SELECT COUNT(*) AS number_of_orders_with_more_than_12_items
FROM
(SELECT order_id, COUNT(item_id) AS number_of_items
FROM order_details
GROUP BY order_id
HAVING number_of_items > 12) AS number_of_orders_with_more_than_12_items;

-- 9. Combine the menu_items and order_details tables into a single table
SELECT *
FROM order_details
LEFT JOIN menu_items
ON order_details.item_id = menu_items.menu_item_id;

-- 10. What were the least and most ordered items? What categories were they in?
WITH order_details_menu_items(order_details_id, order_id, order_date, order_time, item_id, menu_item_id, item_name, category, price)
AS 
(SELECT *
FROM order_details
LEFT JOIN menu_items
ON order_details.item_id = menu_items.menu_item_id)

(SELECT item_name, COUNT(order_details_id) AS number_of_orders, category, "Least Ordered" AS order_frequency
FROM order_details_menu_items
GROUP BY item_name, category
ORDER BY number_of_orders LIMIT 1)
UNION
(SELECT item_name, COUNT(order_details_id) AS number_of_orders, category, "Most Ordered" AS order_frequency
FROM order_details_menu_items
GROUP BY item_name, category
ORDER BY number_of_orders DESC LIMIT 1);

-- 11. What were the top 5 orders that spent the most money?
WITH order_details_menu_items(order_details_id, order_id, order_date, order_time, item_id, menu_item_id, item_name, category, price)
AS 
(SELECT *
FROM order_details
LEFT JOIN menu_items
ON order_details.item_id = menu_items.menu_item_id)

SELECT order_id, SUM(price) AS total_price
FROM order_details_menu_items
GROUP BY order_id
ORDER BY total_price DESC LIMIT 5;

-- 12. View the details of the highest spend order. Which specific items were purchased?
WITH order_details_menu_items(order_details_id, order_id, order_date, order_time, item_id, menu_item_id, item_name, category, price)
AS 
(SELECT *
FROM order_details
LEFT JOIN menu_items
ON order_details.item_id = menu_items.menu_item_id)

SELECT order_id, GROUP_CONCAT(DISTINCT item_name SEPARATOR ",") AS item_names, SUM(price) AS total_price
FROM order_details_menu_items
GROUP BY order_id
ORDER BY total_price DESC LIMIT 1;

-- 13. View the details of the top 5 highest spend orders
WITH order_details_menu_items(order_details_id, order_id, order_date, order_time, item_id, menu_item_id, item_name, category, price)
AS 
(SELECT *
FROM order_details
LEFT JOIN menu_items
ON order_details.item_id = menu_items.menu_item_id)

SELECT o1.order_id, o1.category, COUNT(o1.item_id) AS number_of_items
FROM order_details_menu_items AS o1
INNER JOIN (
SELECT order_id
FROM order_details_menu_items
GROUP BY order_id
ORDER BY SUM(price) DESC LIMIT 5) AS o2
ON o1.order_id = o2.order_id
GROUP BY o1.order_id, o1.category;

-- 14. Find the number of orders in each month
SELECT EXTRACT(MONTH FROM order_date) AS month_value, COUNT(*) AS number_of_orders
FROM order_details
GROUP BY month_value;

-- 15. Analyze the weekday and weekend orders per month
WITH weekday_or_weekend(order_date, month_number, day_of_week, weekday_or_weekend) AS
(SELECT order_date,
EXTRACT(MONTH FROM order_date) AS month_number,
CASE WHEN DAYOFWEEK(order_date) = 1 THEN "Sunday"
WHEN DAYOFWEEK(order_date) = 2 THEN "Monday"
WHEN DAYOFWEEK(order_date) = 3 THEN "Tuesday"
WHEN DAYOFWEEK(order_date) = 4 THEN "Wednesday"
WHEN DAYOFWEEK(order_date) = 5 THEN "Thursday"
WHEN DAYOFWEEK(order_date) = 6 THEN "Friday"
ELSE "Saturday"
END AS day_of_week,
CASE WHEN DAYOFWEEK(order_date) IN (1, 7) THEN "Weekend"
ELSE "Weekday"
END AS weekday_or_weekend
FROM order_details)

SELECT month_number, weekday_or_weekend, COUNT(*) AS number_of_orders,
ROUND((0.0 + COUNT(*)) * 100 / (SUM(COUNT(*)) OVER (PARTITION BY month_number)), 2) AS percentage_of_orders
FROM weekday_or_weekend
GROUP BY month_number, weekday_or_weekend
ORDER BY month_number, weekday_or_weekend;