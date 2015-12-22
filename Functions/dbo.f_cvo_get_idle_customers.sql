SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[f_cvo_get_idle_customers] (@terr VARCHAR(1000) = null,  @months_idle INT = 6, @top_x INT = 10 )
	RETURNS @idle_cust TABLE
	(customer_code VARCHAR(10)
	, ship_to_code VARCHAR(10)
	, cust_name VARCHAR(60)
	, netsales DECIMAL (20,8)
	, idle_date DATETIME
    , territory VARCHAR(8)
	, last_activity datetime
	)

AS
BEGIN

/*
 8/11/2015 - tag
 
 usage:

 select * From dbo.f_cvo_get_idle_customers ( '20201' , 6 , 10) 
  
 An idle customer has not had any activity in the past 6 months
 , and has >2400 activity in the rolling 12 period prior. (months 6 - 18)
*/

DECLARE @asofdate DATETIME
SElect @asofdate = DATEADD(dd,DATEDIFF(dd,0,GETDATE()), 0 )

-- SELECT DATEADD(day,1,dateadd(month,-6,@asofdate)) , @asofdate

-- uncomment to test
--declare @Terr varchar(1000)
--select  @Terr = null

DECLARE @territory TABLE (territory varchar(8))

if @Terr is null
begin
 insert into @territory (territory)
 select distinct territory_code from armaster (nolock) 
 where address_type <> 9 
end
else
begin
 insert into @territory (territory)
 select listitem from dbo.f_comma_list_to_table(@Terr)
end

-- Get the 12months prior sales for customers that have no stock order in the last 6 months
DECLARE @last_terr VARCHAR(8)
SELECT @last_terr = ''

SELECT @last_terr = MIN(territory) FROM @territory 
WHERE territory > @last_terr

WHILE @last_Terr IS NOT NULL
BEGIN

INSERT INTO @idle_cust
        ( customer_code ,
          ship_to_code ,
          cust_name ,
          netsales,
		  idle_date,
		  territory,
		  last_activity
        )

SELECT TOP (@top_x)
ar.customer_code, ar.ship_to_code, ar.address_name, sales.netsales
, idle_date = dateadd(day,1,dateadd(month,-@months_idle,@asofdate))
, ar.territory_code
, m.last_activity

FROM armaster ar (NOLOCK) 
INNER join
	( SELECT ar.customer_code, ar.ship_to_code, ar.status_type
	FROM armaster ar (NOLOCK) 
	INNER JOIN dbo.CVO_armaster_all car (NOLOCK) ON ar.customer_code = car.customer_code AND ar.ship_to_code = car.ship_to
	WHERE ar.territory_code = @last_terr
	AND car.door = 1
	AND NOT EXISTS
	(SELECT 1 	
	FROM ORDERS_ALL (NOLOCK) T1
	JOIN ORD_LIST (NOLOCK) T2 ON T1.ORDER_NO = T2.ORDER_NO AND T1.EXT=T2.ORDER_EXT
	join inv_master (NOLOCK) t3 ON t2.part_no=t3.part_no
	where 
	t1.cust_code=ar.customer_code and t1.ship_to=ar.ship_to_code 
	and t1.status='t' 	and t1.type='i' 	and t1.who_entered <> 'backordr' 	AND t3.type_code in ('frame','sun')
	and t1.DATE_ENTERED between dateadd(day,1,dateadd(month,-@months_idle,@asofdate)) and @asofdate
	AND t1.user_category not like 'rx%'
	-- GROUP BY t1.cust_code, t1.ship_to
	HAVING sum(t2.ordered) >= 5
	)
) AS idle ON idle.customer_code = ar.customer_code AND idle.ship_to_code = ar.ship_to_code

INNER join
	(SELECT sbm.customer, sbm.ship_to, SUM(anet) netsales 
	FROM armaster ar (NOLOCK) 
	INNER JOIN cvo_sbm_details sbm (NOLOCK) ON sbm.customer = ar.customer_code AND sbm.ship_to = ar.ship_to_code
	WHERE ar.territory_code = @last_terr
	AND sbm.yyyymmdd BETWEEN dateadd(day,1,dateadd(month,-@months_idle-12,@asofdate)) 
	AND dateadd(month,-@months_idle,@asofdate)
	-- AND sbm.user_category NOT LIKE 'rx%'
	-- AND sbm.iscl = 0
	GROUP BY sbm.customer, sbm.ship_to
	HAVING SUM(anet) > 2400
	) AS sales ON sales.customer = idle.customer_code AND sales.ship_to = idle.ship_to_code
LEFT OUTER JOIN
	(
	SELECT customer, ship_to, MAX(dateordered) last_activity
	FROM dbo.cvo_sbm_details 
	WHERE user_category LIKE 'st%' AND user_category NOT LIKE '%rb'
	AND yyyymmdd BETWEEN dateadd(day,1,dateadd(month,-@months_idle-12,@asofdate)) and @asofdate
	GROUP BY customer, ship_to
	) AS m ON m.customer = ar.customer_code AND m.ship_to = ar.ship_to_code

WHERE ar.territory_code = @last_terr
ORDER BY sales.netsales DESC

SELECT @last_terr = MIN(territory) FROM @territory WHERE territory > @last_terr
end

RETURN 
END


GO
GRANT REFERENCES ON  [dbo].[f_cvo_get_idle_customers] TO [public]
GO
GRANT SELECT ON  [dbo].[f_cvo_get_idle_customers] TO [public]
GO
