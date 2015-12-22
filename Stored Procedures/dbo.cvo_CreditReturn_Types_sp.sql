SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_CreditReturn_Types_sp]
@sdate datetime,
@edate datetime

-- exec cvo_CreditReturn_Types_sp '10/1/2014','10/31/2014'
as 

select @edate = dateadd(ms,-1,dateadd(day,1,@edate))

select terr.region, terr.terr, terr.salesperson,
isnull(cust_code,'') cust_code, isnull(ship_to,'') ship_to ,
date_shipped, 
ord_date ,
days_open,
isnull(Return_type,'') Return_type,
who_entered, 
order_no,  
hs_order_no
from
(
SELECT dbo.calculate_Region_fn(Territory_code)Region,
Territory_code as Terr, 
Salesperson_name as Salesperson
FROM arsalesp 
Where 1=1
and status_type = 1
) as terr 
full outer join
(
select distinct ar.territory_code, 
o.order_no, 
o.cust_code, o.ship_to ,
o.date_shipped, 
dateadd(dd, datediff(dd, 0 , o.date_entered), 0) ord_date ,
convert(int,dateadd(dd, datediff(dd, date_entered , date_shipped ), 0))  days_open,
Return_type = 
case when convert(int,dateadd(dd, datediff(dd, date_entered , date_shipped ), 0)) 
< 3 and status in ('r','t') then 'Manual' else 
case when status in ('r','t') then 'RMA received' else 'RMA written/open' 
end end,
 o.who_entered, o.user_def_fld4 hs_order_no
From orders o
inner join armaster ar on ar.customer_code = o.cust_code and ar.ship_to_code = o.ship_to
where type = 'c' and status <> 'v'
and date_entered between @sdate and @edate
and exists ( select 1 from ord_list (nolock) 
-- only include RA returns
	where order_no = o.order_no and order_ext = o.ext and return_code in ('06-13') ) 
) as orders
on orders.territory_code = terr.terr


select * From po_retcode
GO
GRANT EXECUTE ON  [dbo].[cvo_CreditReturn_Types_sp] TO [public]
GO
