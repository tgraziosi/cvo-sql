SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_territory_sales_r2_sp] 
@CompareYear int,
--v2
@territory varchar(1000) -- multi-valued parameter
as 
set nocount on
begin

-- 032614 - tag - performance improvements - add multi-value param for territory
--  move setting the region to last.

--declare @compareyear int
--set @compareyear = 2013

-- exec cvo_territory_sales_r2_sp 2014, '20201,20202,20203,20204,20205,20206,20210,20215'

-- select distinct territory_code from armaster

-- 082914 - performance
declare @sdate datetime, @edate datetime, @sdately datetime, @edately datetime

set @sdately = dateadd(year, (@CompareYear -1) - 1900 , '01-01-1900')
set @edately = Case 
		When @CompareYear= YEAR(Getdate())Then
		DATEADD(dd, datediff(dd, 0,dateadd("yyyy",-1,GetDate())) + -1,0)
		Else
		dateadd(ms, -2, (dateadd(year, (@CompareYear-1) - 1900 + 1 , '01-01-1900')))
		End
set @sdate = dateadd(year, (@CompareYear) - 1900 , '01-01-1900')
set @edate = Case 
		When @CompareYear= YEAR(Getdate())Then
		getdate()
		Else
		dateadd(ms, -2, (dateadd(year, (@CompareYear) - 1900 + 1 , '01-01-1900')))
		End

CREATE TABLE #territory ([territory] VARCHAR(10))
INSERT INTO #territory ([territory])
SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@territory)

-- get workdays info
declare @workday int, @totalworkdays int, @pct_month float
select @workday = dbo.cvo_f_get_work_days (CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(GETDATE())-1),GETDATE()),101),DateAdd(d,-1,GETDATE())) 


select @totalworkdays =  dbo.cvo_f_get_work_days (CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(GETDATE())-1),GETDATE()),101),CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(DATEADD(mm,1,GETDATE()))),DATEADD(mm,1,GETDATE())),101))

select @pct_month = cast(@workday as float)/cast(@totalworkdays as float)

SELECT   a.territory_code, 
a.salesperson_code ,
datepart(mm,isnull(c.yyyymmdd,getdate() )) As X_MONTH,
datepart(yy,isnull(c.yyyymmdd,getdate() )) As Year,
isnull(c.month, datename(month,getdate() )) as month,
isnull(c.yyyymmdd,
DateAdd("yyyy",0,DATEADD(dd, datediff(dd, 0,GetDate()) + -1,0)) ) as yyyymmdd, 
isnull(c.anet,0) anet, 
isnull(c.qnet,0) qnet,
space(3) as Region,
-- 3/11/2013
cast(0.00 as float) as anet_mtd
into #temp 
FROM  armaster (nolock) a 
	inner JOIN cvo_sbm_details c (nolock) 
	ON a.customer_code = c.customer AND a.ship_to_code = c.ship_to

--v2
inner join #territory terr on terr.territory = a.territory_code
-- tag 082914 - dont get all sales, just compare year and prior year
-- where yyyymmdd > = @sdately

-- fill in the blanks so that all buckets are covered

insert into #temp
SELECT   distinct a.territory_code, 
a.salesperson_code,
datepart(mm,getdate() ) As X_MONTH,
datepart(yy,getdate() ) As Year,
datename(month,getdate() ) as month,
DateAdd("yyyy",0,DATEADD(dd, datediff(dd, 0,GetDate()) + -1,0))  as yyyymmdd, 
0 anet, 
0 qnet,
space(3) as region
-- dbo.calculate_region_fn(a.territory_code) AS Region
, 0 as anet_mtd
FROM  armaster (nolock) a 
-- v2
inner join #territory terr on terr.territory = a.territory_code
where a.territory_code is not null
and a.salesperson_code <> 'smithma'

union all

SELECT   distinct a.territory_code, a.salesperson_code,
datepart(mm,DateAdd("yyyy",-1,DATEADD(dd, datediff(dd, 0,GetDate()) + -1,0)) ) As X_MONTH,
datepart(yy,DateAdd("yyyy",-1,DATEADD(dd, datediff(dd, 0,GetDate()) + -1,0)) ) As year,
datename(month,DateAdd("yyyy",-1,DATEADD(dd, datediff(dd, 0,GetDate()) + -1,0)) ) as month,
DateAdd("yyyy",-1,DATEADD(dd, datediff(dd, 0,GetDate()) + -1,0))  as yyyymmdd, 
0 anet, 
0 qnet,
space(3) as region
-- dbo.calculate_region_fn(a.territory_code) AS Region
, 0 as anet_mtd

FROM  armaster (nolock) a 
inner join #territory terr on terr.territory = a.territory_code
where a.territory_code is not null
and a.salesperson_code <> 'smithma'

-- get last years figures

SELECT territory_code,
DatePart(yy,yyyymmdd) As year,
DatePart(mm,yyyymmdd) As X_MONTH,
Sum(anet) AS CurrentMonthSales
 into #MonthKey FROM  #temp 
 group by territory_code,DatePart(yy,yyyymmdd),DatePart(mm,yyyymmdd)
 
SELECT  a.territory_code, 
a.salesperson_code,
DatePart(mm,a.yyyymmdd) As X_MONTH,
DatePart(yy,a.yyyymmdd) As year,a.month,
a.yyyymmdd, 
a.anet, 
a.qnet,
a.Region,
a.anet_mtd,
m.CurrentMonthSales
,Row_Number() over(partition by a.territory_code,DatePart(yy,a.yyyymmdd),DatePart(mm,a.yyyymmdd) 
order by a.territory_code,DatePart(yy,a.yyyymmdd),DatePart(mm,a.yyyymmdd) ) AS Rank
into #ly
FROM  #temp a
left join #MonthKey m
ON a.territory_code = m.territory_code AND a.year = m.year AND a.X_MONTH = m.X_MONTH

Where a.year = @CompareYear-1
-- AND a.X_Month IN(@CompareMonth)
AND a.yyyymmdd Between 
@sdately
-- select dateadd(year, (@CompareYear -1) - 1900 , '01-01-1900')
AND
@edately
--Case 
--When @CompareYear= YEAR(Getdate())Then
---- tag - fix date math to get the right last year date when it is the first of the month
---- DateAdd("yyyy",-1,DATEADD(dd, datediff(dd, 0,GetDate()) + -1,0))
-- select DATEADD(dd, datediff(dd, 0,dateadd("yyyy",-1,GetDate())) + -1,0)
--Else
--dateadd(ms, -2, (dateadd(year, (@CompareYear-1) - 1900 + 1 , '01-01-1900')))
--End

Update #ly 
SET CurrentMonthSales = 0
Where Rank <> 1 

-- get this year figures

SELECT  a.territory_code, 
a.salesperson_code,DatePart(mm,a.yyyymmdd) As X_MONTH,
DatePart(yy,a.yyyymmdd) As year,a.month,a.yyyymmdd, 
a.anet, 
a.qnet,
a.Region,
a.anet_mtd,
NULL as currentmonthsales,
NULL as rank
into #ty FROM  #temp a
Where a.year = @CompareYear
AND a.yyyymmdd Between 
@sdate
-- dateadd(year, (@CompareYear) - 1900 , '01-01-1900')
AND
@edate
-- Case 
--When @CompareYear = YEAR(Getdate())Then
--Getdate()
--Else
--dateadd(ms, -2, (dateadd(year, (@CompareYear) - 1900 + 1 , '01-01-1900')))
--End

-- fixup sales person names

select distinct territory_code, salesperson_code 
into #s1 from arsalesp (nolock) where status_type = 1
and salesperson_code <> 'smithma' and isnull(date_of_hire,'1/1/1900') <= getdate()

--select * from #s1 order by territory_code

update #ty set #ty.region = dbo.calculate_region_fn(#ty.territory_code)
update #ly set #ly.region = dbo.calculate_region_fn(#ly.territory_code)

update #ty set #ty.salesperson_code = #s1.salesperson_code,
        #ty.region = dbo.calculate_region_fn(#s1.territory_code)
from #ty, #s1
where #ty.territory_code = #s1.territory_code
and #ty.salesperson_code <> #s1.salesperson_code

update #ly set #ly.salesperson_code = #s1.salesperson_code,
        #ly.region = dbo.calculate_region_fn(#s1.territory_code)
from #ly, #s1
where #ly.territory_code = #s1.territory_code
and #ly.salesperson_code <> #s1.salesperson_code

--select g.territory_code, sum(goal_amt) ygoal,
--        dbo.calculate_region_fn(g.territory_code) as region
--into #yg
--from cvo_territory_goal g
--inner join #territory terr on terr.territory = g.territory_code
--where yyear in (@CompareYear)
--group by territory_code


select *, case when x_month > 9 then 4
			   when x_month > 6 then 3
			   when x_month > 3 then 2
			   else 1
			end as Q
--select *, case when x_month in (1,2,3) then 1
--				when x_month in (4,5,6) then 2
--				when x_month in (7,8,9) then 3
--				else 4 
--		  end as Q 
		  From #ty -- ty
Union ALL
select *, case when x_month > 9 then 4
			   when x_month > 6 then 3
			   when x_month > 3 then 2
			   else 1
			end as Q
--select *, case when x_month in (1,2,3) then 1
--				when x_month in (4,5,6) then 2
--				when x_month in (7,8,9) then 3
--				else 4 
--		  end as Q 
		  from #ly -- ly
union all -- get goals
select g.territory_code, '    Goal' as salesperson_code, mmonth , yyear, 
datename(month,cast ((cast([mmonth] as varchar(2))+'/01/'+cast([yyear] as varchar(4))) as datetime)) as month, 
cast ((cast([mmonth] as varchar(2))+'/01/'+cast([yyear] as varchar(4))) as datetime) as yyyymmdd 
, goal_amt as anet, 0 as qnet,  
dbo.calculate_region_fn(g.territory_code) as region,
case when mmonth = month(getdate()) then round(isnull(goal_amt,0) * @pct_month,2)  else 0 end as anet_mtd,
null, null, 
--case when mmonth in (1,2,3) then 1
--				when mmonth in (4,5,6) then 2
--				when mmonth in (7,8,9) then 3
--				else 4 
--		  end as Q 
case when mmonth > 9 then 4
		   when mmonth > 6 then 3
		   when mmonth > 3 then 2
		   else 1
		end as Q
from cvo_territory_goal g 
inner join #territory terr on terr.territory = g.territory_code
Where yyear = @CompareYear     
--union all
--select tu.territory_code, ' GoalPct' as salesperson_code, mmonth, yyear,
--datename(month,cast ((cast([mmonth] as varchar(2))+'/01/'+cast([yyear] as varchar(4))) as datetime)) as month, 
--cast ((cast([mmonth] as varchar(2))+'/01/'+cast([yyear] as varchar(4))) as datetime) as yyyymmdd,
--case when isnull(#yg.ygoal,0) <> 0 then goal_amt/#yg.ygoal else 0 end as anet, 
--0 as qnet, dbo.calculate_region_fn(tu.territory_code) AS Region, 
--case when mmonth = month(getdate()) then 
--	case when isnull(#yg.ygoal,0) <> 0 then round(isnull(goal_amt,0) * @pct_month,2)/#yg.ygoal else 0 end end as anet_mtd,
--null, null
--from cvo_territory_goal tu inner join #yg on tu.territory_code = #yg.territory_code Where yyear IN (@CompareYear)  

end

GO
GRANT EXECUTE ON  [dbo].[cvo_territory_sales_r2_sp] TO [public]
GO
