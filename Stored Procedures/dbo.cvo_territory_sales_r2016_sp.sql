SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_territory_sales_r2016_sp] 
@CompareYear int = null ,
--v2
@territory varchar(1000) = null -- multi-valued parameter

,@restype VARCHAR(1000) = NULL

as 
set nocount on
BEGIN

-- exec cvo_territory_sales_r2016_sp 2017 , 50508

--DECLARE @compareyear INT, @territory VARCHAR(1000)
--SELECT @compareyear = 2015, @territory = '20201'


declare @cy int, @terr varchar(1000), @today DATETIME, @typecode VARCHAR(1000)
select @cy = @CompareYear, @terr = @territory, @today = getdate(), @typecode = @restype

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

-- SELECT @sdately, @edately, @sdate, @edate


IF(OBJECT_ID('tempdb.dbo.#temp') is not null)  drop table #temp

IF(OBJECT_ID('tempdb.dbo.#typecode') is not null)  drop table #typecode
CREATE TABLE #typecode (type_code VARCHAR(10) )

if @typecode is null
begin
	insert #typecode
	(
	    type_code
	)
	select distinct ISNULL(type_code,'') FROM inv_master (nolock)
end
else
begin
	INSERT INTO #typecode
	(
	    type_code
	)
	SELECT distinct ListItem FROM dbo.f_comma_list_to_table(@typecode)
END

IF(OBJECT_ID('tempdb.dbo.#territory') is not null)  drop table #territory
CREATE TABLE #territory ([territory] VARCHAR(10),
						 [region] VARCHAR(3),
						 [r_id] INT,
						 [t_id] INT )

if @terr is null
begin
	insert #territory
	select distinct territory_code, dbo.calculate_region_fn(territory_code) region, 0, 0
	from armaster where territory_code is not NULL
    ORDER BY territory_code
end
else
begin
	INSERT INTO #territory ([territory],[region], [r_id], [t_id])
	SELECT distinct LISTITEM, dbo.calculate_region_fn(listitem) region, 0, 0 FROM dbo.f_comma_list_to_table(@terr)
	ORDER BY ListItem
END

UPDATE t SET t.r_id = r.r_id, t.t_id = tr.t_id
-- SELECT * 
FROM #territory AS t
join
(
SELECT DISTINCT region, rank() OVER (ORDER BY region) r_id
FROM (SELECT DISTINCT region FROM #territory) AS r
) AS r 
on t.region = r.region
JOIN 
(SELECT DISTINCT territory, RANK() OVER (PARTITION BY region ORDER BY territory) t_id
FROM (SELECT DISTINCT region, territory FROM #territory) AS tr
) AS tr
ON t.territory = tr.territory

-- SELECT * FROM #territory AS t

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
sum(isnull(case when i.type_code in ('frame','sun') then c.qnet ELSE 0 END,0)) qnet
, Sales_type = case when isnull(i.category,'Core') IN ('OP') and i.type_code = 'ACC' then 'Accessories' else 'Core' end
into #temp 
FROM  #territory t 
inner join armaster (nolock) a on a.territory_code = t.territory
inner JOIN cvo_sbm_details c (nolock) 
	ON a.customer_code = c.customer AND a.ship_to_code = c.ship_to
inner join inv_master i (nolock) on i.part_no = c.part_no
INNER JOIN #typecode AS t2 ON t2.type_code = i.type_code
where 1=1
-- and (yyyymmdd between @sdately and @edately) or (yyyymmdd between @sdate and @edate)
and (c.yyyymmdd between @sdately and @edate)
GROUP BY ISNULL(c.x_month, MONTH(@today)),
         ISNULL(c.year, YEAR(@today)),
         ISNULL(c.month, DATENAME(MONTH, @today)),
         CASE
         WHEN ISNULL(i.category, 'Core') IN ( 'OP' )
         AND i.type_code = 'ACC' THEN
         'Accessories'
         ELSE
         'Core'
         END,
         a.territory_code

-- fill in the blanks so that all buckets are covered
-- select * from #temp
-- ty

DECLARE @month INT
SELECT @month = 12
WHILE @month > 0 
BEGIN
	insert into #temp
	SELECT   distinct a.territory_code, 
	@month As X_MONTH,
	y.yyear As Year,
	DATENAME(MONTH, CAST(@month AS VARCHAR(2))+'/01/'+CAST(y.yyear AS VARCHAR(4)) ) as month,
	0 anet, 
	0 qnet,
	'Core' Sales_type
	FROM  armaster (nolock) a 
	inner join #territory terr on terr.territory = a.territory_code
	CROSS join
	(SELECT @cy AS yyear
	UNION SELECT @cy - 1 AS yyear) y
	where a.territory_code is not null
	 AND a.salesperson_code <> 'smithma'

	SELECT @month = @month - 1
END

-- SELECT * FROM #temp

-- get current month sales mtd from lastyear

SELECT a.territory_code,
s.Year,
s.X_MONTH,
Sum(s.anet) AS CurrentMonthSales
, Sales_Type = CASE when isnull(i.category,'Core') IN ('op') and i.type_code = 'ACC' then 'Accessories' else 'Core' end
 into #MonthKey 
 FROM   #territory t 
 inner join armaster a (nolock) on a.territory_code = t.territory
 inner join cvo_sbm_details s (nolock) on s.customer = a.customer_code and s.ship_to = a.ship_to_code
 inner join inv_master i (nolock) on i.part_no = s.part_no
 INNER JOIN #typecode AS t2 ON t2.type_code = i.type_code
 where 1=1 
 and s.yyyymmdd between dateadd(m,datediff(mm,0,@edately),0) and @edately
 -- AND i.type_code NOT IN ('lens')
GROUP BY CASE
         WHEN ISNULL(i.category, 'Core') IN ( 'op' )
         AND i.type_code = 'ACC' THEN
         'Accessories'
         ELSE
         'Core'
         END,
         a.territory_code,
         s.year,
         s.X_MONTH

SELECT  a.territory_code, 
a.X_MONTH,
a.Year,
a.month,
sum(a.anet) anet, 
sum(a.qnet)  qnet,
max(isnull(m.CurrentMonthSales,0)) currentmonthsales
, a.Sales_type

into #ly
FROM  #temp a
left join #MonthKey m
ON a.territory_code = m.territory_code AND a.year = m.year AND a.X_MONTH = m.X_MONTH
Where a.year = @cy-1
GROUP BY a.territory_code, a.x_month, a.year, a.month , a.Sales_type

-- get this year figures

SELECT  
a.territory_code, 
a.X_MONTH,
a.year,
a.month,
sum(a.anet) anet, 
sum(a.qnet) qnet,
0 as currentmonthsales
,a.Sales_type

into #ty
FROM  #temp a
Where a.year = @cy
group by a.territory_code, a.x_month, a.year, a.month , a.Sales_type

-- fixup sales person names

select LTRIM(RTRIM(t.territory)) territory_code
, salesperson_code = LTRIM(RTRIM(ISNULL((select top 1 salesperson_name from arsalesp
	where salesperson_code <> 'smithma' 
	and territory_code = t.territory 
	and isnull(date_of_hire,'1/1/1900') <= @today
	and status_type = 1)
	, 'Empty')))
-- , dbo.calculate_region_fn(t.territory) as region
	, t.region
	, t.r_id
	, t.t_id
into #s1 
from #territory t

-- select * From #territory order by territory
-- select * from #s1 where territory_code in (30398,30399) order by territory_code 
-- select * From arsalesp where territory_code = 30398

select 
#ty.territory_code, 
#s1.salesperson_code,
X_MONTH,
Year,
month,
round (anet,2) anet , 
qnet,
round (currentmonthsales,2) currentmonthsales,
Sales_type,

#s1.region
, case when x_month > 9 then 4
			   when x_month > 6 then 3
			   when x_month > 3 then 2
			   else 1
			end as Q
,#s1.r_id
,#s1.t_id
,col = CASE WHEN #s1.t_id % 2 = 1 THEN 'L' ELSE 'R' end 
, ly_ytd = 0
  From #ty -- ty
  left outer join #s1 on #s1.territory_code = #ty.territory_code
Union ALL
 select 
#ly.territory_code, 
#s1.salesperson_code,
X_MONTH,
Year,
month,
round (anet,2) anet , 
qnet,
round (currentmonthsales,2) currentmonthsales,
Sales_type,
#s1.region
, case when x_month > 9 then 4
			   when x_month > 6 then 3
			   when x_month > 3 then 2
			   else 1
			end as Q
,#s1.r_id
,#s1.t_id
,col = CASE WHEN #s1.t_id % 2 = 1 THEN 'L' ELSE 'R' end 
, ly_ytd = CASE WHEN x_month < MONTH(@edately) THEN ROUND(anet,2)
				WHEN x_month = MONTH(@edately) THEN ROUND(currentmonthsales,2)
				ELSE 0 END
            FROM #ly -- ly
left outer join #s1 on #s1.territory_code = #ly.territory_code
-- where #ly.tot = ' Core'



end




GO
