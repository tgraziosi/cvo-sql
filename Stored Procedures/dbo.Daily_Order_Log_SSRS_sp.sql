SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- exec daily_order_log_ssrs_sp '02/05/2014'
-- tag 021414 - added qualifying order counts

CREATE Procedure [dbo].[Daily_Order_Log_SSRS_sp]
@OrderDate datetime

AS
Begin

IF(OBJECT_ID('tempdb.dbo.#T1') is not null)
drop table dbo.#T1

IF(OBJECT_ID('tempdb.dbo.#T2') is not null)
drop table dbo.#T2

/*
declare @orderdate datetime
select @orderdate = '02/05/2014'
*/

;With C AS
(
Select ol.territory,ol.salesperson,ol.cust_code,ol.ship_to,ol.customer_name,ol.order_no,ol.date_entered,ol.tot_shp_qty,ol.status,ol.status_desc,ol.tot_ord_qty,promo_level,
case
when promo_id = '' then '-'
when promo_id IS NULL then '-' 
else promo_id end AS promo_id,
Replace(tracking, ' ', '') as tracking,
tot_inv_sales,
date_shipped,datename(dw,ol.date_entered) AS Day_Name,datepart(weekday,ol.date_entered) AS Day,
-- tag - 021414
Row_Number() over(partition by ol.cust_code, datename(dw,ol.date_entered)
order by ol.cust_code, datename(dw,ol.date_entered) ) AS UC,
case when ol.tot_ord_qty >=5 then 1 end as qual_order

From cvo_Daily_Order_Log_detail_vw ol 

Where 
Left(ordertype,2) = 'ST'
and right(OL.ORDERTYPE,2) NOT in ('RB','TB','PM')
AND who_entered <> 'BACKORDR'
AND date_entered >= Convert(varchar, DateAdd(dd, 1-(DatePart(dw,@OrderDate) - 1),@OrderDate), 101) And 
date_entered < Convert(varchar, DateAdd(dd, (9 - DatePart(dw, @OrderDate)),@OrderDate), 101)
)

Select * into #T1 From C

update #t1 set uc = null where uc <> 1

-- select #t1.uc*#t1.qual_order as qual_order,*  from #t1 order by cust_code, day

;With C AS
(
select distinct R.territory_code,R.salesperson_code as salesperson,dbo.calculate_region_fn(ar.territory_code) as Region
-- TAG - UPDATE TAKE TERRITORY/REP FROM ARSALESP INSTEAD - AVOID DUPLICATES
from arsalesp r 
-- tg - 2/1/2013 commented out match on sc due to reps having more than 1 territory and don't report
-- Marcella as a rep
join armaster ar (nolock) on --r.salesperson_code = ar.salesperson_code and 
r.territory_code = ar.territory_code  -- EL added territory_code match 1/7/2012
where r.territory_code is not null and salesperson_type = 0 AND R.STATUS_TYPE = 1
and (r.salesperson_code <> 'smithma' and ar.salesperson_code <> 'smithma')
-- order by r.territory_code
)

Select * into #T2 From C

Select isnull(c.territory_code,ol.territory) AS territory,isnull(c.salesperson,ol.salesperson)AS salesperson,
isnull(c.Region,dbo.calculate_region_fn(ol.territory)) Region,
ol.cust_code,ol.ship_to,ol.customer_name,
isnull(ol.uc*ol.qual_order,0) as qual_order, 
ol.order_no,ol.date_entered,ol.tot_shp_qty,ol.status,ol.status_desc,ol.tot_ord_qty,promo_level,
case
when promo_id IS NULL then '-' 
else promo_id end AS promo_id,
tracking,tot_inv_sales,date_shipped,Day_Name,Day


From #T2 c Full outer Join #T1 ol 
ON c.territory_code = ol.territory

order by Region,territory,ol.date_entered
End
GO
