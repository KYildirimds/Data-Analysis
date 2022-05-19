



---- RDB & SQL Session 10-11 (WF 2-3)


--Assign an ordinal number to the product prices for each category in ascending order
--1. Herbir kategori içinde ürünlerin fiyat sýralamasýný yapýnýz (artan fiyata göre 1'den baþlayýp birer birer artacak)



SELECT category_id, list_price, ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY list_price) AS ROW_NUM
FROM product.product




SELECT category_id, list_price, 
		ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY list_price) AS ROW_NUM,
		RANK() OVER (PARTITION BY category_id ORDER BY list_price) AS RANK_,
		DENSE_RANK() OVER (PARTITION BY category_id ORDER BY list_price) AS DENSE
FROM product.product



-------------


--Write a query that returns the order date of the one previous sale of each staff (use the LAG function)
--1. Herbir personelin bir önceki satýþýnýn sipariþ tarihini yazdýrýnýz (LAG fonksiyonunu kullanýnýz)





SELECT	DISTINCT A.order_id, B.staff_id, B.first_name, B.last_name, order_date, 
		LAG(order_date, 1) OVER(PARTITION BY B.staff_id ORDER BY order_id) previous_order_date
FROM	sale.orders A, sale.staff B
WHERE	A.staff_id = B.staff_id
;

--Write a query that returns how many days are between the third and fourth order dates of each staff.
--Her bir personelin üçüncü ve dördüncü sipariþleri arasýndaki gün farkýný bulunuz.

WITH T1 AS
(
SELECT	DISTINCT A.order_id, B.staff_id, B.first_name, B.last_name, order_date, 
		LAG(order_date, 1) OVER(PARTITION BY B.staff_id ORDER BY order_id) previous_order_date,
		ROW_NUMBER() OVER (PARTITION BY B.staff_id ORDER BY order_id) ord_number
FROM	sale.orders A, sale.staff B
WHERE	A.staff_id = B.staff_id
) 
SELECT *, DATEDIFF ( DAY, previous_order_date, order_date ) day_diff
FROM	T1
WHERE ord_number = 4




----

----PERCENTILE_CONT

----PERCENTILE_DISC



SELECT list_price, 

PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY list_price) OVER () median1,

PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY list_price) OVER ()median2,

avg(list_price) over ()

FROM PRODUCT.product




----

SELECT list_price, 

PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY list_price) OVER () median1,

PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY list_price) OVER ()median2

FROM PRODUCT.product
WHERE list_price <16000

----------------

SELECT list_price, 

PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY list_price) OVER () median1,

PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY list_price) OVER ()median2

FROM PRODUCT.product



------------------



-- Write a query that returns the cumulative distribution of the list price in product table by brand.

-- product tablosundaki list price' larýn kümülatif daðýlýmýný marka kýrýlýmýnda hesaplayýnýz

SELECT brand_id,
		list_price
FROM product.product




SELECT brand_id,
		list_price,
			ROUND(CUME_DIST() OVER(PARTITION BY brand_id ORDER BY list_price),3)
FROM product.product





---------------



--Write a query that returns both of the followings:
--The average product price of orders.
--Average net amount.


--Aþaðýdakilerin her ikisini de döndüren bir sorgu yazýn:
--Sipariþlerin ortalama ürün fiyatý.
--Ortalama net tutar.




SELECT DISTINCT order_id, 
AVG(list_price) OVER (PARTITION BY order_id) avg_price_of_prod,
AVG(quantity*list_price*(1-discount)) OVER () avg_net_amount
FROM sale.order_item



---------------------

--------///////


--List orders for which the average product price is higher than the average net amount.
--Ortalama ürün fiyatýnýn ortalama net tutardan yüksek olduðu sipariþleri listeleyin.




WITH T1 AS
(
SELECT DISTINCT order_id, 
		AVG(list_price) OVER (PARTITION BY order_id) avg_price_of_prod,
		AVG(quantity*list_price*(1-discount)) OVER () avg_net_amount
FROM sale.order_item
)
SELECT *
FROM T1
WHERE	avg_price_of_prod > avg_net_amount




-----------/////////////////

--Calculate the stores' weekly cumulative number of orders for 2018
--maðazalarýn 2018 yýlýna ait haftalýk kümülatif sipariþ sayýlarýný hesaplayýnýz



SELECT b.store_id, b.store_name, DATEPART(WK, order_date) WK, order_id,

		COUNT (*) OVER (PARTITION BY b.store_id ORDER BY DATEPART(WK, order_date))
FROM sale.orders A, sale.store B
WHERE A.store_id = B.store_id
AND	YEAR (a.order_date) = 2018
order by 1,2



SELECT DISTINCT b.store_id, b.store_name, order_date,
		COUNT(*) OVER (PARTITION BY order_date, b.store_id) cnt_order_by_week,
		COUNT (*) OVER (PARTITION BY b.store_id ORDER BY order_date)
FROM sale.orders A, sale.store B
WHERE A.store_id = B.store_id
AND	YEAR (a.order_date) = 2018




SELECT  product_id, list_price, sum(list_price) OVER (order by product_id)
FROM product.product



SELECT  list_price, sum(list_price) OVER (order by list_price ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
FROM product.product


-------


-----/////


--Calculate 7-day moving average of the number of products sold between '2018-03-12' and '2018-04-12'.
--'2018-03-12' ve '2018-04-12' arasýnda satýlan ürün sayýsýnýn 7 günlük hareketli ortalamasýný hesaplayýn.



WITH T1 AS
(
SELECT	DISTINCT A.order_date, SUM (quantity) OVER (PARTITION BY A.order_date) cnt_product
FROM	sale.orders A, sale.order_item B
WHERE	A.order_id = B.order_id
AND		A.order_date BETWEEN '2018-03-12' AND '2018-04-12'
)
SELECT order_date, cnt_product,
		AVG(cnt_product) OVER (ORDER BY ORDER_DATE ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
FROM T1








