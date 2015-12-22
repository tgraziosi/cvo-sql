SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_ship_sum] @t1 varchar(10), @t2 varchar(10), @d1 datetime, @d2 datetime, @c1 varchar(10),@ct char(1),
@loc varchar(10), @part varchar(30) AS 

create table #tempshipsum (t varchar(10) null, c varchar(10), sp money)

insert into #tempshipsum
select ship_to_region, cust_code, sum( ( shipped - cr_shipped ) * price) 
from shippers (nolock)
where 
(cust_code like @c1) and (date_shipped >= @d1) and (date_shipped <= @d2) and 
(shippers.cust_type like @ct OR @ct='%') and 
((ship_to_region is null and @t1='%') OR ship_to_region like @t1) and
((salesperson is null and @t2='%') OR salesperson like @t2) and
((location is null and @loc='%') OR location like @loc) and
((part_no is null and @part= '%') or part_no like @part)
group by ship_to_region, cust_code 
order by ship_to_region, cust_code

select t, c, sp, customer_name, @t1, @t2, @d1, @d2, @loc 
from #tempshipsum , adm_cust_all 
where c=customer_code
order by t, c

GO
GRANT EXECUTE ON  [dbo].[fs_ship_sum] TO [public]
GO
