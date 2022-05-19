/* Cleaning data set, definig keys and change the table data formats*/
select * from cust_dimen
update cust_dimen
set Cust_id = REPLACE(Cust_id,'Cust_','')
alter table cust_dimen alter column Cust_id int
select * from cust_dimen
------------
select * from orders_dimen
update orders_dimen
set Ord_id = REPLACE(Ord_id,'Ord_','')
alter table orders_dimen alter column Ord_id int
select * from orders_dimen
-----
select * from prod_dimen
update prod_dimen
set Prod_id = REPLACE(Prod_id,'Prod_','')
alter table prod_dimen alter column Prod_id int
select * from prod_dimen
----------
select * from shipping_dimen
update shipping_dimen
set Ship_id = REPLACE(Ship_id,'SHP_','')
alter table shipping_dimen alter column Ship_id int
select * from shipping_dimen
----------------------------
select * from market_fact
update market_fact
set Ord_id = REPLACE(Ord_id,'Ord_','')
alter table market_fact alter column Ord_id int
update market_fact
set Prod_id = REPLACE(Prod_id,'Prod_','')
alter table market_fact alter column Prod_id int
update market_fact
set Ship_id = REPLACE(Ship_id,'SHP_','')
alter table market_fact alter column Ship_id int
update market_fact
set Cust_id = REPLACE(Cust_id,'Cust_','')
alter table market_fact alter column Cust_id int
select * from market_fact

------------------------------------




--E-Commerce Project Solution



--1. Join all the tables and create a new table called combined_table. (market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)
/*Making a combined table*/
SELECT distinct *
INTO
combined_table
FROM
(
SELECT
cd.Cust_id, cd.Customer_Name, cd.Province, cd.Region, cd.Customer_Segment,
mf.Ord_id, mf.Prod_id, mf.Sales, mf.Discount, mf.Order_Quantity, mf.Product_Base_Margin,
od.Order_Date, od.Order_Priority,
pd.Product_Category, pd.Product_Sub_Category,
sd.Ship_id, sd.Ship_Mode, sd.Ship_Date
FROM market_fact mf
INNER JOIN cust_dimen cd ON mf.Cust_id = cd.Cust_id
INNER JOIN orders_dimen od ON od.Ord_id = mf.Ord_id
INNER JOIN prod_dimen pd ON pd.Prod_id = mf.Prod_id
INNER JOIN shipping_dimen sd ON sd.Ship_id = mf.Ship_id
) A;
select * from combined_table


--2. Find the top 3 customers who have the maximum count of orders.

SELECT TOP 3 Cust_id, COUNT(Ord_id) AS orders
FROM combined_table
GROUP BY Cust_id
ORDER BY COUNT(Ord_id) DESC


--/////////////////////////////////

--3.Create a new column at combined_table as DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.
--Use "ALTER TABLE", "UPDATE" etc.

ALTER TABLE combined_table
ADD DaysTakenForDelivery INT;

UPDATE combined_table
SET DaysTakenForDelivery = DATEDIFF (DAY, Order_Date, Ship_Date)

SELECT TOP 5 *
FROM combined_table

--////////////////////////////////////

--4. Find the customer whose order took the maximum time to get delivered.
--Use "MAX" or "TOP"

SELECT TOP 1 Cust_id, Customer_Name, Order_Date, Ship_Date,DaysTakenForDelivery
FROM combined_table
ORDER BY 5 DESC

--////////////////////////////////


--5. Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011
--You can use date functions and subqueries

SELECT DATEPART(MONTH, Order_Date) AS [MONTH], COUNT(DISTINCT Cust_id) AS MONTHLY_NUM_OF_CUST
FROM combined_table
WHERE DATEPART(YEAR, Order_Date) = 2011 AND
Cust_id in
(
SELECT DISTINCT Cust_id   
FROM combined_table
WHERE DATEPART(MONTH, Order_Date) = 1
AND DATEPART(YEAR, Order_Date) = 2011
)
GROUP BY DATEPART(MONTH, Order_Date)


--////////////////////////////////////////////


--6. write a query to return for each user acording to the time elapsed between the first purchasing and the third purchasing, 
--in ascending order by Customer ID
--Use "MIN" with Window Functions

CREATE VIEW View_1 AS
WITH T1 AS
(
SELECT DISTINCT Cust_id, Order_Date, MIN(Order_Date) OVER (PARTITION BY Cust_id) AS FIRST_ORDER_DATE 
FROM combined_table
)
SELECT Cust_id, Order_Date , ROW_Number () OVER (PARTITION BY Cust_id ORDER BY Cust_id ASC) dense_number, FIRST_ORDER_DATE
FROM T1;

SELECT *, DATEDIFF(DAY,FIRST_ORDER_DATE,Order_Date) AS DAYS_ELAPSED
FROM View_1
WHERE dense_number =3
ORDER BY Cust_id

--//////////////////////////////////////

--7. Write a query that returns customers who purchased both product 11 and product 14, 
--as well as the ratio of these products to the total number of products purchased by all customers.
--Use CASE Expression, CTE, CAST and/or Aggregate Functions

with T1 AS
(
SELECT Cust_id, SUM(CASE WHEN Prod_id = 11 THEN Order_quantity ELSE 0 END) AS P11 , SUM(CASE WHEN Prod_id = 14 THEN Order_Quantity ELSE 0 END) AS P14, 
SUM(CASE WHEN Prod_id > 0 THEN Order_Quantity ELSE 0 END) AS TOTAL_PROD, 
CAST(SUM(CASE WHEN Prod_id = 11 THEN Order_quantity ELSE 0 END)/SUM(CASE WHEN Prod_id > 0 THEN Order_Quantity ELSE 0 END) AS numeric (3,2)) AS RATIO_P11,
CAST(SUM(CASE WHEN Prod_id = 14 THEN Order_Quantity ELSE 0 END)/SUM(CASE WHEN Prod_id > 0 THEN Order_Quantity ELSE 0 END) AS numeric (3,2)) AS RATIO_P14
FROM combined_table
group by Cust_id
)
SELECT * 
FROM T1
WHERE P11 <> 0 AND P14 <> 0
ORDER BY 1

--/////////////////


--CUSTOMER SEGMENTATION

--1. Create a view that keeps visit logs of customers on a monthly basis. (For each log, three field is kept: Cust_id, Year, Month)
--Use such date functions. Don't forget to call up columns you might need later.
Create View View_2 AS

select Cust_id, year(Order_date) as [YEAR], DATEPART(MONTH,Order_Date) as[MONTH],Prod_id, Order_Date, count (Prod_id) as prod
from combined_table
group by  Cust_id, year(Order_date) , DATEPART(MONTH,Order_Date), Prod_id, Order_Date


select Cust_id,[YEAR],[MONTH]
FROM View_2
ORDER BY 1

--//////////////////////////////////



  --2.Create a “view” that keeps the number of monthly visits by users. (Show separately all months from the beginning  business)
--Don't forget to call up columns you might need later.
Create View View_3 AS
select distinct Cust_id, [YEAR],[MONTH], 
count(Prod_id) over(PARTITION BY Cust_id,[YEAR], [MONTH] ORDER by Cust_id,[YEAR] ) NUM_OF_LOG, 
DATEDIFF(month,'2008-12-01', Order_Date) as CURRENT_MONTH
from View_2


select distinct Cust_id, [YEAR],[MONTH], NUM_OF_LOG
FROM View_3


--//////////////////////////////////

--3. For each visit of customers, create the next month of the visit as a separate column.
--You can order the months using "DENSE_RANK" function.
--then create a new column for each month showing the next month using the order you have made above. (use "LEAD" function.)
--Don't forget to call up columns you might need later.

WITH T1 AS
(
SELECT *,
DENSE_RANK() OVER (PARTITION BY Cust_id,[YEAR] ORDER BY Cust_id,[YEAR], [MONTH]) AS DENSE
FROM View_3
)
SELECT Cust_id, [YEAR], [MONTH], NUM_OF_LOG, CURRENT_MONTH, ISNULL(LEAD (CURRENT_MONTH, 1) OVER(PARTITION BY Cust_id ORDER BY CURRENT_MONTH), NULL) AS NEXT_VISIT_MONTH
FROM T1
ORDER BY 1
------OR----
SELECT Cust_id, [YEAR], [MONTH], NUM_OF_LOG, CURRENT_MONTH, ISNULL(LEAD (CURRENT_MONTH, 1) OVER(PARTITION BY Cust_id ORDER BY CURRENT_MONTH), NULL) AS NEXT_VISIT_MONTH
FROM View_3
ORDER BY 1

--/////////////////////////////////

--4. Calculate monthly time gap between two consecutive visits by each customer.
--Don't forget to call up columns you might need later.


SELECT Cust_id, [YEAR], [MONTH], NUM_OF_LOG, CURRENT_MONTH, ISNULL(LEAD (CURRENT_MONTH, 1) OVER(PARTITION BY Cust_id ORDER BY CURRENT_MONTH), NULL) AS NEXT_VISIT_MONTH,
ISNULL(LEAD (CURRENT_MONTH, 1) OVER(PARTITION BY Cust_id ORDER BY CURRENT_MONTH), NULL) - CURRENT_MONTH  AS TIME_GAPS
FROM View_3


--/////////////////////////////////////////


--5.Categorise customers using average time gaps. Choose the most fitted labeling model for you.
--For example: 
--Labeled as “churn” if the customer hasn't made another purchase for the months since they made their first purchase.
--Labeled as “regular” if the customer has made a purchase every month.
--Etc.
CREATE VIEW View_4 AS	
WITH T1 AS
(
SELECT Cust_id, [YEAR], [MONTH], NUM_OF_LOG, CURRENT_MONTH, ISNULL(LEAD (CURRENT_MONTH, 1) OVER(PARTITION BY Cust_id ORDER BY CURRENT_MONTH), NULL) AS NEXT_VISIT_MONTH,
ISNULL(LEAD (CURRENT_MONTH, 1) OVER(PARTITION BY Cust_id ORDER BY CURRENT_MONTH), NULL) - CURRENT_MONTH  AS TIME_GAPS
FROM View_3
)
SELECT DISTINCT Cust_id, AVG(TIME_GAPS) OVER (PARTITION BY Cust_id) AS AVG_TIME_GAP
FROM T1

SELECT *,
CASE
	WHEN AVG_TIME_GAP = 1 THEN 'Regular'
	WHEN AVG_TIME_GAP > 2 THEN 'Irregular'
	ELSE 'Churn'
	END AS CUST_LABELS
FROM View_4
ORDER BY 1

--/////////////////////////////////////

--MONTH-WISE RETENTÝON RATE

--Find month-by-month customer retention rate  since the start of the business.


--1. Find the number of customers retained month-wise. (You can use time gaps)
--Use Time Gaps

WITH T1 AS
(
SELECT Cust_id, [YEAR], [MONTH], NUM_OF_LOG, CURRENT_MONTH, ISNULL(LEAD (CURRENT_MONTH, 1) OVER(PARTITION BY Cust_id ORDER BY CURRENT_MONTH), NULL) AS NEXT_VISIT_MONTH,
ISNULL(LEAD (CURRENT_MONTH, 1) OVER(PARTITION BY Cust_id ORDER BY CURRENT_MONTH), NULL) - CURRENT_MONTH  AS TIME_GAPS
FROM View_3)
SELECT Cust_id, [YEAR], [MONTH], CURRENT_MONTH, NEXT_VISIT_MONTH, TIME_GAPS, COUNT(Cust_id) OVER (PARTITION BY [YEAR],[MONTH]) AS RETENTION_MONTH_WISE
from T1
where TIME_GAPS = 1
ORDER BY 1


--//////////////////////


--2. Calculate the month-wise retention rate.

--Basic formula: o	Month-Wise Retention Rate = 1.0 * Number of Customers Retained in The Current Month / Total Number of Customers in the Current Month

--It is easier to divide the operations into parts rather than in a single ad-hoc query. It is recommended to use View. 
--You can also use CTE or Subquery if you want.

--You should pay attention to the join type and join columns between your views or tables.

CREATE VIEW View_6 AS
WITH T1 AS
(
SELECT Cust_id, [YEAR], [MONTH], NUM_OF_LOG, CURRENT_MONTH, ISNULL(LEAD (CURRENT_MONTH, 1) OVER(PARTITION BY Cust_id ORDER BY CURRENT_MONTH), NULL) AS NEXT_VISIT_MONTH,
ISNULL(LEAD (CURRENT_MONTH, 1) OVER(PARTITION BY Cust_id ORDER BY CURRENT_MONTH), NULL) - CURRENT_MONTH  AS TIME_GAPS
FROM View_3)
SELECT distinct [YEAR], [MONTH], CURRENT_MONTH, COUNT(Cust_id) OVER (PARTITION BY [YEAR],[MONTH]) AS RETENTION_MONTH_WISE
from T1
where TIME_GAPS = 1
AND CURRENT_MONTH >1
ORDER BY 1
drop VIEW View_7

CREATE VIEW View_7 AS
WITH T1 AS
(
SELECT Cust_id, [YEAR], [MONTH], NUM_OF_LOG, CURRENT_MONTH, ISNULL(LEAD (CURRENT_MONTH, 1) OVER(PARTITION BY Cust_id ORDER BY CURRENT_MONTH), NULL) AS NEXT_VISIT_MONTH,
ISNULL(LEAD (CURRENT_MONTH, 1) OVER(PARTITION BY Cust_id ORDER BY CURRENT_MONTH), NULL) - CURRENT_MONTH  AS TIME_GAPS
FROM View_3)
SELECT distinct [YEAR], [MONTH], CURRENT_MONTH, COUNT(Cust_id) OVER (PARTITION BY [YEAR],[MONTH]) AS RETENTION_MONTH_WISE_TOTAL
from T1
WHERE CURRENT_MONTH >1 AND
CURRENT_MONTH <48
ORDER BY 1

SELECT distinct A.YEAR, B.MONTH, CAST(1.0*A.RETENTION_MONTH_WISE/B.RETENTION_MONTH_WISE_TOTAL  as numeric (3,2)) AS RETENTION_RATE
FROM View_6 A, View_7 B
WHERE A.CURRENT_MONTH = B.CURRENT_MONTH
ORDER BY 1,2

---///////////////////////////////////
--Good luck!