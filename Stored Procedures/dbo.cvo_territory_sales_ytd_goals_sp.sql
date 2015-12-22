SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_territory_sales_ytd_goals_sp] 
@CompareYear int = null
--,@CompareMonth varchar(100)
, @territory varchar(1000) = null

as 
begin

-- exec cvo_territory_sales_ytd_goals_sp '2015', '20201'

-- declare @compareyear int
-- set @compareyear = 2013
if @compareyear is null select @compareyear = datepart("yyyy",getdate())

CREATE TABLE #Terr ([terr] VARCHAR(8))

if @territory is null
begin 
	insert into #terr (terr)
	select distinct territory_code from armaster
end
else
begin
	INSERT INTO #terr ([terr])
	SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@territory)
end

declare @ty int, @ly int
select  @ty = @compareyear, @ly = @compareyear - 1

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
dbo.calculate_region_fn(a.territory_code) Region,
-- 3/11/2013
cast(0.00 as float) as anet_mtd
, cast((case when i.category <> 'AS' then 'TOT' else i.category end) as varchar(3)) as tot
into #temp 
FROM #terr t
inner join armaster (nolock) a on a.territory_code = t.terr
inner JOIN cvo_sbm_details c (nolock) 
	ON a.customer_code = c.customer AND a.ship_to_code = c.ship_to
inner join inv_master i (nolock) on i.part_no = c.part_no
and c.year >= @ly

-- fill in the blanks so that all buckets are covered

-- ty
insert into #temp
SELECT   distinct a.territory_code, 
a.salesperson_code,
datepart(mm,getdate() ) As X_MONTH,
datepart(yy,getdate() ) As Year,
datename(month,getdate() ) as month,
DateAdd("yyyy",0,DATEADD(dd, datediff(dd, 0,GetDate()) + -1,0))  as yyyymmdd, 
0 anet, 
0 qnet,dbo.calculate_region_fn(a.territory_code) AS Region
, 0 as anet_mtd
,'TOT' as tot
FROM  #terr t 
inner join armaster (nolock) a on a.territory_code = t.terr
where a.salesperson_code <> 'smithma'

-- union all

-- ly
insert into #temp
SELECT   distinct a.territory_code, a.salesperson_code,
datepart(mm,DateAdd("yyyy",-1,DATEADD(dd, datediff(dd, 0,GetDate()) + -1,0)) ) As X_MONTH,
datepart(yy,DateAdd("yyyy",-1,DATEADD(dd, datediff(dd, 0,GetDate()) + -1,0)) ) As year,
datename(month,DateAdd("yyyy",-1,DATEADD(dd, datediff(dd, 0,GetDate()) + -1,0)) ) as month,
DateAdd("yyyy",-1,DATEADD(dd, datediff(dd, 0,GetDate()) + -1,0))  as yyyymmdd, 
0 anet, 
0 qnet,
dbo.calculate_region_fn(a.territory_code) AS Region
, 0 as anet_mtd
, 'TOT' as tot
FROM  #terr t 
inner join armaster (nolock) a on t.terr = a.territory_code
where a.salesperson_code <> 'smithma'


SELECT territory_code,
DatePart(yy,yyyymmdd) As year,
DatePart(mm,yyyymmdd) As X_MONTH,
Sum(anet) AS CurrentMonthSales
 into #MonthKey FROM  #temp 
 where #temp.tot = 'tot' -- dont include AS sales here
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
,Row_Number() over(partition by a.territory_code,DatePart(yy,a.yyyymmdd),DatePart(mm,a.yyyymmdd) order by a.territory_code,DatePart(yy,a.yyyymmdd),DatePart(mm,a.yyyymmdd) ) AS Rank
, a.tot
into #t1 FROM  #temp a
left join #MonthKey m
ON a.territory_code = m.territory_code AND a.year = m.year AND a.X_MONTH = m.X_MONTH

Where a.year = (@CompareYear-1)     
-- AND a.X_Month IN(@CompareMonth)
and a.tot = 'tot'
AND a.yyyymmdd Between 

dateadd(year, (@CompareYear -1) - 1900 , '01-01-1900')
AND
Case 
When @CompareYear= YEAR(Getdate())Then
-- tag - fix date math to get the right last year date when it is the first of the month
-- DateAdd("yyyy",-1,DATEADD(dd, datediff(dd, 0,GetDate()) + -1,0))
DATEADD(dd, datediff(dd, 0,dateadd("yyyy",-1,GetDate())) + -1,0)
Else
dateadd(ms, -2, (dateadd(year, (@CompareYear-1) - 1900 + 1 , '01-01-1900')))
End

Update #t1 
SET CurrentMonthSales = 0
Where Rank <> 1 

-- get last year figures

SELECT  a.territory_code, 
a.salesperson_code,DatePart(mm,a.yyyymmdd) As X_MONTH,
DatePart(yy,a.yyyymmdd) As year,a.month,a.yyyymmdd, 
a.anet, 
a.qnet,
a.Region,
a.anet_mtd,
NULL as currentmonthsales,
NULL as rank
, a.tot
into #t2 FROM  #temp a
Where a.year = (@CompareYear)     
-- AND a.X_Month IN(@CompareMonth)
AND a.yyyymmdd Between dateadd(year, (@CompareYear) - 1900 , '01-01-1900')
AND Case 
	When @CompareYear = YEAR(Getdate())Then Getdate()
	Else dateadd(ms, -2, (dateadd(year, (@CompareYear) - 1900 + 1 , '01-01-1900')))
	End

-- fixup sales person names

select distinct territory_code, salesperson_code 
into #s1 from arsalesp (nolock) where status_type = 1
and salesperson_code <> 'smithma' and isnull(date_of_hire,'1/1/1900') <= getdate()

--select * from #s1 order by territory_code

update #t1 set #t1.salesperson_code = #s1.salesperson_code
from #t1, #s1
where #t1.territory_code = #s1.territory_code
and #t1.salesperson_code <> #s1.salesperson_code

update #t2 set #t2.salesperson_code = #s1.salesperson_code
from #t1, #s1
where #t2.territory_code = #s1.territory_code
and #t2.salesperson_code <> #s1.salesperson_code

select territory_code, sum(goal_amt) ygoal 
into #yg
from cvo_territory_goal where yyear in (@CompareYear)
group by territory_code

select * From #t1 -- ty
Union ALL
select * from #t2 -- ly
union all -- get goals
select territory_code, '    Goal' as salesperson_code, mmonth , yyear, 
datename(month,cast ((cast([mmonth] as varchar(2))+'/01/'+cast([yyear] as varchar(4))) as datetime)) as month, 
cast ((cast([mmonth] as varchar(2))+'/01/'+cast([yyear] as varchar(4))) as datetime) as yyyymmdd 
, goal_amt as anet, 0 as qnet, dbo.calculate_region_fn(territory_code) AS Region, 
case when mmonth = month(getdate()) then round(isnull(goal_amt,0) * @pct_month,2)  else 0 end as anet_mtd,
null, null
, 'tot' as tot
from cvo_territory_goal Where yyear IN (@CompareYear)   
  
union all

select tu.territory_code, ' GoalPct' as salesperson_code, mmonth, yyear,
datename(month,cast ((cast([mmonth] as varchar(2))+'/01/'+cast([yyear] as varchar(4))) as datetime)) as month, 
cast ((cast([mmonth] as varchar(2))+'/01/'+cast([yyear] as varchar(4))) as datetime) as yyyymmdd,
case when isnull(#yg.ygoal,0) <> 0 then goal_amt/#yg.ygoal else 0 end as anet, 
0 as qnet, dbo.calculate_region_fn(tu.territory_code) AS Region, 
case when mmonth = month(getdate()) then 
	case when isnull(#yg.ygoal,0) <> 0 then round(isnull(goal_amt,0) * @pct_month,2)/#yg.ygoal else 0 end end as anet_mtd,
null, null
, 'tot'
from cvo_territory_goal tu inner join #yg on tu.territory_code = #yg.territory_code Where yyear IN (@CompareYear)  

end
GO
GRANT EXECUTE ON  [dbo].[cvo_territory_sales_ytd_goals_sp] TO [public]
GO
