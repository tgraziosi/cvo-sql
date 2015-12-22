SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- select * from cvoemktgcusttypesvw where cust_type = 'inactive' and territory_code < '80000'

CREATE VIEW [dbo].[CvoEmktgCustTypesVw]
AS
SELECT 
-- Active customers
ar.customer_code, ar.ship_to_code, ar.address_name, ar.contact_email
, ar.addr_sort1 customer_type
, ar.territory_code
, qual_fact = cast(rolling12net as varchar(30))
, 'Active  ' as Cust_type
FROM  (
SELECT DISTINCT customer, ship_to, rolling12net FROM   dbo.cvo_rad_shipto WITH (nolock)
WHERE
1=1 and
(X_MONTH = MONTH(GETDATE())) AND (year = YEAR(GETDATE())) AND (rolling12net >= 2880)) AS Sales 
INNER JOIN dbo.armaster AS ar WITH (nolock) ON Sales.customer = ar.customer_code AND Sales.ship_to = ar.ship_to_code
and ar.contact_email is not null and ar.status_type = 1
and ar.contact_email not in('refused','info@cvoptical.com','none')
         
union all 

SELECT 
-- Slow customers
ar.customer_code, ar.ship_to_code, ar.address_name, ar.contact_email
, ar.addr_sort1 customer_type
, ar.territory_code
, qual_fact = cast(rolling12net as varchar(30))
, 'Slow' as Cust_type
FROM  (
SELECT DISTINCT customer, ship_to, rolling12net FROM   dbo.cvo_rad_shipto WITH (nolock)
WHERE 
1=1 and
(X_MONTH = MONTH(GETDATE())) AND (year = YEAR(GETDATE())) AND (rolling12net between 1 and 2160)) AS Sales -- 90% 
INNER JOIN dbo.armaster AS ar WITH (nolock) ON Sales.customer = ar.customer_code AND Sales.ship_to = ar.ship_to_code
and ar.contact_email is not null and ar.contact_email not in('refused','none','info@cvoptical.com')

union all

select
-- Fall off Customers
ar.customer_code, ar.ship_to_code, ar.address_name, ar.contact_email
, ar.addr_sort1 customer_type
, ar.territory_code
, qual_fact = cast(last_order as varchar(30))
,'Fall off' as Cust_type
FROM  
(
select cust_code customer, ship_to, max(date_entered) last_order from orders
where 
1=1 
and status <> 'v' and who_entered not in ('backordr','outofstock') and user_category not in ('st-rb','rx-rb') and type = 'i'
group by cust_code, ship_to
) AS Sales 
INNER JOIN
dbo.armaster AS ar WITH (nolock) ON Sales.customer = ar.customer_code AND Sales.ship_to = ar.ship_to_code
where ar.status_type = 1
and last_order < dateadd(dd,-90,getdate())
and ar.contact_email is not null and ar.contact_email not in('refused','none','info@cvoptical.com')

union all

select
-- Fall off Customers
ar.customer_code, ar.ship_to_code, ar.address_name, ar.contact_email
, ar.addr_sort1 customer_type
, ar.territory_code
, qual_fact = cast(last_order as varchar(30))
,'Inactive' as Cust_type
FROM  
(
select cust_code customer, ship_to, max(date_entered) last_order from orders
where 
1=1 
and status <> 'v' and who_entered not in ('backordr','outofstock') and user_category not in ('st-rb','rx-rb') and type = 'i'
group by cust_code, ship_to
) AS Sales 
INNER JOIN
dbo.armaster AS ar WITH (nolock) ON Sales.customer = ar.customer_code AND Sales.ship_to = ar.ship_to_code
where ar.status_type = 1
and last_order < dateadd(yy,-1,getdate())
and ar.contact_email is not null and ar.contact_email not in('refused','none','info@cvoptical.com')
          
union all
-- Consistent
select
ar.customer_code, ar.ship_to_code, ar.address_name, ar.contact_email
, ar.addr_sort1 customer_type
, ar.territory_code
, qual_fact = cast(week_num as varchar(30))
, 'Consitnt' as Cust_type
FROM  
(
select c.cust_code customer, c.ship_to ship_to, count(c.week_num) week_num
from
(
select datepart(week, date_entered) week_num, count(order_no) num_orders, cust_code, ship_to
from orders
where 
1=1
and status <> 'v' and who_entered not in ('backordr','outofstock')
and (user_category like 'st%' or user_category like 'rx%')
and user_category not in ('st-rb','rx-rb') and type = 'i'
and date_entered between dateadd(ww,-8,getdate()) and getdate()
group by cust_code, ship_to, datepart(week, date_entered)
having count(order_no) > 1
) as c
 group by c.cust_code, c.ship_to
 having count(c.week_num) = 8
) as Sales
INNER JOIN dbo.armaster AS ar (nolock) ON Sales.customer = ar.customer_code AND Sales.ship_to = ar.ship_to_code
where ar.contact_email is not null and ar.status_type = 1 
and ar.contact_email not in('refused','none','info@cvoptical.com')
           
union all

-- testing
            
SELECT 
ar.customer_code, ar.ship_to_code, ar.address_name,  ar.contact_email
, ar.addr_sort1 customer_type
, ar.territory_code
, qual_fact = 'testing'
,'testing' as cust_type
FROM dbo.armaster ar (nolock) where ar.customer_code = '000010'
and ar.contact_email is not null

union all
select '999999','','Tine Graziosi','tgraziosi@gmail.com','testing','99999','testing','testing'
union all
select '999999','','Mary Tarantino','mtarantino@cvoptical.com','testing','99999','testing','testing'





GO
GRANT REFERENCES ON  [dbo].[CvoEmktgCustTypesVw] TO [public]
GO
GRANT SELECT ON  [dbo].[CvoEmktgCustTypesVw] TO [public]
GO
GRANT INSERT ON  [dbo].[CvoEmktgCustTypesVw] TO [public]
GO
GRANT DELETE ON  [dbo].[CvoEmktgCustTypesVw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CvoEmktgCustTypesVw] TO [public]
GO
