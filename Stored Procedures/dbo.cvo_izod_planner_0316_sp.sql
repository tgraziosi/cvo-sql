
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_izod_planner_0316_sp]
	@ResType VARCHAR(1000), @Brand VARCHAR(1000), @Demo VARCHAR(1000), @MinSales DECIMAL (20,8)
AS 
BEGIN
SET NOCOUNT ON
SET ANSI_WARNINGS OFF

--DECLARE @ResType VARCHAR(1000), @Brand VARCHAR(1000), @Demo VARCHAR(1000), @MinSales DECIMAL (20,8)
--SELECT @restype = 'Frame', @brand = 'IZX,IZOD', @demo = 'Female-adult,male-adult,unisex-adult'

CREATE TABLE #brand ([brand] VARCHAR(10))
	if @brand is null
	begin
		insert into #brand ([brand])
		select distinct kys from category where isnull(void,'n') = 'n' 
	end
	else
	begin
		INSERT INTO #brand ([brand])
		SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@Brand)
	end

CREATE TABLE #restype ([restype] VARCHAR(10))
	if @restype is null
	begin
		insert into #restype ([restype])
		select distinct type_code from inv_master (NOLOCK) where isnull(void,'n') = 'n' 
	end
	else
	begin
		INSERT INTO #restype ([restype])
		SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@restype)
	END
    
CREATE TABLE #demo ([demo] VARCHAR(15))
	if @demo is null
	begin
		insert into #demo ([demo])
		select distinct category_2 from inv_master_add 
	end
	else
	begin
		INSERT INTO #demo ([demo])
		SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@demo)
	end

IF @minsales IS NULL SELECT @minsales = 1000


SELECT ar.territory_code, ar.customer_code, ar.ship_to_code, ar.address_name, ar.city, ar.postal_code
, CASE WHEN promo.cust_code IS NULL THEN 'No' ELSE 'Yes' END AS Promo_Activity
		, SUM(custsales.NetSales_2013) NetSales_2013
		, SUM(custsales.NetSales_2014) NetSales_2014
		, SUM(custsales.NetSales_2015) NetSales_2015
FROM 
(SELECT customer, ship_to
, CASE WHEN c_year = 2013 THEN SUM(anet) ELSE 0 END AS NetSales_2013
, CASE WHEN c_year = 2014 THEN SUM(anet) ELSE 0 END AS NetSales_2014
, CASE WHEN c_year = 2015 THEN SUM(anet) ELSE 0 END AS NetSales_2015
FROM dbo.cvo_sbm_details AS sbm
INNER JOIN dbo.inv_master AS i ON i.part_no = sbm.part_no
INNER JOIN dbo.inv_master_add AS ia ON ia.part_no = sbm.part_no
JOIN #restype ON  #restype.restype = i.type_code
JOIN #demo ON #demo.demo = ia.category_2
JOIN #brand ON #brand.brand = i.category
WHERE sbm.c_year IN (2013,2014,2015)
--AND i.type_code IN ('frame')
--AND i.category IN ('izx','izod')
AND i.void = 'N'
--AND ia.category_2 LIKE '%adult%'
GROUP BY customer, ship_to,
		 c_year
) custsales

INNER JOIN armaster ar ON ar.customer_code = custsales.customer AND ar.ship_to_code = custsales.ship_to
LEFT OUTER JOIN
(SELECT DISTINCT o.cust_code, ship_to
FROM cvo_orders_all co JOIN orders o ON o.ext = co.ext AND o.order_no = co.order_no
WHERE co.promo_id = 'IZOD CLEAR' OR (CO.PROMO_ID = 'IZOD' AND CO.promo_level IN ('CARBON','PROFLEX','T & C')) 
AND o.status = 't'
) promo ON promo.ship_to = custsales.ship_to AND promo.cust_code = custsales.customer
WHERE custsales.NetSales_2013 > @MinSales OR custsales.NetSales_2014 > @MinSales OR custsales.NetSales_2015 > @MinSales
GROUP BY ar.territory_code, ar.customer_code, ar.ship_to_code, ar.address_name, ar.city, ar.postal_code, promo.cust_code

END

GO

GRANT EXECUTE ON  [dbo].[cvo_izod_planner_0316_sp] TO [public]
GO
