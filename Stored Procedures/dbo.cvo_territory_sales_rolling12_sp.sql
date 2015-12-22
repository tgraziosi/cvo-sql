SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_territory_sales_rolling12_sp]
@asofdate datetime
as
begin

-- exec cvo_territory_sales_rolling12_sp '8/31/2013'

--declare @compareyear varchar(1000)
--set @compareyear = '2013'

--declare @asofdate datetime
set @asofdate = dateadd(ms,-3, dateadd(dd, 1, @asofdate)) 

declare @start_ty datetime, @start_ly datetime, @end_ly datetime

set @start_ty = dateadd(ms,3, dateadd(m,-12, @asofdate))
set @start_ly = dateadd(ms,3, dateadd(m,-24, @asofdate))
set @end_ly = dateadd(m,-12, @asofdate)

--select @start_ty, @asofdate, @start_ly, @end_ly

declare @compareyear varchar(1000)
set @compareyear = datepart(year,@asofdate)

IF(OBJECT_ID('tempdb.dbo.#tsr') is not null)  drop table #tsr

CREATE TABLE #tsr
(territory_code	varchar(8),
salesperson_name varchar(40),
date_of_hire datetime,
yyear	int,
mmonth	varchar(15),
yyyymmdd	datetime,
anet	float,
agoal   float,
Region	varchar(3),
anet_ty float default 0,
anet_ly float default 0)

--insert into #tsr 
--(territory_code,
--salesperson_name,
--x_month,
--yyear,
--mmonth,
--yyyymmdd, anet, qnet, region, anet_mtd, 
--currentmonthsales, rrank) 

--exec cvo_territory_sales_sp @compareyear

insert into #tsr
(territory_code,
yyear,
mmonth,
yyyymmdd, 
anet) 
select 
ar.territory_code,
sbm.c_year,
sbm.c_month,
sbm.yyyymmdd,
sum(anet) anet
from
cvo_sbm_details sbm (nolock) 
inner join armaster ar (nolock) on ar.customer_code = sbm.customer  and ar.ship_to_code = sbm.ship_to
where yyyymmdd between @start_ly and @asofdate
group by ar.territory_code, sbm.c_year, sbm.c_month, sbm.yyyymmdd

-- get goals for the 12 month period
insert into #tsr
(territory_code,
yyear,
mmonth,
yyyymmdd, 
agoal)
select territory_code,
yyear,
mmonth,
cast ((cast([mmonth] as varchar(2))+'/01/'+cast([yyear] as varchar(4))) as datetime) as yyyymmdd,
goal_amt as agoal
from cvo_territory_goal where cast ((cast([mmonth] as varchar(2))+'/01/'+cast([yyear] as varchar(4))) as datetime) between @start_ty and @asofdate

-- select * from cvo_territory_goal

--update #tsr set agoal = anet, anet = 0, qnet = 0, currentmonthsales = 0 where salesperson_name like '%Goal%'

--select * from #tsr

update #tsr set #tsr.salesperson_name = #terr.salesperson_name,
#tsr.region = #terr.region,
#tsr.date_of_hire = #terr.date_of_hire
from #tsr inner join
(SELECT   distinct a.territory_code, 
a.salesperson_code, slp.salesperson_name, slp.date_of_hire,
dbo.calculate_region_fn(a.territory_code) AS Region
FROM  armaster (nolock) a 
inner join arsalesp slp (nolock) on a.salesperson_code = slp.salesperson_code
where a.territory_code is not null
and a.salesperson_code <> 'smithma')
#terr on #terr.territory_code = #tsr.territory_code

--

update #tsr set anet_ty = anet where yyyymmdd between @start_ty and @asofdate
update #tsr set anet_ly = anet where yyyymmdd between @start_ly and @end_ly

--

select #tsr.*, mgr.mgr_name, mgr.mgr_date_of_hire from #tsr 
left outer join
(select dbo.calculate_region_fn(territory_code) region, salesperson_name mgr_name,
date_of_hire mgr_date_of_hire
from arsalesp where salesperson_type = 1 and territory_code is not null
union 
select '800','Corporate Accounts','1/1/1949')
mgr on #tsr.region = mgr.region



end
GO
GRANT EXECUTE ON  [dbo].[cvo_territory_sales_rolling12_sp] TO [public]
GO
