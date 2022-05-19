----- DS DE WEEKLY AGENDA WEEK-10 RDB&SQL QUESTIONS-3-----

-----1. Report cumulative total turnover by months in each year in pivot table format.

SELECT * 
FROM
	(
	SELECT	distinct YEAR (A.order_date) ord_year, MONTH(A.order_date) ord_month, 
	SUM(quantity*list_price) OVER (PARTITION BY YEAR (A.order_date) ORDER BY YEAR (A.order_date), MONTH(A.order_date)) turnover
	FROM	sale.orders A, sale.order_item B
	WHERE	A.order_id = B.order_id
	) A
PIVOT
	(
	MAX(turnover)
	FOR ord_year
	IN ([2018], [2019],[2020])
	)
PIVOT_TA

---- 2. What percentage of customers purchasing a product have purchased the same product again?----

WITH T1 AS 
(
SELECT B.product_id, COUNT (DISTINCT a.customer_id) cnt_cust
FROM sale.orders A, SALE.order_item B
WHERE A.order_id = B.order_id
GROUP BY b.product_id
), T2 AS
(
SELECT  T1.product_id, cnt_cust,
COUNT (*) OVER (PARTITION BY T1.product_id, C.customer_id) cnt_customer_product
FROM sale.customer C, sale.orders D, sale.order_item E, T1
WHERE C.customer_id = D.customer_id
AND	D.order_id = E.order_id
AND	E.product_id =T1.product_id
) 
SELECT DISTINCT product_id,
FIRST_VALUE (CASE WHEN cnt_customer_product = 1 THEN 0 
				  ELSE CAST(1.0*cnt_customer_product/cnt_cust AS NUMERIC(4,3)) 
			 END) 
		OVER (PARTITION BY product_id ORDER BY (CASE WHEN cnt_customer_product = 1 THEN 0 
													 ELSE CAST(1.0*cnt_customer_product/cnt_cust AS NUMERIC(4,3)) 
													END) DESC)
FROM T2 



----3. From the following table of user IDs, actions, and dates, write a query to return the publication and cancellation rate for each user.


-- CREATING DATABASE

CREATE DATABASE Assignment_2;

-- CREATING TABLE

CREATE TABLE pubcan (
					User_id int,
					Action varchar(255),
					Date varchar(255)
					);

-- INSERT VALUES INTO TABLE

INSERT INTO Assignment_2.dbo.pubcan (User_id, Action, Date)

VALUES

(1,'Start','1-1-20'),
(1,'Cancel','1-2-20'),
(2,'Start','1-3-20'),
(2,'Publish','1-4-20'),
(3,'Start','1-5-20'),
(3,'Cancel','1-6-20'),
(1,'Start','1-7-20'),
(1,'Publish','1-8-20')

SELECT *
FROM pubcan

-- SOLUTION WITH CREATING VIEW AND USING CAST () FUNCTION

CREATE VIEW View_Ass_2 AS

SELECT	User_id, Start, Publish, Cancel
FROM (
	SELECT
			User_id,
			SUM(CASE WHEN Action = 'Start' THEN 1 ELSE 0 END) AS Start,
			SUM(CASE WHEN Action = 'Publish' THEN 1 ELSE 0 END) AS Publish,
			SUM(CASE WHEN Action = 'Cancel' THEN 1 ELSE 0 END) AS Cancel
	FROM pubcan
	GROUP BY User_id
	) AS A
;

SELECT
		User_id,
		CAST((1.0 * Publish / Start) AS NUMERIC(2,1)) AS 'Publish_rate',
		CAST((1.0 * Cancel / Start) AS NUMERIC(2,1)) AS 'Cancel_rate'
FROM View_Ass_2



-- SOLUTION WITH THE SAME VIEW AND USING CONVERT () FUNCTION

SELECT
		User_id,
		CONVERT(NUMERIC(2,1), (1.0 * Publish / Start)) AS 'Publish_rate',
		CONVERT(NUMERIC(2,1), (1.0 * Cancel / Start)) AS 'Cancel_rate'
FROM View_Ass_2



-- SOLUTION WITH CREATING TABLE WITH SELECT INTO STATEMENT AND USING CAST () FUNCTION

SELECT
		User_id,
		SUM(CASE WHEN Action = 'Start' THEN 1 ELSE 0 END) AS Start,
		SUM(CASE WHEN Action = 'Publish' THEN 1 ELSE 0 END) AS Publish,
		SUM(CASE WHEN Action = 'Cancel' THEN 1 ELSE 0 END) AS Cancel
INTO pubcanrate
FROM pubcan
GROUP BY User_id

SELECT
		User_id,
		CAST((1.0 * Publish / Start) AS NUMERIC(2,1)) AS 'Publish_rate',
		CAST((1.0 * Cancel / Start) AS NUMERIC(2,1)) AS 'Cancel_rate'
FROM pubcanrate



-- SOLUTION WITH USING ABOVE TABLE AND USING STR () FUNCTION

SELECT
		User_id,
		STR(1.0 * Publish / Start, 4, 2) AS 'Publish_rate',
		STR(1.0 * Cancel / Start, 4, 2) AS 'Cancel_rate'
FROM pubcanrate

