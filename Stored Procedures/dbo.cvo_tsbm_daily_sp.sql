SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





-- =============================================
-- Author:		Tine Graziosi - CVO
-- Create date: 11/7/2012
-- Description:	Territory Sales by Month/Year and Order Type
-- For Territory Dashboard report (SAles Driver)
-- =============================================
-- exec [dbo].[cvo_tsbm_daily_sp]
-- select * from cvo.dbo.cvo_tsbm_daily order by territory, otype, month 
/*
   select sum(anet) from cvo_tsbm_daily 
   select sum(anet) from cvo_sbm_details
   select * From tempdb.dbo.#cvo_tsbm_det
*/
/* 9/5/2012 - make qty's frames and suns only, and add unposted AR */


CREATE PROCEDURE [dbo].[cvo_tsbm_daily_sp]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- exec cvo_tsbm_daily_sp
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

if (object_id('cvo.dbo.cvo_tsbm_daily') is not null)
	drop table cvo.dbo.cvo_tsbm_daily

if (object_id('cvo.dbo.cvo_tsbm_daily') is null)
 begin
 CREATE TABLE [dbo].[cvo_tsbm_daily]
(
	[territory] varchar(8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[otype] varchar(2) not null,
	[X_MONTH] [int] NULL,
	[month] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[year] [int] NULL,
	[asales] [float] NULL,
	[areturns] [float] NULL,
	[anet] [float] NULL,
	[qsales] [float] NULL,
	[qreturns] [float] NULL,
	[qnet] [float] NULL,
	[yyyymmdd] [datetime]
 ) ON [PRIMARY]
 GRANT SELECT ON [dbo].[cvo_tsbm_daily] TO [public]
 CREATE NONCLUSTERED INDEX [idx_cvo_tsbm_shipto] ON [dbo].[cvo_tsbm_daily] 
 (
	[Territory] ASC,
	otype asc,
	[month] ASC,
	[year] ASC,
	[yyyymmdd] asc
 ) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]
end


IF(OBJECT_ID('tempdb.dbo.#cvo_tsbm_det') is not null)  
	drop table #cvo_tsbm_det

-- load history data


select 
Territory = isnull(a.Territory_code,''),
case when left(oa.user_category,2) <> 'RX' then 'ST' else 'RX' end as otype,
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
case when type = 'i' then isnull(o.shipped*o.price,0) else 0 end as asales,
case when type = 'c' then isnull(o.cr_shipped*o.price,0) else 0 end as areturns,
case when type = 'I' and i.type_code in ('FRAME','SUN') then isnull(o.shipped,0) else 0 end as qsales,
case when type = 'C' and i.type_code in ('FRAME','SUN') then isnull(o.cr_shipped,0) else 0 end as qreturns,
convert(varchar(10),oa.date_shipped,101) DateShipped -- for daily version
--
--case when type = 'i' then isnull(o.shipped,0) else 0 end as qsales,
--case when type = 'c' then isnull(o.cr_shipped,0) else 0 end as qreturns
into #cvo_tsbm_det
--cvo_tsbm_shipto
from cvo_orders_all_hist oa (nolock)
inner join cvo_ord_list_hist o (nolock) on oa.order_no = o.order_no and oa.ext = o.order_ext
left outer join inv_master i (nolock) on o.part_no = i.part_no
left outer join armaster a (nolock) on  a.customer_code = oa.cust_code and a.ship_to_code = oa.ship_to
where 1=1
and oa.date_shipped between @first and @last

-- load live data - use artrx to capture validated sales #

insert into #cvo_tsbm_det
select
Territory = isnull(a.territory_code,''),
case when left(isnull(o.user_category,'ST'),2) <>'RX' then 'ST' else 'RX' end as otype,
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
	where oo.type = 'i' and oi.order_no = o.order_no and oi.order_ext = o.order_ext
	and right(oo.user_category,2) <> 'RB'
	and i.type_code in ('FRAME','SUN')),0)  qsales, 
isnull((select sum(o.cr_shipped) from ord_list o (nolock)
	inner join inv_master i (nolock) on o.part_no = i.part_no  
	inner join orders oo (nolock) on oo.order_no = o.order_no and oo.ext = o.order_ext
	where oo.type = 'c' 
	and oi.order_no = o.order_no and oi.order_ext = o.order_ext
	and left(o.return_code,2) <> '05'
	and i.type_code in ('FRAME','SUN')), 0) qreturns,
convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101) DateShipped
--
from artrx xx (nolock) 
left outer join orders_invoice oi (nolock) on xx.trx_ctrl_num = oi.trx_ctrl_num
left outer join orders o (nolock) on oi.order_no = o.order_no and oi.order_ext = o.ext
left outer join armaster a (nolock) on a.customer_code = xx.customer_code and a.ship_to_code = xx.ship_to_code

where 1=1
and xx.date_applied between @jfirst and @jlast
and xx.trx_type in ('2031','2032') 
and xx.doc_desc not like 'converted%' and xx.doc_desc not like '%nonsales%' 
and xx.doc_ctrl_num not like 'cb%' and xx.doc_ctrl_num not like 'fin%'
and xx.void_flag = 0 and xx.posted_flag = 1

-- unposted invoices

insert into #cvo_tsbm_det
select
Territory = isnull(a.territory_code,''),
case when left(isnull(o.user_category,'ST'),2) <>'RX' then 'ST' else 'RX' end as otype,
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
	and i.type_code in ('FRAME','SUN')), 0) qreturns,
convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101) DateShipped
--
from arinpchg xx (nolock) 
left outer join orders_invoice oi (nolock) on xx.trx_ctrl_num = oi.trx_ctrl_num
left outer join armaster a (nolock) on a.customer_code = xx.customer_code and a.ship_to_code = xx.ship_to_code
left outer join orders o (nolock) on oi.order_no = o.order_no and oi.order_ext = o.ext

where 1=1
and xx.date_applied between @jfirst and @jlast
and xx.trx_type in ('2031','2032') 
and xx.doc_desc not like 'converted%' and xx.doc_desc not like '%nonsales%' 
and xx.doc_ctrl_num not like 'cb%' and xx.doc_ctrl_num not like 'fin%'

-- Create summary table by month

insert cvo_tsbm_daily
 select 
 Territory,
 otype,
 X_MONTH,
 [month],
 [year],
 sum(asales)asales,
 sum(areturns)areturns,
 sum(asales)-sum(areturns) as anet,
 sum(qsales)qsales,
 sum(qreturns)qreturns,
 sum(qsales) - sum(qreturns) as qnet,
 DateShipped as yyyymmdd
 from #cvo_tsbm_det
 group by Territory, otype, year, X_MONTH, [month], dateshipped

END



GO
