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
--set @compareyear = '2018'

IF(OBJECT_ID('tempdb.dbo.#tsr') is not null)  drop table #tsr

CREATE TABLE #tsr
(territory_code	varchar(8),
salesperson_name varchar(40),
date_of_hire datetime,
X_MONTH	int,
yyear	int,
mmonth	varchar(15),
yyyymmdd	datetime,
anet	decimal(20,8),
qnet	decimal(20,8),
Region	varchar(3),
anet_mtd	decimal(20,8),
CurrentMonthSales	decimal(20,8),
agoal decimal(20,8) default 0,
anet_ty decimal(20,8) default 0,
anet_ly decimal(20,8) default 0,
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
from dbo.arsalesp slp where slp.salesperson_code = #tsr.salesperson_name

update #tsr set anet_ty = anet where yyear = @compareyear
update #tsr set anet_ly = anet where yyear < @compareyear


INSERT #tsr
(
    territory_code,
    salesperson_name,
    date_of_hire,
    X_MONTH,
    yyear,
    mmonth,
    yyyymmdd,

    Region,

    agoal

)
SELECT ar.territory_code, frame.slp_name, frame.date_of_hire, frame.X_MONTH, frame.yyear, frame.mmonth, frame.yyyymmdd, frame.region, SUM(anet) lynetsales 
FROM cvo_sbm_details s
JOIN armaster ar (NOLOCK) ON ar.customer_code = s.customer AND ar.ship_to_code = s.ship_to
JOIN 
(
SELECT DISTINCT territory_code,'     Goal' slp_name, date_of_hire, X_MONTH, yyear, mmonth, yyyymmdd, region
FROM #tsr y
WHERE yyyymmdd = (SELECT MAX(yyyymmdd) FROM #tsr x WHERE x.territory_code = y.territory_code)
) frame ON frame.territory_code = ar.territory_code
WHERE s.c_year = @compareyear - 1
GROUP BY ar.territory_code,
         frame.slp_name,
         frame.date_of_hire,
         frame.X_MONTH,
         frame.yyear,
         frame.mmonth,
         frame.yyyymmdd,
         frame.Region



select #tsr.territory_code,
       #tsr.salesperson_name,
       #tsr.date_of_hire,
       #tsr.X_MONTH,
       #tsr.yyear,
       #tsr.mmonth,
       #tsr.yyyymmdd,
       #tsr.anet,
       #tsr.qnet,
       #tsr.Region,
       #tsr.anet_mtd,
       #tsr.CurrentMonthSales,
       #tsr.agoal,
       #tsr.anet_ty,
       #tsr.anet_ly,
       #tsr.rRank, mgr.mgr_name, mgr.mgr_date_of_hire from #tsr 
left outer join
(select dbo.calculate_region_fn(territory_code) region, salesperson_name mgr_name,
date_of_hire mgr_date_of_hire
from dbo.arsalesp where salesperson_type = 1 and territory_code is not NULL AND status_type = 1 -- add status check for active
union 
select '800','Corporate Accounts','1/1/1949')
mgr on #tsr.region = mgr.region

-- set the goal to be LY total sales



end


GO
GRANT EXECUTE ON  [dbo].[cvo_territory_sales_mtd_ytd_sp] TO [public]
GO
