USE `magist`;
SELECT * FROM products;
SELECT * FROM product_category_name_translation;
SELECT * FROM geo;
SELECT * FROM order_reviews;
SELECT * FROM order_payments;
SELECT * FROM order_items;
SELECT * FROM orders;
SELECT * FROM sellers;
SELECT * FROM customers;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------


# 2.1. In relation to the products:
#####
# 2.1.1 What categories of tech products does Magist have?

SELECT
DISTINCT(product_category_name_english)
FROM
product_category_name_translation
	ORDER BY product_category_name_english;
    
SELECT
COUNT(p.product_id) AS product_count,
pc.product_category_name_english
FROM products AS p
	JOIN product_category_name_translation AS pc
		ON
        p.product_category_name = pc.product_category_name
				WHERE pc.product_category_name_english 
				REGEXP
					'computer|electronic|telephon|phone|tablet|audio|camera|console|game|apple|watch|smart'
						GROUP BY pc.product_category_name_english;

# REGEXP is used to search text for a pattern. Without REGEXP, you would need:
#WHERE category LIKE '%computer%'
#OR category LIKE '%electronic%'
#OR category LIKE '%telephon%'
#OR category LIKE '%phone%'
#OR category LIKE '%tablet%'
#OR category LIKE '%audio%'
#OR category LIKE '%camera%'
#OR category LIKE '%console%'
#OR category LIKE '%game%'
#OR category LIKE '%accessor%'
#OR category LIKE '%apple%'
#That's quite long.
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# 2.1.2 (a) How many products of these tech categories have been sold (within the time window of the database snapshot)?

SELECT
COUNT(o.order_item_id) AS product_sold,
pc.product_category_name_english
FROM products AS p
	JOIN product_category_name_translation AS pc
		ON
        p.product_category_name = pc.product_category_name
			JOIN order_items AS o
				ON
                p.product_id = o.product_id
					WHERE pc.product_category_name_english 
						REGEXP
						'computer|electronic|telephon|phone|tablet|audio|camera|console|game|computers_accessories|apple|cine|watch|smart'
							GROUP BY pc.product_category_name_english
								ORDER by product_sold DESC;

# 2.1.2 (b) What percentage does that represent from the overall number of products sold?

SELECT
COUNT(o.order_item_id) AS total_product_sold,
ROUND(
		COUNT(o.order_item_id) * 100 /
			(SELECT COUNT(*)
				FROM order_items)
		, 2
	) AS percentage_tech_product_sold,
    pc.product_category_name_english
FROM products AS p
	JOIN product_category_name_translation AS pc
		ON
        p.product_category_name = pc.product_category_name
			JOIN order_items AS o
				ON
                p.product_id = o.product_id
					WHERE pc.product_category_name_english 
						REGEXP
						'computer|electronic|telephon|phone|tablet|audio|camera|console|game|computers_accessories|apple|cine|watch|smart'
							GROUP BY pc.product_category_name_english
								ORDER by total_product_sold DESC;
                                
#[COMBINED ANSWER FOR ALL THE PRODUCTS]

SELECT
    COUNT(*) AS tech_products_sold,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*)
         FROM order_items),
        2
    ) AS percentage_of_all_products_sold
FROM products AS p
JOIN product_category_name_translation AS pc
    ON p.product_category_name = pc.product_category_name
JOIN order_items AS o
    ON p.product_id = o.product_id
WHERE pc.product_category_name_english REGEXP
    'computer|electronic|telephon|phone|tablet|audio|camera|console|game|computers_accessories|apple|watch';
                                
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# 2.1.3 What’s the average price of the products being sold?
        
#[average price for every product]
  SELECT
		product_id,
        ROUND(AVG(price),2) AS Average_price
	FROM order_items
		GROUP BY product_id
		ORDER BY Average_price DESC;  
        

#[average price of each Tech product]

 SELECT
    pc.product_category_name_english,
    o.product_id,
    ROUND(AVG(o.price), 2) AS average_price
FROM order_items AS o
JOIN products AS p
    ON o.product_id = p.product_id
JOIN product_category_name_translation AS pc
    ON p.product_category_name = pc.product_category_name
WHERE pc.product_category_name_english REGEXP
    'computer|electronic|telephon|phone|tablet|audio|camera|console|game|computers_accessories|apple|watch'
GROUP BY pc.product_category_name_english, o.product_id
ORDER BY average_price DESC;     


#[average price of Tech products together]              
SELECT
    ROUND(AVG(o.price), 2) AS average_tech_product_price
FROM order_items AS o
JOIN products AS p
    ON o.product_id = p.product_id
JOIN product_category_name_translation AS pc
    ON p.product_category_name = pc.product_category_name
WHERE pc.product_category_name_english REGEXP
    'computer|electronic|telephon|phone|tablet|audio|camera|console|game|computers_accessories|apple|watch';	

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# 2.1.4 Are expensive tech products popular?  

# To calculate the threshold of price that belongs to expensive we need to calculate Q3-quartile first.

WITH product_prices AS (
    SELECT
        o.product_id,
        ROUND(AVG(o.price), 2) AS average_price
    FROM order_items AS o
    JOIN products AS p
        ON o.product_id = p.product_id
    JOIN product_category_name_translation AS pc
        ON p.product_category_name = pc.product_category_name
    WHERE pc.product_category_name_english REGEXP
        'computer|electronic|telephon|phone|tablet|audio|camera|console|game|computers_accessories|apple|watch'
    GROUP BY o.product_id
),

ordered_prices AS (
    SELECT
        average_price,
        ROW_NUMBER() OVER (ORDER BY average_price) AS rn,
        COUNT(*) OVER () AS n
    FROM product_prices
),

Q3 AS (
	SELECT
    MAX(n) AS number_of_tech_products,
    MIN(average_price) AS q3_threshold
FROM ordered_prices
WHERE rn >= CEIL(0.75 * n)
),

# Now we calculate the answer

classified_products AS (

    # Classify each Tech product using its average price
    SELECT
        pp.product_id,
        pp.average_price,
        CASE
            WHEN pp.average_price >= q3.q3_threshold
                THEN 'Expensive'
            ELSE 'Low_cost'
        END AS PriceCategory
    FROM product_prices AS pp
    CROSS JOIN q3
)

# Measure popularity through number of products sold
SELECT
    cp.PriceCategory,
    COUNT(o.order_item_id) AS product_sold
FROM classified_products AS cp
JOIN order_items AS o
    ON cp.product_id = o.product_id
GROUP BY cp.PriceCategory
ORDER BY product_sold DESC;

---------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------
# 2.2. In relation to the sellers
#######
# 2.2.1 How many months of data are included in the magist database?

SELECT DISTINCT
    COUNT(DISTINCT DATE_FORMAT(order_purchase_timestamp, '%Y-%m')) AS total_month
FROM orders;

---------------------------------------------------------------------------------------------------------------------------
# 2.2.2 (a) How many sellers are there?

SELECT COUNT(DISTINCT(seller_id)) FROM sellers;

# 2.2.2 (b) How many Tech sellers are there?

SELECT
COUNT(DISTINCT(s.seller_id)) AS number_tech_sellers
FROM products AS p
	JOIN product_category_name_translation AS pc
		ON
        p.product_category_name = pc.product_category_name
			JOIN order_items AS o
				ON
                p.product_id = o.product_id
                JOIN sellers AS s
					ON
                    o.seller_id = s.seller_id
					WHERE pc.product_category_name_english 
						REGEXP
						'computer|electronic|telephon|phone|tablet|audio|camera|console|game|computers_accessories|apple|watch';
							
                           
#2.2.2 (c) What percentage of overall sellers are Tech sellers?

SELECT
COUNT(DISTINCT CASE
	 WHEN pc.product_category_name_english 
		REGEXP
		'computer|electronic|telephon|phone|tablet|audio|camera|console|game|computers_accessories|apple|watch'
	THEN s.seller_id
    END) * 100.0
    / COUNT(DISTINCT s.seller_id) AS percentage_tech_sellers
FROM sellers AS s
LEFT JOIN order_items AS o
    ON s.seller_id = o.seller_id
LEFT JOIN products AS p
    ON o.product_id = p.product_id
LEFT JOIN product_category_name_translation AS pc
    ON p.product_category_name = pc.product_category_name;
    
   
   
   # combined answer
   
   SELECT
    COUNT(DISTINCT s.seller_id) AS total_sellers,

    COUNT(DISTINCT CASE
        WHEN pc.product_category_name_english REGEXP
            'computer|electronic|telephon|phone|tablet|audio|camera|console|game|computers_accessories|apple|watch'
        THEN s.seller_id
    END) AS tech_sellers,

    ROUND(
        COUNT(DISTINCT CASE
            WHEN pc.product_category_name_english REGEXP
                'computer|electronic|telephon|phone|tablet|audio|camera|console|game|computers_accessories|apple|watch'
            THEN s.seller_id
        END) * 100.0
        / COUNT(DISTINCT s.seller_id),
        2
    ) AS percentage_tech_sellers

FROM sellers AS s
LEFT JOIN order_items AS o
    ON s.seller_id = o.seller_id
LEFT JOIN products AS p
    ON o.product_id = p.product_id
LEFT JOIN product_category_name_translation AS pc
    ON p.product_category_name = pc.product_category_name;
   
 ---------------------------------------------------------------------------------------------------------------------------------
# 2.2.3 (a) What is the total amount earned by all sellers?
SELECT
    SUM(price) AS total_amount_earned
FROM order_items;

# EXTRA - How much did each seller earn?
SELECT
	seller_id,
    SUM(price) AS amount_earned
FROM order_items
	GROUP BY seller_id;
    
# 2.2.3(b) What is the total amount earned by all Tech sellers?
SELECT
SUM(o.price) AS total_tech_Seller_earnings
FROM products AS p
	JOIN product_category_name_translation AS pc
		ON
        p.product_category_name = pc.product_category_name
			JOIN order_items AS o
				ON
                p.product_id = o.product_id
                JOIN sellers AS s
					ON
                    o.seller_id = s.seller_id
					WHERE pc.product_category_name_english 
						REGEXP
						'computer|electronic|telephon|phone|tablet|audio|camera|console|game|computers_accessories|apple|watch';
  
  
  # Combined answer
  # 2.2.3 (a) and (b)

SELECT
    SUM(o.price) AS total_amount_all_sellers,

    SUM(
        CASE
            WHEN pc.product_category_name_english REGEXP
                'computer|electronic|telephon|phone|tablet|audio|camera|console|game|computers_accessories|apple|watch'
            THEN o.price
            ELSE 0
        END
    ) AS total_amount_tech_sellers

FROM order_items AS o
JOIN products AS p
    ON o.product_id = p.product_id
JOIN product_category_name_translation AS pc
    ON p.product_category_name = pc.product_category_name;
  
---------------------------------------------------------------------------------------------------------------------------  
# 2.2.4 Can you work out the average monthly income of all sellers? Can you work out the average monthly income of Tech sellers?

# 2.2.4 Average monthly income of all sellers and Tech sellers

SELECT
    'All sellers' AS seller_type,
    ROUND(
        SUM(o.price) /
        (
            SELECT COUNT(DISTINCT DATE_FORMAT(
                order_purchase_timestamp, '%Y-%m'
            ))
            FROM orders
        ),
        2
    ) AS average_monthly_income
FROM order_items AS o

UNION ALL

SELECT
    'Tech sellers' AS seller_type,
    ROUND(
        SUM(o.price) /
        (
            SELECT COUNT(DISTINCT DATE_FORMAT(
                order_purchase_timestamp, '%Y-%m'
            ))
            FROM orders
        ),
        2
    ) AS average_monthly_income
FROM order_items AS o
JOIN products AS p
    ON o.product_id = p.product_id
JOIN product_category_name_translation AS pc
    ON p.product_category_name = pc.product_category_name
WHERE pc.product_category_name_english REGEXP
    'computer|electronic|telephon|phone|tablet|audio|camera|console|game|computers_accessories|apple|watch';
    
---------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------    
# 2.3.1 What’s the average time between the order being placed and the product being delivered?
    
    SELECT
    ROUND(
        AVG(
            DATEDIFF(
                order_delivered_customer_date,
                order_purchase_timestamp
            )
        ),
        2
    ) AS average_delivery_time_days
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

---------------------------------------------------------------------------------------------------------------------------

# 2.3.2 How many orders are delivered on time vs orders delivered with a delay?

SELECT
    CASE
        WHEN order_delivered_customer_date <= order_estimated_delivery_date
            THEN 'On time'
        WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 'Delayed'
    END AS delivery_status,
    COUNT(order_id) AS number_of_orders
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
GROUP BY delivery_status;

---------------------------------------------------------------------------------------------------------------------------
# 2.3.3 Is there any pattern for delayed orders, e.g. big products being delayed more often?

SELECT CASE
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
		THEN 'on time'
        ELSE 'delayed'
    END AS delivery_status,

    ROUND(AVG(p.product_weight_g), 2) AS avg_product_weight,
    COUNT(DISTINCT o.order_id) AS order_count

FROM orders AS o
JOIN order_items AS oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id

WHERE o.order_status = 'delivered'AND o.order_delivered_customer_date IS NOT NULL

GROUP BY delivery_status;

