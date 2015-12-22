SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		Tine Graziosi - CVO
-- Create date: 4/2/2012
-- Description:	Customer Sales  by Month/Year
-- =============================================
-- exec [dbo].[CVO_Customer_Sales_by_Month_sp]
-- select * from cvo.dbo.cvo_customer_sales_by_month order by customer, month 
-- select * From tempdb.dbo.#cvo_csbm_det
/* 9/5/2012 - make qty's frames and suns only, and add unposted AR */

CREATE PROCEDURE [dbo].[CVO_Customer_Sales_by_Month_sp]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- exec cvo_customer_sales_by_month_sp

declare @first datetime
declare @last datetime
declare @jfirst int
declare @jlast int

select @first = '1/1/2009'	-- add 09 and 10 once validated and fixed
select @last = getdate()

select @jfirst = datediff(day,'1/1/1950',convert(datetime,convert(varchar(8), 
	(year(@first)*10000)+(month(@first)*100) + day(@first))))+711858

select @jlast = datediff(day,'1/1/1950',convert(datetime,convert(varchar(8), 
	(year(@last)*10000)+(month(@last)*100) + day(@last))))+711858

if (object_id('cvo.dbo.cvo_customer_sales_by_month') is not null)
	truncate table cvo.dbo.cvo_customer_sales_by_month

if (object_id('cvo.dbo.cvo_customer_sales_by_month') is null)
 begin
 CREATE TABLE [dbo].[cvo_customer_sales_by_month]
(
	[customer] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[customer_name] [varchar](40),
	[X_MONTH] [int] NULL,
	[month] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[year] [int] NULL,
	[asales] [float] NULL,
	[areturns] [float] NULL,
	[anet] [float] NULL,
	[qsales] [float] NULL,
	[qreturns] [float] NULL,
	[qnet] [float] NULL
 ) ON [PRIMARY]
 GRANT SELECT ON [dbo].[cvo_customer_sales_by_month] TO [public]
 CREATE NONCLUSTERED INDEX [idx_cvo_customer_sales_by_month] ON [dbo].[cvo_customer_sales_by_month] 
 (
	[Customer] ASC,
	[month] ASC,
	[year] ASC
 ) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]
end


IF(OBJECT_ID('tempdb.dbo.#cvo_csbm_det') is not null)  
	drop table #cvo_csbm_det

-- load history data


select 
customer = isnull(oa.cust_code,''),
case when oa.date_shipped >='12/26/2011'
	then datepart(month,'1/1/2012')
	else isnull(datepart(month,oa.date_shipped),'')
end as x_month,
case when oa.date_shipped >= '12/26/2011'
	then datename(month,'1/1/2012')
	else datename(month,oa.date_shipped)
end as month,
case when oa.date_shipped >= '12/26/2011'
	then datepart(year,'1/1/2012')
	else datepart(year,oa.date_shipped)
end as year,
isnull((select sum(o.shipped*o.price) from cvo_ord_list_hist o (nolock)
	where type = 'i' and oa.order_no = order_no 
	and oa.ext = order_ext),0)  asales, 
isnull((select sum(o.cr_shipped*o.price) from cvo_ord_list_hist o (nolock) 
	where type = 'c' and oa.order_no = order_no 
	and oa.ext = order_ext), 0) areturns,
isnull((select sum(o.shipped) from cvo_ord_list_hist o (nolock) 
	inner join inv_master i (nolock) on o.part_no = i.part_no 
	where type = 'i' and oa.order_no = order_no 
	and oa.ext = order_ext
	and i.type_code in ('FRAME','SUN')),0)  qsales, 
isnull((select sum(o.cr_shipped) from cvo_ord_list_hist o (nolock)
	inner join inv_master i (nolock) on o.part_no = i.part_no  
	where type = 'c' and oa.order_no = order_no 
	and oa.ext = order_ext
	and i.type_code in ('FRAME','SUN')), 0) qreturns

into #cvo_csbm_det
--cvo_customer_sales_by_month
from cvo_orders_all_hist oa (nolock)
where oa.date_shipped between @first and @last

-- load live data - use artrx to capture validated sales #

insert into #cvo_csbm_det
select
customer = isnull(xx.customer_code,''),
datepart(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))x_month,
datename(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))month,
datepart(year,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))year,
isnull( (select sum(x.extended_price) from artrxcdt x (nolock) 
	where x.trx_ctrl_num = xx.trx_ctrl_num 
	and xx.doc_ctrl_num = x.doc_ctrl_num
	and x.trx_type = '2031'), 0) asales,
isnull( (select sum(x.extended_price) from artrxcdt x (nolock) 
	where x.trx_ctrl_num = xx.trx_ctrl_num 
	and xx.doc_ctrl_num = x.doc_ctrl_num
	and x.trx_type = '2032'), 0) areturns,

isnull((select sum(o.shipped) from ord_list o (nolock) 
	inner join inv_master i (nolock) on o.part_no = i.part_no 
	inner join orders oo (nolock) on oo.order_no = o.order_no and oo.ext = o.order_ext
	where oo.type = 'i' 
	and oi.order_no = o.order_no and oi.order_ext = o.order_ext
	and right(oo.user_category,2) <> 'RB'
	and i.type_code in ('FRAME','SUN')),0)  qsales, 

isnull((select sum(o.cr_shipped) from ord_list o (nolock)
	inner join inv_master i (nolock) on o.part_no = i.part_no  
	inner join orders oo (nolock) on oo.order_no = o.order_no and oo.ext = o.order_ext
	where oo.type = 'c' 
	and oi.order_no = o.order_no and oi.order_ext = o.order_ext
	and left(o.return_code,2) <> '05'
	and i.type_code in ('FRAME','SUN')), 0) qreturns

--isnull( (select sum(x.qty_shipped) from artrxcdt x (nolock)	
--	where x.trx_ctrl_num = xx.trx_ctrl_num 
--	and xx.doc_ctrl_num = x.doc_ctrl_num
--	and x.trx_type = '2031'), 0) qsales,
--isnull( (select sum(x.qty_returned) from artrxcdt x (nolock) 
--	where x.trx_ctrl_num = xx.trx_ctrl_num 
--	and xx.doc_ctrl_num = x.doc_ctrl_num		
--	and x.trx_type = '2032'), 0) qreturns
from artrx xx (nolock) 
left outer join orders_invoice oi (nolock) on xx.trx_ctrl_num = oi.trx_ctrl_num

where xx.date_applied between @jfirst and @jlast
and xx.trx_type in ('2031','2032') 
and xx.doc_desc not like 'converted%' and xx.doc_desc not like '%nonsales%' 
and xx.doc_ctrl_num not like 'cb%' and xx.doc_ctrl_num not like 'fin%'
and xx.void_flag = 0 and xx.posted_flag = 1

-- unposted invoices

insert into #cvo_csbm_det
select
customer = isnull(xx.customer_code,''),
datepart(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))x_month,
datename(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))month,
datepart(year,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))year,
isnull( (select sum(x.extended_price) from arinpcdt x (nolock) 
	where x.trx_ctrl_num = xx.trx_ctrl_num 
	and xx.doc_ctrl_num = x.doc_ctrl_num
	and x.trx_type = '2031'), 0) asales,
isnull( (select sum(x.extended_price) from arinpcdt x (nolock) 
	where x.trx_ctrl_num = xx.trx_ctrl_num 
	and xx.doc_ctrl_num = x.doc_ctrl_num
	and x.trx_type = '2032'), 0) areturns,

isnull((select sum(o.shipped) from ord_list o (nolock) 
	inner join inv_master i (nolock) on o.part_no = i.part_no 
	inner join orders oo (nolock) on oo.order_no = o.order_no and oo.ext = o.order_ext
	where oo.type = 'i' and oi.order_no = o.order_no and oi.order_ext = o.order_ext
	and right(oo.user_category,2) <> 'RB'
	and i.type_code in ('FRAME','SUN')),0)  qsales, 
isnull((select sum(o.cr_shipped) from ord_list o (nolock)
	inner join inv_master i (nolock) on o.part_no = i.part_no  
	inner join orders oo (nolock) on oo.order_no = o.order_no and oo.ext = o.order_ext
	where oo.type = 'c' 
	and oi.order_no = o.order_no and oi.order_ext = o.order_ext
	and left(o.return_code,2) <> '05'
	and i.type_code in ('FRAME','SUN')), 0) qreturns

--isnull( (select sum(x.qty_shipped) from artrxcdt x (nolock)	
--	where x.trx_ctrl_num = xx.trx_ctrl_num 
--	and xx.doc_ctrl_num = x.doc_ctrl_num
--	and x.trx_type = '2031'), 0) qsales,
--isnull( (select sum(x.qty_returned) from artrxcdt x (nolock) 
--	where x.trx_ctrl_num = xx.trx_ctrl_num 
--	and xx.doc_ctrl_num = x.doc_ctrl_num		
--	and x.trx_type = '2032'), 0) qreturns
from arinpchg xx (nolock) 
left outer join orders_invoice oi (nolock) on xx.trx_ctrl_num = oi.trx_ctrl_num

where xx.date_applied between @jfirst and @jlast
and xx.trx_type in ('2031','2032') 
and xx.doc_desc not like 'converted%' and xx.doc_desc not like '%nonsales%' 
and xx.doc_ctrl_num not like 'cb%' and xx.doc_ctrl_num not like 'fin%'
--and xx.void_flag = 0 and xx.posted_flag = 1


-- Create summary table by month

insert cvo_customer_sales_by_month
 select 
 customer,
 (select top 1 customer_name from arcust (nolock) where customer = arcust.customer_code) customer_name,
 X_MONTH,
 [month],
 [year],
 sum(asales)asales,
 sum(areturns)areturns,
 sum(asales)-sum(areturns) as anet,
 sum(qsales)qsales,
 sum(qreturns)qreturns,
 sum(qsales) - sum(qreturns) as qnet
 from #cvo_csbm_det
 group by customer, year, X_MONTH, [month]

END


GO
