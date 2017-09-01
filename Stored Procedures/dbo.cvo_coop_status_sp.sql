SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Tine Graziosi
-- Create date: 1/23/2013
-- Description:	Report COOP Status as of a date
-- =============================================
-- updates
-- v1.1 10/3/2013 - fix sign on transaction type for redemptions
-- v1.2 12/2/2013 - add support for AP voucher based redemption
-- v1.3 1/8/2014 - fixed issue with even/odd and prior years  EL
-- v1.4 12/3/2015 - add parameter to run for one customer only.

CREATE PROCEDURE [dbo].[cvo_coop_status_sp] @cust VARCHAR(10)  = NULL
	-- exec cvo_coop_status_sp 	'026595'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	

DECLARE
@coop_general_rate DECIMAL(20,8),   
@coop_redeemed_even varchar(40),  
@coop_redeemed_odd varchar(40),  
@coop_general_minsales DECIMAL(20,8)

--Get the values from tables into variables at application level  
-- even = 6850001200000, odd = 6851001200000
select @coop_redeemed_even = ISNULL(value_str, '') from config (NOLOCK) where flag = 'COOP_ACCOUNT'  
select @coop_redeemed_even = '6850%'
--
select @coop_redeemed_odd = '6851%' 
--
select @coop_general_minsales = CAST(ISNULL(value_str, '0') as DECIMAL(20,8))  from config (NOLOCK) where flag = 'COOP_MINSALES'  
select @coop_general_rate = CAST(ISNULL(value_str, '0') as DECIMAL(20,8)) from config (NOLOCK) where flag = 'COOP_RATE'

declare @jfromdate int, @jtodate int, @evenyear int
declare @fromdate datetime, @todate datetime
select @fromdate = DATEADD(yy, DATEDIFF(yy,0,dateadd(yy,-1, getdate())), 0)
select @todate = dateadd(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0, getdate() ), 0)))
select @jfromdate = dbo.adm_get_pltdate_f(@fromdate)
select @jtodate = dbo.adm_get_pltdate_f(@todate) 
set @evenyear = datepart(yy,@todate) % 2 -- 1 = odd, 0 = even

--select @fromdate, @todate, @jfromdate, @jtodate
--select @evenyear

  if (select object_id('tempdb..#coop_cust_info')) is not null 
 begin
	drop table #coop_cust_info
 end
  
  --Get all the values from tables into the variables at the customer level  
 SELECT co.customer_code,
	  ar.customer_name,
	  ISNULL(co.coop_eligible, '') coop_eligible,   
      coop_threshold_amount =
		case when ISNULL(co.coop_threshold_flag, '')<>'y'
		then @coop_general_minsales 
		else isnull(co.coop_threshold_amount,0) 
		end,   
      coop_cust_rate = 
		case when ISNULL(co.coop_cust_rate,0)=0
		then @coop_general_rate else
		isnull(co.coop_cust_rate,0) 
		end,
		ar.salesperson_code,
		ar.territory_code,
		(select top 1 cd.code FROM cvo_cust_designation_codes cd (nolocK)
			JOIN dbo.cvo_designation_codes AS dc (nolock) ON dc.code = cd.code
			where cd.customer_code = co.customer_code and 
			(cd.code in ('BBG') OR cd.primary_flag = 1 ) -- 8/23/17
			AND
			cd.start_date <= getdate() and isnull(cd.end_date,'1/1/2099') >=getdate())
			as desig_code
  into #coop_cust_info
  from
 	cvo_armaster_all co (nolock)
	inner join arcust ar (nolock) on co.customer_code = ar.customer_code

 WHERE   
 isnull(co.coop_eligible,'') = 'Y'
 AND ar.customer_code = CASE when @cust IS NULL THEN ar.customer_code ELSE @cust end
 
 CREATE INDEX #COOP_IDX1 ON #COOP_CUST_INFO (CUSTOMER_CODE)
 
-- --   SELECT * FROM #coop_cust_info
-- get sales figures ty & LY

-- get from orders

 if (select object_id('tempdb..#coop_det')) is not null 
 begin
	drop table #coop_DET
 end
 
 SELECT   
	o.cust_code customer_code,
	datepart(yy,o.date_shipped) yyear,
	SUM(CASE WHEN type = 'C' THEN ((ISNULL(gross_sales,0) - ISNULL(total_discount,0)) * -1)		ELSE ISNULL(gross_sales,0) - ISNULL(total_discount,0) END) as coop_sales
 into #coop_det
 FROM   
	#COOP_CUST_INFO CO (NOLOCK)
	inner join orders (NOLOCK) o on co.customer_code = o.cust_code
 WHERE   
 isnull(co.coop_eligible,'n') = 'Y' and 
 o.status in ('t')
 AND o.date_shipped BETWEEN @fromdate and @todate
 AND ((o.user_category IN (SELECT order_category FROM CVO_order_types WHERE category_eligible = 'Y')) OR (o.[type] = 'C')) -- vx.3  
  
 group by o.cust_code, datepart(yy,o.date_shipped)
-- -- SELECT * FROM #COOP_DET

 insert into #coop_det
 SELECT   
	o.cust_code customer_code,
	datepart(yy,o.date_shipped) yyear,
	SUM(CASE WHEN type = 'C' THEN ((ISNULL(total_amt_order,0) - ISNULL(tot_ord_disc,0)) * -1)		ELSE ISNULL(total_amt_order,0) - ISNULL(tot_ord_disc,0) END) as coop_sales
 FROM   
	#COOP_CUST_INFO CO (NOLOCK)
	inner join cvo_orders_all_hist (NOLOCK) o on co.customer_code = o.cust_code
 WHERE   
 o.status in ('t')
 AND o.date_shipped BETWEEN @fromdate and @todate
 AND ((o.user_category IN (SELECT order_category FROM CVO_order_types WHERE category_eligible = 'Y'))  OR (o.[type] = 'C')) -- vx.3  
  
  group by o.cust_code, datepart(yy,o.date_shipped)
-- -- SELECT * FROM #COOP_DET

 if (select object_id('tempdb..#coop_summ')) is not null 
 begin
	drop table #coop_summ
 end
 
select right(ltrim(rtrim(customer_code)),5) customer_code, yyear, sum(coop_sales) coop_sales 
into #coop_summ 
from #coop_det
group by right(ltrim(rtrim(customer_code)),5), yyear
-- -- SELECT * FROM #COOP_SUMM



if (select object_id('tempdb..#coop_det')) is not null 
 begin
	drop table #coop_DET
 end
 
if (select object_id('tempdb..#coop_cust')) is not null 
 begin
	drop table #coop_cust
 end

  --Get all the values from tables into the variables at the customer level  
 SELECT right(ltrim(rtrim(customer_code)),5) customer_code,
	  min(customer_name) customer_name,
      min(coop_threshold_amount) coop_threshold_amount,
	  min(coop_cust_rate) coop_cust_rate,
	  salesperson_code,
	  territory_code,
	  max(desig_code) desig_code
  into #coop_cust
  from #coop_cust_info
  group by right(ltrim(rtrim(customer_code)),5), salesperson_code, territory_code
 
  if (select object_id('tempdb..#coop_cust_info')) is not null 
 begin
	drop table #coop_cust_info
 end
 

-- get coop threshold and % values

-- get coop redeemed ty & ly

 if (select object_id('tempdb..#coop_redeemed')) is not null 
 begin
	drop table #coop_redeemed
 end


select right(ltrim(rtrim(x.customer_code)),5) customer_code, 
-- v1.3
--yyear = case when (xc.gl_rev_acct like @coop_redeemed_even  and @evenyear = 0)
--                or(xc.gl_Rev_acct like @coop_redeemed_odd and @evenyear = 1)
--	then datepart(yy,@todate) else datepart(yy,@fromdate) end,
yyear = case when (xc.gl_rev_acct like @coop_redeemed_odd  and @evenyear = 1 and x.date_applied < datediff(day,'1/1/1950',convert(datetime,
  convert(varchar( 8), (year(DATEADD(YEAR, DATEDIFF(YEAR, 0, @todate), -1)) * 10000) + (month(DATEADD(YEAR, DATEDIFF(YEAR, 0, @todate), -1)) * 100) + day(DATEADD(YEAR, DATEDIFF(YEAR, 0, @todate), -1))))  ) + 711858  )
			then datepart(yy,@fromdate)-1 

			when (xc.gl_Rev_acct like @coop_redeemed_odd and @evenyear = 1 )
			then datepart(yy,@fromdate) 

			when (xc.gl_Rev_acct like @coop_redeemed_odd and @evenyear = 0)
			then datepart(yy,@fromdate)

			when (xc.gl_rev_acct like @coop_redeemed_even  and @evenyear = 0 and x.date_applied < datediff(day,'1/1/1950',convert(datetime,
  convert(varchar( 8), (year(DATEADD(YEAR, DATEDIFF(YEAR, 0, @todate), -1)) * 10000) + (month(DATEADD(YEAR, DATEDIFF(YEAR, 0, @todate), -1)) * 100) + day(DATEADD(YEAR, DATEDIFF(YEAR, 0, @todate), -1))))  ) + 711858  )
			then datepart(yy,@todate)-2 

			when (xc.gl_rev_acct like @coop_redeemed_even  and @evenyear = 0)
			then datepart(yy,@todate) 
			when (xc.gl_rev_acct like @coop_redeemed_even  and @evenyear = 1)
			then datepart(yy,@todate)-1 
			end,
-- v1.3
-- v1.1
case when x.trx_type = 2032 then sum(extended_price) 
     when x.trx_type = 2031 then sum(extended_price)*-1 end as coop_redeemed
-- v1.1
into #coop_redeemed
from artrxcdt xc (nolock)
inner join artrx x (nolock) on x.trx_ctrl_num = xc.trx_ctrl_num
where ( xc.gl_rev_acct like @coop_redeemed_even or xc.gl_rev_acct like @coop_redeemed_odd )
and  x.date_applied between @jfromdate and @jtodate
--v1.1
and x.trx_type in (2031,2032)
--v1.1
group by right(ltrim(rtrim(x.customer_code)),5)
,datepart(year,convert(varchar,dateadd(d,x.date_applied-711858,'1/1/1950'),101)),
 xc.gl_rev_acct, x.trx_type, x.date_applied

/*
-- tag version
select right(ltrim(rtrim(x.customer_code)),5) customer_code, 
yyear = case when (xc.gl_rev_acct like @coop_redeemed_even  and @evenyear = 0)
                or(xc.gl_Rev_acct like @coop_redeemed_odd and @evenyear = 1)
	then datepart(yy,@todate) else datepart(yy,@fromdate) end,
-- v1.1
case when x.trx_type = 2032 then sum(extended_price) 
     when x.trx_type = 2031 then sum(extended_price)*-1 end as coop_redeemed
-- v1.1
into #coop_redeemed
from artrxcdt xc (nolock)
inner join artrx x (nolock) on x.trx_ctrl_num = xc.trx_ctrl_num
where ( xc.gl_rev_acct like @coop_redeemed_even or xc.gl_rev_acct like @coop_redeemed_odd )
and  x.date_applied between @jfromdate and @jtodate
--v1.1
and x.trx_type in (2031,2032)
--v1.1
group by right(ltrim(rtrim(x.customer_code)),5)
,datepart(year,convert(varchar,dateadd(d,x.date_applied-711858,'1/1/1950'),101)), xc.gl_rev_acct, x.trx_type
*/

-- v1.2 - get ap voucher transactions for redemptions
insert into #coop_redeemed
select right(ltrim(rtrim(x.reference_code)),5) customer_code,
yyear = case when (x.gl_exp_acct like @coop_redeemed_even  and @evenyear = 0)
                or(x.gl_exp_acct like @coop_redeemed_odd and @evenyear = 1)
	then datepart(yy,@todate) else datepart(yy,@fromdate) end,	
sum(x.amt_extended) as coop_redeemed  -- debit memo 
from apvodet x  (nolock)
inner join apvohdr xap (nolock) on x.trx_ctrl_num = xap.trx_ctrl_num
where ( x.gl_exp_acct like @coop_redeemed_even or x.gl_exp_acct like @coop_redeemed_odd )
and  xap.date_applied between @jfromdate and @jtodate
group by right(ltrim(rtrim(x.reference_code)),5)
,datepart(year,convert(varchar,dateadd(d,xap.date_applied-711858,'1/1/1950'),101)), x.gl_exp_acct

-- select * From apvodet
-- v1.3  -- remove redeemed from 2x years ago
delete from #coop_redeemed where yyear = datepart(yy,@todate)-2 
-- v1.3
-- select * from #coop_redeemed

-- final select for output

;with cte as 
( select customer_code,
isnull(yyear,0) yyear, isnull(coop_sales,0) coop_sales, 
0 as coop_redeemed
from #coop_summ 
union all
select customer_code,
isnull(yyear,0) yyear, 
0 as coop_sales,
isnull(coop_redeemed,0) coop_redeemed
from #coop_redeemed ) 
select
ci.territory_code, ci.salesperson_code, ci.customer_code, customer_name, coop_threshold_amount, coop_cust_rate , 
ci.desig_code,
yyear, coop_sales,
coop_earned = 
case when coop_sales > coop_threshold_amount then
	round(coop_cust_rate/100 * coop_sales,2) else 0 end,
coop_redeemed
--coop_avail =
-- case when coop_sales > coop_threshold_amount then
--	round(coop_cust_rate/100 * coop_sales,2) - coop_redeemed else 0 end
from cte, #coop_cust ci
where cte.customer_code = ci.customer_code 



END



GO
GRANT EXECUTE ON  [dbo].[cvo_coop_status_sp] TO [public]
GO
