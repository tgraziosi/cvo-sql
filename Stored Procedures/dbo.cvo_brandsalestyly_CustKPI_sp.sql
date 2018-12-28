SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_brandsalestyly_CustKPI_sp]  
@AsOfDateParam datetime,
@Brand varchar(1000),
@Type_Code varchar(1000),
@Territory varchar(1000)

as

-- exec cvo_brandsalestyly_custkpi_sp '09/30/2015', 'bcbg','frame,sun', 20201

declare @LYSTART datetime, @LYEND datetime, @sdate datetime, @edate datetime

set @sdate = dateadd(year, -1, DATEADD(DAY,1,@ASOFDATEPARAM))
set @edate = @asofdateparam

SET @LYSTART = DATEADD(YEAR, -1, @SDATE)
SET @LYEND  = DATEADD(YEAR, -1, @EDATE)

CREATE TABLE #restype ([restype] VARCHAR(10))
INSERT INTO #restype ([restype])
SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@Type_code)
CREATE TABLE #Terr ([terr] VARCHAR(10))
INSERT INTO #terr ([terr])
SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@Territory)

CREATE TABLE #brand ([brand] VARCHAR(10))
INSERT INTO #brand ([brand])
SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@Brand)

;with cte as 
(
select ar.customer_code, ar.status_type
-- , i.category brand
,sum(case when yyyymmdd <= @LYEND then anet else 0 end) LYNET
,sum(case when yyyymmdd >= @sdate then anet else 0 end) TYNET

FROM
#brand b
JOIN inv_master i  on b.brand = i.category
join #restype r on i.type_code = r.restype
join cvo_sbm_details s  on s.part_no = i.part_no
join arcust ar on s.customer = ar.customer_code and s.ship_to = ar.ship_to_code
join #terr t on t.terr = ar.territory_code


where yyyymmdd between @LYSTART and @edate
-- and i.category = @BRAND

group by ar.customer_code, ar.status_type
-- , i.category
),
TEMP AS 
(select customer_code, 
-- brand
LYNET, TYNET, 
case when TYNET > 1 and LYNET = 0 then 1 else 0 end as New,
case when tynet > 1 then 1 else 0 end as Active,
case when TYNET <= 500 and LYNET >= 1200 then 1 else 0 end as Dropped_Active,
case when tynet <=0 and lynet >=1 then 1 else 0 end as Dropped_Any,
case when tynet = 0 then 0 else (tynet-lynet)/tynet end as pct_diff
from cte
)

select 
sum(new) as New_Cust_cnt,
sum(case when new = 1 then tynet else 0 end) as New_cust_sales,
sum(active) as Active_Cust_cnt,
sum(case when active = 1 then tynet else 0 end) as Active_Sales,
sum(dropped_active) as Dropped_active_cnt,
sum(case when dropped_active = 1 then tynet else 0 end) as Dropped_Active_sales,
sum(dropped_any) as dropped_any_cnt,
sum(case when dropped_any = 1 then tynet else 0 end) as Dropped_any_sales,
sum(case when pct_diff >0.01 then 1 else 0 end) as up_sales_cnt,
sum(case when pct_diff >0.01 then tynet-lynet else 0 end) as up_sales,
sum(case when pct_diff <=0.01 then 1 else 0 end) as down_sales_cnt,
sum(case when pct_diff <=0.01 then tynet-lynet else 0 end) as down_sales
from TEMP



GO
GRANT EXECUTE ON  [dbo].[cvo_brandsalestyly_CustKPI_sp] TO [public]
GO
