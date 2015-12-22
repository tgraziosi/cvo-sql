SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_territory_sales_mtd_ytd_sp]
@CompareYear varchar(1000)
as
begin

-- exec cvo_territory_sales_mtd_ytd_sp '2013'

--declare @compareyear varchar(1000)
--set @compareyear = '2013'

IF(OBJECT_ID('tempdb.dbo.#tsr') is not null)  drop table #tsr

CREATE TABLE #tsr
(territory_code	varchar(8),
salesperson_name varchar(40),
date_of_hire datetime,
X_MONTH	int,
yyear	int,
mmonth	varchar(15),
yyyymmdd	datetime,
anet	float,
qnet	float,
Region	varchar(3),
anet_mtd	float,
CurrentMonthSales	float,
agoal float default 0,
anet_ty float default 0,
anet_ly float default 0,
rRank	bigint)

insert into #tsr 
(territory_code,
salesperson_name,
x_month,
yyear,
mmonth,
yyyymmdd, anet, qnet, region, anet_mtd, 
currentmonthsales, rrank) 
exec cvo_territory_sales_sp @CompareYear

update #tsr set agoal = anet, anet = 0, qnet = 0, currentmonthsales = 0 where salesperson_name like '%Goal%'

update #tsr set #tsr.salesperson_name = #terr.salesperson_name
from #tsr inner join
(select distinct #tsr.territory_code, #tsr.salesperson_name
from #tsr where #tsr.salesperson_name not like '%Goal%')
#terr on #terr.territory_code = #tsr.territory_code

update #tsr set #tsr.salesperson_name = slp.salesperson_name,
#tsr.date_of_hire = slp.date_of_hire
from arsalesp slp where slp.salesperson_code = #tsr.salesperson_name

update #tsr set anet_ty = anet where yyear = @compareyear
update #tsr set anet_ly = anet where yyear < @compareyear

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
GRANT EXECUTE ON  [dbo].[cvo_territory_sales_mtd_ytd_sp] TO [public]
GO
