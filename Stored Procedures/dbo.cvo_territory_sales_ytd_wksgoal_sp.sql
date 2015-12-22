SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_territory_sales_ytd_wksgoal_sp] @asofdate datetime
as
begin

-- exec cvo_territory_sales_ytd_wksgoal_sp '10/26/2014'

--declare @asofdate datetime
--set @asofdate = '10/31/2014'


declare @sdate datetime, @edate datetime, @ly_edate datetime, @compareyear int, @wtg int
set @sdate = dateadd(yy,datediff(yy,0,@asofdate), 0)
select @edate = @asofdate

select @compareyear = datepart(year, @asofdate)
select @ly_edate = dateadd(yy,-1, @edate)
select @wtg = 52 - datediff(ww, @sdate, @edate)

-- figure out current month days worked

declare @mtd decimal(20,8), @month decimal(20,8), @pctmth decimal (20,8)

Select @mtd = dbo.cvo_f_get_work_days ( DATEADD(dd,-(DAY(@asofdate)-1),@asofdate), @asofdate )
select @month = dbo.cvo_f_get_work_days ( DATEADD(dd,-(DAY(@asofdate)-1),@asofdate),
										  DATEADD(dd,-(DAY(DATEADD(mm,1,@asofdate))),DATEADD(mm,1,@asofdate)) )
select @pctmth = case when @month = 0 then 0 else @mtd/@month end

-- select @mtd, @month, @pctmth

IF(OBJECT_ID('tempdb.dbo.#tsr') is not null)  drop table #tsr

CREATE TABLE #tsr
(territory_code	varchar(8),
salesperson_name varchar(40),
date_of_hire datetime,
slp_email varchar(255),
wks_worked int,
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

-- delete from #tsr where yyear <> @compareyear -- dont need LY figures for this version
-- delete from #tsr where yyyymmdd < dateadd(yy,-1, @edate)


update #tsr set agoal = anet, anet = 0, qnet = 0, currentmonthsales = 0 where salesperson_name like '%Goal%'

update #tsr set #tsr.salesperson_name = #terr.salesperson_name
from #tsr inner join
(select distinct #tsr.territory_code, #tsr.salesperson_name
from #tsr where #tsr.salesperson_name not like '%Goal%')
#terr on #terr.territory_code = #tsr.territory_code

update #tsr set #tsr.salesperson_name = slp.salesperson_name,
#tsr.date_of_hire = isnull (slp.date_of_hire, '1/1/1949'),
#tsr.slp_email = isnull(slp.addr_sort2,'')
from arsalesp slp where slp.salesperson_code = #tsr.salesperson_name

update #tsr set anet_ty = anet where yyear = @compareyear
-- update #tsr set anet_ly = anet where yyear < @compareyear

-- get LY YTD Net Sales
IF(OBJECT_ID('tempdb.dbo.#tsr_ly_ytg') is not null)  drop table #tsr_ly_ytg

select territory_code, sum(isnull(sbm.anet,0)) ly_ytg_net 
into #tsr_ly_ytg
from armaster ar  
	join cvo_sbm_details sbm on sbm.customer = ar.customer_code and sbm.ship_to = ar.ship_to_code
	where yyyymmdd > @ly_edate and year = @compareyear - 1
	group by territory_code

-- figure out weeks worked ytd

/*
update #tsr set wks_worked = 
case when date_of_hire < @sdate
then datediff(ww, @sdate, @edate )
else datediff(ww, date_of_hire, @edate) 
end
from #tsr
*/

update #tsr set wks_worked = datediff( ww, @sdate, @edate ) 
from #tsr

-- summarize

IF(OBJECT_ID('tempdb.dbo.#tsr_wksworked') is not null)  drop table #tsr_wksworked

select region, territory_code, salesperson_name, date_of_hire, 
slp_email, 
isnull(ty.wks_worked,0) wks_worked, 
sum(case when ty.yyyymmdd <= @edate then isnull(anet,0) else 0 end) anet,
-- sum(isnull(ty.anet,0)) anet, 
sum(isnull(ty.agoal,0)) agoal,
agoal_ytd = sum(case when ty.x_month < datepart(mm,@edate) then isnull(agoal,0) else 0 end)
			+sum(case when ty.x_month = datepart(mm,@edate) then isnull(agoal,0)*@pctmth else 0 end),
AGOAL_MTH = +sum(case when ty.x_month = datepart(mm,@edate) then isnull(agoal,0) else 0 end),
agoal_mtd = sum(case when ty.x_month = datepart(mm,@edate) then isnull(agoal,0)*@pctmth else 0 end),
agoal_attained = sum(isnull(ty.agoal,0)) 
	- sum(case when ty.x_month < datepart(mm,@edate) then isnull(agoal,0) else 0 end) 
	- sum(case when ty.x_month = datepart(mm,@edate) then isnull(agoal,0)*@pctmth else 0 end),
Goal_pct = case when sum(isnull(ty.agoal,0)) = 0 then 0 else 
	(sum(case when ty.x_month < datepart(mm,@edate) then isnull(ty.agoal,0) else 0 end)
	  + sum(case when ty.x_month = datepart(mm,@edate) then isnull(ty.agoal,0)*@pctmth else 0 end) )
	  / sum(isnull(ty.agoal,0))  end,
goal_Togo = sum(isnull(ty.agoal,0)) - sum(case when ty.yyyymmdd <= @edate then isnull(anet,0) else 0 end) , 
weekly_anet_ytd = sum(case when ty.yyyymmdd <= @edate then isnull(anet,0) else 0 end)/(case when (ty.wks_worked = 0 or ty.wks_worked = null) then 1 else ty.wks_worked end) , 
weekly_anet_togo = (( sum(isnull(ty.agoal,0)) - sum(case when ty.yyyymmdd <= @edate then isnull(anet,0) else 0 end) ) / @wtg )
					,
weekly_anet_ly_ytg =  (select top 1 ly_ytg_net from #tsr_ly_ytg ly 
					   where ly.territory_code = ty.territory_code )
					  / @wtg ,
anet_ly = (select top 1 ly_ytg_net from #tsr_ly_ytg ly where ly.territory_code = ty.territory_code),
datediff(ww, @sdate, @edate) weeks, @wtg  weeks_togo,
@sdate sdate,
@edate edate,
@mtd WorkDay,
@month TotalWorkDays,
@pctmth pctmth

into #tsr_wksworked
from #tsr ty
where yyear = @compareyear 
group by region, territory_code, salesperson_name, date_of_hire, slp_email, wks_worked, TY.YYEAR


select #tsr_wksworked.*, mgr.mgr_name, mgr.mgr_date_of_hire,mgr.mgr_email from #tsr_wksworked 
left outer join
(select dbo.calculate_region_fn(territory_code) region, salesperson_name mgr_name,
date_of_hire mgr_date_of_hire, isnull(addr_sort2,'') mgr_email
from arsalesp where salesperson_type = 1 and territory_code is not null and salesperson_name is not null
and isnull(addr_sort2,'') > ''
union 
select '800','Corporate Accounts','1/1/1949','')
mgr on #tsr_wksworked.region = mgr.region

-- select #tsr.* from #tsr where wks_worked < 30

end

GO
GRANT EXECUTE ON  [dbo].[cvo_territory_sales_ytd_wksgoal_sp] TO [public]
GO
