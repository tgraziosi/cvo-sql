SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_cust_analysis] 
@range varchar(8000) = '0=0'
as

CREATE TABLE #temp (
order_no int NULL,
order_ext int NULL,
cust_code varchar(10) NULL,
sch_ship_date datetime NULL,
date_shipped datetime NULL,
ship_amt decimal(20,8) NULL,
Backordered int,
Early int,
Late int,
OnTime int )

create TABLE #temp1 (
yyyymm varchar(6),
Backordered int,
Early int,
Late int,
OnTime int )

select @range = replace(@range,'"','''')
select @range = replace(@range,'s.date_shipped',' datediff(day,''01/01/1900'',s.date_shipped) + 693596 ')


exec('INSERT INTO #temp
SELECT distinct  s.order_no, s.order_ext , s.cust_code, NULL ,
  s.date_shipped, sum(s.shipped * s.price),
case when s.order_ext > 0 then 1 else 0 end ''Backordered'', 0, 0, 0
FROM shippers s (nolock), locations l (nolock), region_vw r (nolock)
WHERE    l.location = s.location and 
   l.organization_id = r.org_id and
' + @range + '
GROUP BY s.order_no, s.order_ext, s.cust_code, s.date_shipped')

update #temp
set sch_ship_date = o.sch_ship_date,
Early = case when convert(varchar(8),t.date_shipped,112) < convert(varchar(8),isnull(o.sch_ship_date,t.date_shipped),112) 
  then 1 else 0 end,
Late = case when convert(varchar(8),t.date_shipped,112) > convert(varchar(8),isnull(o.sch_ship_date,t.date_shipped),112) 
  then 1 else 0 end ,
OnTime = case when convert(varchar(8),t.date_shipped,112) = convert(varchar(8),isnull(o.sch_ship_date,t.date_shipped),112) 
  then 1 else 0 end 
from #temp t, orders_all o
where t.order_no = o.order_no and t.order_ext = o.ext

INSERT #temp1
select substring(convert(varchar(8), date_shipped, 112),1,6), sum(Backordered), sum(Early), sum(Late), sum(OnTime)
from #temp
group by substring(convert(varchar(8), date_shipped, 112),1,6)

update #temp set
Early = t1.Early,
Late = t1.Late,
OnTime = t1.OnTime
from #temp t, #temp1 t1
where substring(convert(varchar(8), t.date_shipped, 112),1,6) = t1.yyyymm

select * from #temp
ORDER BY date_shipped, order_no, order_ext

GO
GRANT EXECUTE ON  [dbo].[adm_cust_analysis] TO [public]
GO
