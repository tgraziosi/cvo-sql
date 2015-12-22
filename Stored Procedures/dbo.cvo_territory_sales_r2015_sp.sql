SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_territory_sales_r2015_sp] 
@CompareYear int = null ,
--v2
@territory varchar(1000) = null -- multi-valued parameter
as 
set nocount on
begin

declare @cy int, @terr varchar(1000), @today datetime
select @cy = @CompareYear, @terr = @territory, @today = getdate()

-- 032614 - tag - performance improvements - add multi-value param for territory
--  move setting the region to last.

--declare @compareyear int
--set @compareyear = 2013

-- exec cvo_territory_sales_r2015_sp 2015, '30302' '20201,40454' ,20202,20203,20204,20205,20206,20210,20215'
 -- exec cvo_territory_sales_r2_sp 2015, '40438'
-- select distinct territory_code from armaster

-- 082914 - performance
declare @sdate datetime, @edate datetime, @sdately datetime, @edately datetime

if @cy is null select @cy = year(@today)

set @sdately = dateadd(year, (@cy -1) - 1900 , '01-01-1900')
set @edately = Case 
		When @cy= YEAR(@today) Then
		DATEADD(dd, datediff(dd, 0,dateadd("yyyy",-1,@today)) + -1,0)
		Else
		dateadd(ms, -2, (dateadd(year, (@cy-1) - 1900 + 1 , '01-01-1900')))
		End
set @sdate = dateadd(year, (@cy) - 1900 , '01-01-1900')
set @edate = Case 
		When @cy= YEAR(@today)Then @today		Else
		dateadd(ms, -2, (dateadd(year, (@cy) - 1900 + 1 , '01-01-1900')))
		End

CREATE TABLE #territory ([territory] VARCHAR(10),
						 [region] VARCHAR(3))

if @terr is null
begin
	insert #territory
	select distinct territory_code, dbo.calculate_region_fn(territory_code) region
	FROM armaster where territory_code is not null
end
else
begin
	INSERT INTO #territory ([territory],[region])
	SELECT  LISTITEM , dbo.calculate_region_fn(listitem) region 
	FROM dbo.f_comma_list_to_table(@terr)
end

-- get workdays info
declare @workday int, @totalworkdays int, @pct_month float
select @workday = dbo.cvo_f_get_work_days (CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(@today)-1),@today),101),DateAdd(d,-1,@today)) 

select @totalworkdays =  dbo.cvo_f_get_work_days (CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(@today)-1),@today),101),CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(DATEADD(mm,1,@today))),DATEADD(mm,1,@today)),101))

select @pct_month = cast(@workday as float)/cast(@totalworkdays as float)

-- get TY and LY sales details
SELECT   
a.territory_code, 
isnull(c.x_month, month(@today)) as x_month,
isnull(c.year, year(@today) ) As Year,
isnull(c.month, datename(month,@today )) as month,
sum(isnull(c.anet,0)) anet, 
sum(isnull(case when i.type_code in ('frame','sun') then c.qnet end,0)) qnet,
cast(0.00 as float) as anet_mtd,
tot = case when isnull(i.category,'cv') = 'as' then 'as' else 'cv' end
into #temp 
FROM  #territory t 
inner join armaster (nolock) a on a.territory_code = t.territory
inner JOIN cvo_sbm_details c (nolock) 
	ON a.customer_code = c.customer AND a.ship_to_code = c.ship_to
inner join inv_master i (nolock) on i.part_no = c.part_no
where 1=1
-- and (yyyymmdd between @sdately and @edately) or (yyyymmdd between @sdate and @edate)
and (yyyymmdd between @sdately and @edate)
group by a.territory_code, c.x_month, c.year, c.month,
	case when isnull(i.category,'cv') = 'as' then 'as' else 'cv' end

-- fill in the blanks so that all buckets are covered
-- select * from #temp
-- ty
insert into #temp
SELECT   distinct a.territory_code, 
datepart(mm,@today ) As X_MONTH,
datepart(yy,@today ) As Year,
datename(month,@today ) as month,
0 anet, 
0 qnet,
0 as anet_mtd,
'cv' tot
FROM  armaster (nolock) a 
-- v2
inner join #territory terr on terr.territory = a.territory_code
where a.territory_code is not null
and a.salesperson_code <> 'smithma'

insert into #temp
SELECT   distinct a.territory_code, 
datepart(mm,@today ) As X_MONTH,
datepart(yy,@today ) As Year,
datename(month,@today ) as month,
0 anet, 
0 qnet,
0 as anet_mtd,
'as' tot
FROM  armaster (nolock) a 
-- v2
inner join #territory terr on terr.territory = a.territory_code
where a.territory_code is not null
and a.salesperson_code <> 'smithma'

insert into #temp
-- ly
SELECT   distinct a.territory_code,
month(@today) as X_MONTH,
@cy - 1 as year,
datename(month, @today) month,
0 anet, 
0 qnet,
0 as anet_mtd,
'cv' as tot
FROM  armaster (nolock) a 
inner join #territory terr on terr.territory = a.territory_code
where a.territory_code is not null
and a.salesperson_code <> 'smithma'

--insert into #temp
--SELECT   distinct a.territory_code,
--month(@today) as X_MONTH,
--@cy - 1 as year,
--datename(month, @today) month,
--0 anet, 
--0 qnet,
--0 as anet_mtd,
--'as' as tot
--FROM  armaster (nolock) a 
--inner join #territory terr on terr.territory = a.territory_code
--where a.territory_code is not null
--and a.salesperson_code <> 'smithma'

-- get current month sales mtd from lastyear

SELECT a.territory_code,
s.year,
s.X_MONTH,
Sum(s.anet) AS CurrentMonthSales,
tot = case when isnull(i.category,'cv') = 'as' then 'as' else 'cv' end
 into #MonthKey 
 FROM   #territory t 
 inner join armaster a (nolock) on a.territory_code = t.territory
 inner join cvo_sbm_details s (nolock) on s.customer = a.customer_code and s.ship_to = a.ship_to_code
 inner join inv_master i (nolock) on i.part_no = s.part_no
 where 1=1 
 -- and s.x_month = month(@today) and s.year = @cy - 1 and day(s.yyyymmdd) <= day(@today)
 and s.yyyymmdd between dateadd(m,datediff(mm,0,@edately),0) and @edately
 group by a.territory_code, year, x_month,
	case when isnull(i.category,'cv') = 'as' then 'as' else 'cv' end
 
SELECT  a.territory_code, 
a.X_MONTH,
a.year,
a.month,
sum(a.anet) anet, 
case when a.tot = 'as' then sum(a.qnet) else 0 end as qnet,
sum(a.anet_mtd) anet_mtd,
max(isnull(m.CurrentMonthSales,0)) currentmonthsales,
a.tot
into #ly
FROM  #temp a
left join #MonthKey m
ON a.territory_code = m.territory_code AND a.year = m.year AND a.X_MONTH = m.X_MONTH
Where a.year = @cy-1
group by a.territory_code, a.x_month, a.year, a.month, a.tot

-- get this year figures

SELECT  
a.territory_code, 
a.X_MONTH,
a.year,
a.month,
sum(a.anet) anet, 
case when a.tot = 'as' then sum(a.qnet) else 0 end as qnet,
sum(a.anet_mtd) anet_mtd,
0 as currentmonthsales,
a.tot
into #ty FROM  #temp a
Where a.year = @cy
group by a.territory_code, a.x_month, a.year, a.month, a.tot

-- fixup sales person names

select t.territory territory_code
, salesperson_code = isnull((select top 1 salesperson_name from arsalesp
	where salesperson_code <> 'smithma' 
	and territory_code = t.territory 
	and isnull(date_of_hire,'1/1/1900') <= @today
	and status_type = 1)
	, 'Empty')
-- , dbo.calculate_region_fn(t.territory) as region
, t.region
into #s1 
from #territory t

-- select * From #territory order by territory
-- select * from #s1 where territory_code in (30398,30399) order by territory_code 
-- select * From arsalesp where territory_code = 30398

select 
#ty.territory_code, 
#s1.salesperson_code,
X_MONTH,
year,
month,
round (anet,2) anet , 
qnet,
round (anet_mtd,2) anet_mtd,
round (currentmonthsales,2) currentmonthsales,
tot,
#s1.region
, case when x_month > 9 then 4
			   when x_month > 6 then 3
			   when x_month > 3 then 2
			   else 1
			end as Q
  From #ty -- ty
  left outer join #s1 on #s1.territory_code = #ty.territory_code
Union ALL
 select 
#ly.territory_code, 
#s1.salesperson_code,
X_MONTH,
year,
month,
round (anet,2) anet , 
qnet,
round (anet_mtd,2) anet_mtd,
round (currentmonthsales,2) currentmonthsales,
tot,
#s1.region
, case when x_month > 9 then 4
			   when x_month > 6 then 3
			   when x_month > 3 then 2
			   else 1
			end as Q
from #ly -- ly
left outer join #s1 on #s1.territory_code = #ly.territory_code
where #ly.tot = 'cv'

union all -- get goals

select
g.territory_code, '    Goal' as salesperson_code, mmonth 
, @cy as yyear, 
datename(month,cast ((cast([mmonth] as varchar(2))+'/01/'+cast([yyear] as varchar(4))) as datetime)) as month, 
goal_amt as anet, 
0 as qnet,  
case when mmonth = month(@today) then round(isnull(goal_amt,0) * @pct_month,2)  else 0 end as anet_mtd,
0 as currentmonthsales, 
'cv' tot,
-- dbo.calculate_region_fn(g.territory_code) as region,
terr.region, 
case when mmonth > 9 then 4
		   when mmonth > 6 then 3
		   when mmonth > 3 then 2
		   else 1
		end as Q
from #territory terr 
left outer join cvo_territory_goal g on terr.territory = g.territory_code
Where 1=1 
and (yyear = @cy or yyear = 9999)
union all
	SELECT   distinct a.territory_code, 
	'    Goal' as salesperson_code,
	mm.mmonth,
	@cy As Year,
	mm.mm_name as month,
	0 anet, 
	0 qnet,
	0 anet_mtd,
	0 as currentmonthsales, 
	'cv' tot,
	dbo.calculate_region_fn(a.territory_code) as region,
	case when mm.mmonth > 9 then 4
		   when mm.mmonth > 6 then 3
		   when mm.mmonth > 3 then 2
		   else 1
		end as Q

	FROM  #territory terr 
	inner join armaster (nolock) a on terr.territory = a.territory_code
	cross join 
	 ( 	select distinct @cy yyear, mmonth, datename(month, str(mmonth) + '/1/2015') mm_name
		from cvo_territory_goal where yyear = @cy - 1
	 ) mm
	where a.salesperson_code <> 'smithma'   
	

end

GO
