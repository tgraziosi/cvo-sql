SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Tine Graziosi - CVO
-- Create date: 6/1/2012
-- Description:	Customer/Ship_to Sales by Month/Year
-- updated: 1/17/13 - tag - corrected yyyymmd for Dec/Jan 2011/12
-- updated: 2/15/2013 - tag - add sales returns for EL reporting
-- =============================================
-- exec [dbo].[CVO_csbm_shipto_sp]
-- select * from cvo.dbo.cvo_csbm_shipto  where x_month = 1 and year = 2012
-- order by customer, ship_to, month
--select sum(anet) from cvo_csbm_shipto where x_month = 1 and year = 2012
--select sum(anet) from cvo_customer_sales_by_month where x_month = 1 and year = 2012
 
/*
 select customer, sum(asales), sum(asales_rx), sum(asales_st), sum(asales_rx)+sum(asales_st),
 sum(qsales), sum(qsales_rx), sum(qsales_st), sum(qsales_rx)+sum(qsales_st)
 From tempdb.dbo.#cvo_csbm_det
  --where customer = '010098'
 group by customer
 having round(sum(asales)-sum(asales_rx)-sum(asales_st),2) <> 0.00
	or round(sum(qsales)-sum(qsales_rx)-sum(qsales_st),2) <> 0.00
 order by customer
 
 select * from tempdb.dbo.#cvo_csbm_det
 where customer = '010098'

 select sum(asales), sum(areturns), sum(qsales), sum(qreturns) from cvo_csbm_shipto_daily
 select sum(asales), sum(areturns), sum(qsales), sum(qreturns) from cvo_customer_sales_by_month
  --where customer = '010098'
  select sum(asales), sum(areturns), sum(qsales), sum(qreturns) from cvo_csbm_shipto
   --where customer = '010098'
   
  select year, x_month, sum(asales), sum(areturns), sum(qsales), sum(qreturns) from cvo_customer_sales_by_month
  -- where customer = '010098'
  GROUP BY year,x_month
  select year, x_month, sum(asales), sum(areturns), sum(qsales), sum(qreturns) from cvo_csbm_shipto
  -- where customer = '010098' 
  GROUP BY year,x_month
 
*/

/* 9/5/2012 - make qty's frames and suns only, and add unposted AR */
/* 12/12/12 - add rx and st sales  */
/* 1/9/2013 - add rx and st returns */

/*  Returns to be excluded  for "Sales"
01-04	Carrier Error
04-3A	Warranty Defect - Hinge
04-3B	Warranty Defect - Solder Point
04-3C	Warranty Defect - Finish
04-3D	Warranty Defect - Bridge Integrity
04-3E	Warranty Defect - Head Fit
04-3G	Warranty Defect - Temple
04-3H	Warranty Defect - Material Failure
04-3I	Warranty Defect - Lens Fit
04-LO	Warranty Defect - Trim
05-01	Fulfillment Error
05-24	Credit & Rebill
05-35	Invoicing Error
06-22	Sales Rep Samples
*/

CREATE PROCEDURE [dbo].[CVO_Csbm_shipto_sp]
AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- exec cvo_csbm_shipto_sp

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

if (object_id('cvo.dbo.cvo_csbm_shipto') is not null)
	drop table cvo.dbo.cvo_csbm_shipto

if (object_id('cvo.dbo.cvo_csbm_shipto') is null)
 begin
 CREATE TABLE [dbo].[cvo_csbm_shipto]
(
	[customer] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ship_to] [varchar](10),
	[customer_name] [varchar](40),
	[X_MONTH] [int] NULL,
	[month] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[year] [int] NULL,
	[asales] [float] NULL,
	[asales_rx] float null,
	[asales_st] float null,
	[areturns] [float] NULL,
	[aret_rx] float null,
	[aret_st] float null,
	[anet] [float] NULL,
	-- new 'sales' fields
	areturns_s float null,
	aret_rx_s float null,
	aret_st_s float null,
	--
	[qsales] [float] NULL,
	[qsales_rx] [float] NULL,
	[qsales_st] [float] NULL,
	[qreturns] [float] NULL,
	[qret_rx] float null,
	[qret_st] float null,
	[qnet] [float] NULL,
	-- new sales fields
	qreturns_s float null,
	qret_rx_s float null,
	qret_st_s float null,
	--
	[yyyymmdd] [datetime]
 ) ON [PRIMARY]
 GRANT SELECT ON [dbo].[cvo_csbm_shipto] TO [public]
 CREATE NONCLUSTERED INDEX [idx_cvo_csbm_shipto] ON [dbo].[cvo_csbm_shipto] 
 (
	[Customer] ASC,
	[ship_to] asc,
	[month] ASC,
	[year] ASC,
	[yyyymmdd] asc
 ) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]
end

IF(OBJECT_ID('tempdb.dbo.#cvo_csbm_det') is not null)  
	drop table #cvo_csbm_det

-- load history data

select 
customer = isnull(oa.cust_code,''),
case
	when not exists (select * from armaster ar where ar.customer_code=oa.cust_code 
					 and ar.ship_to_code=oa.ship_to) then ''
	when oa.ship_to is null then ''
	else oa.ship_To
end as ship_to,
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

cast(datepart(month,oa.date_shipped) as varchar(2) ) +
    '/1/' +
    cast(datepart(year,oa.date_shipped) as varchar(4) )
as yyyymmdd,

case when type = 'i' then isnull(ol.shipped*ol.price,0) else 0 end as asales,
-- 121212
case when type = 'i' and left(oa.user_category,2)='rx' then isnull(ol.shipped*ol.price,0) else 0 end as asales_rx,
case when type = 'i' and isnull(left(oa.user_category,2),'st')<>'rx' then isnull(ol.shipped*ol.price,0) else 0 end as asales_st,
case when type = 'c' then isnull(ol.cr_shipped*ol.price,0) else 0 end as areturns,
-- 010913 - for EL
case when type = 'c' and left(oa.user_category,2)='rx' then isnull(ol.cr_shipped*ol.price,0) else 0 end as aret_rx,
case when type = 'c' and isnull(left(oa.user_category,2),'st')<>'rx' then isnull(ol.cr_shipped*ol.price,0) else 0 end as aret_st,

case when type = 'i' and i.type_code in ('frame','sun') then isnull(ol.shipped,0) else 0 end as qsales,
-- 121212
case when type = 'i' and i.type_code in ('frame','sun') 
	and left(oa.user_category,2)='rx' then isnull(ol.shipped,0) else 0 end as qsales_rx,
case when type = 'i' and i.type_code in ('frame','sun') 
	and isnull(left(oa.user_category,2),'st')<>'rx' then isnull(ol.shipped,0) else 0 end as qsales_st,

case when type = 'c' and i.type_code in ('frame','sun') then isnull(ol.cr_shipped,0) else 0 end as qreturns,
-- 010913 for EL
case when type = 'c' and left(oa.user_category,2)='rx' then isnull(ol.cr_shipped,0) else 0 end as qret_rx,
case when type = 'c' and isnull(left(oa.user_category,2),'st')<>'rx' then isnull(ol.cr_shipped,0) else 0 end as qret_st,

-- new sales fields
case when type = 'c' and ( ol.return_code  
	not in ('01-04','05-01','05-24','05-35','06-22')
	and ol.return_code not like '04-%') then isnull(ol.cr_shipped*ol.price,0) else 0 end as areturns_s,
-- 010913 - for EL
case when type = 'c' and left(oa.user_category,2)='rx' and ( ol.return_code  
	not in ('01-04','05-01','05-24','05-35','06-22')
	and ol.return_code not like '04-%') then isnull(ol.cr_shipped*ol.price,0) 
else 0 end as aret_rx_s,
case when type = 'c' and isnull(left(oa.user_category,2),'st')<>'rx' and ( ol.return_code  
	not in ('01-04','05-01','05-24','05-35','06-22')
	and ol.return_code not like '04-%') then isnull(ol.cr_shipped*ol.price,0) else 0 end as aret_st_s,
case when type = 'c' and i.type_code in ('frame','sun') and ( ol.return_code  
	not in ('01-04','05-01','05-24','05-35','06-22')
	and ol.return_code not like '04-%') then isnull(ol.cr_shipped,0) else 0 end as qreturns_s,
-- 010913 for EL
case when type = 'c' and left(oa.user_category,2)='rx' and ( ol.return_code  
	not in ('01-04','05-01','05-24','05-35','06-22')
	and ol.return_code not like '04-%') 
then isnull(ol.cr_shipped,0) else 0 end as qret_rx_s,
case when type = 'c' and isnull(left(oa.user_category,2),'st')<>'rx' and ( ol.return_code  
	not in ('01-04','05-01','05-24','05-35','06-22')
	and ol.return_code not like '04-%') 
then isnull(ol.cr_shipped,0) else 0 
end as qret_st_s

--
into #cvo_csbm_det
--cvo_csbm_shipto
from cvo_orders_all_hist oa (nolock)
inner join cvo_ord_list_hist ol (nolock) on ol.order_no = oa.order_no and ol.order_ext = oa.ext 
left outer join inv_master i (nolock) on i.part_no = ol.part_no
where 1=1
and oa.date_shipped between @first and @last

-- load live data - use artrx to capture validated sales #
-- tempdb..sp_help #cvo_csbm_det

insert into #cvo_csbm_det
select
	customer = isnull(o.cust_code,''),
	ship_to = isnull(o.ship_to,''),
	
	datepart(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))x_month,
	datename(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))month,
	datepart(year,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))year,
	
	cast(datepart(month,
	convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101)) as varchar(2) ) +
	'/1/'+
	cast(datepart(year,
		convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101)) as varchar(4) )
	as yyyymmdd,
	
	CASE o.type WHEN 'I' THEN 
		CASE isnull(cl.is_amt_disc,'N')   
		WHEN 'Y' THEN	round(ol.shipped * ol.curr_price,2) -  
					round((ol.shipped * isnull(cl.amt_disc,0)),2)		
		ELSE	round(ol.shipped * ol.curr_price,2) -   
				round(( (ol.shipped * ol.curr_price) * (ol.discount / 100.00)),2) 
		END			
	else 0 END as asales,
	
	CASE when o.type = 'i' and left(o.user_category,2)='RX' THEN 
		CASE isnull(cl.is_amt_disc,'N')   
		WHEN 'Y' THEN	round(ol.shipped * ol.curr_price,2) -  
					round((ol.shipped * isnull(cl.amt_disc,0)),2)		
		ELSE	round(ol.shipped * ol.curr_price,2) -   
				round(( (ol.shipped * ol.curr_price) * (ol.discount / 100.00)),2) 
		END			
	else 0 END as asales_rx,
	
	CASE when o.type = 'i' and isnull(left(o.user_category,2),'st')<>'RX' THEN 
		CASE isnull(cl.is_amt_disc,'N')   
		WHEN 'Y' THEN	round(ol.shipped * ol.curr_price,2) -  
					round((ol.shipped * isnull(cl.amt_disc,0)),2)		
		ELSE	round(ol.shipped * ol.curr_price,2) -   
				round(( (ol.shipped * ol.curr_price) * (ol.discount / 100.00)),2) 
		END			
	else 0 END as asales_st,
	
	CASE o.type WHEN 'C' THEN 
		 round(ol.cr_shipped * ol.curr_price,2) -  
		 round(((ol.cr_shipped * ol.curr_price) * (ol.discount / 100.00)),2) 	
	else 0 end as areturns,
	
	CASE when o.type = 'C' and left(o.user_category,2)='RX' THEN 
		 round(ol.cr_shipped * ol.curr_price,2) -  
		 round(((ol.cr_shipped * ol.curr_price) * (ol.discount / 100.00)),2) 	
	else 0 end as aret_rx,
	
	CASE when o.type = 'C' and isnull(left(o.user_category,2),'st')<>'RX' THEN 
		 round(ol.cr_shipped * ol.curr_price,2) -  
		 round(((ol.cr_shipped * ol.curr_price) * (ol.discount / 100.00)),2) 	
	else 0 end as aret_st,

	case when o.type = 'i' and i.type_code in ('FRAME','SUN') and right(o.user_category,2)<> 'rb' then
		isnull(ol.shipped,0) 
	else 0 end as qsales,
	
	case when o.type = 'i' and i.type_code in ('FRAME','SUN') 
		and right(o.user_category,2)<> 'rb' and left(o.user_category,2)='RX' then
		isnull(ol.shipped,0) 
	else 0 end as qsales_rx,
	
	case when o.type = 'i' and i.type_code in ('FRAME','SUN') 
		and right(o.user_category,2)<> 'rb' and isnull(left(o.user_category,2),'st')<>'RX' then
		isnull(ol.shipped,0) 
	else 0 end as qsales_st,
	
	case when o.type = 'c' and i.type_code in ('FRAME','SUN') 
		and left(ol.return_code,2)<> '05' then
		isnull(ol.cr_shipped,0) 
	else 0 end as qreturns,
	
	case when o.type = 'c' and i.type_code in ('FRAME','SUN') 
		and left(ol.return_code,2)<> '05' and left(o.user_category,2)='RX' then
		isnull(ol.cr_shipped,0) 
	else 0 end as qret_rx,
	
	case when o.type = 'c' and i.type_code in ('FRAME','SUN') 
		and left(ol.return_code,2)<> '05' and isnull(left(o.user_category,2),'st')<>'RX' then
		isnull(ol.cr_shipped,0) 
	else 0 end as qret_st,

	-- new sales fields
	
	CASE when o.type = 'C'  
	and ( ol.return_code not in ('01-04','05-01','05-24','05-35','06-22') 
	and ol.return_code not like '04-%')
	THEN 
		 round(ol.cr_shipped * ol.curr_price,2) -  
		 round(((ol.cr_shipped * ol.curr_price) * (ol.discount / 100.00)),2) 	
	else 0 end as areturn_s,
	
	CASE when o.type = 'C' and left(o.user_category,2)='RX'
		and ( ol.return_code not in ('01-04','05-01','05-24','05-35','06-22') 
		and ol.return_code not like '04-%') THEN 
		 round(ol.cr_shipped * ol.curr_price,2) -  
		 round(((ol.cr_shipped * ol.curr_price) * (ol.discount / 100.00)),2) 	
	else 0 end as aret_rx_s,
	
	CASE when o.type = 'C' and isnull(left(o.user_category,2),'st')<>'RX'
		and ( ol.return_code not in ('01-04','05-01','05-24','05-35','06-22') 
		and ol.return_code not like '04-%') THEN 
		 round(ol.cr_shipped * ol.curr_price,2) -  
		 round(((ol.cr_shipped * ol.curr_price) * (ol.discount / 100.00)),2) 	
	else 0 end as aret_st_s,
	
	case when o.type = 'c' and i.type_code in ('FRAME','SUN') 
		and ( ol.return_code not in ('01-04','05-01','05-24','05-35','06-22') 
		and ol.return_code not like '04-%') then
		isnull(ol.cr_shipped,0) 
	else 0 end as qreturns_s,
	
	case when o.type = 'c' and i.type_code in ('FRAME','SUN') 
		and left(o.user_category,2)='RX'  
		and ( ol.return_code not in ('01-04','05-01','05-24','05-35','06-22') 
		and ol.return_code not like '04-%')
	then
		isnull(ol.cr_shipped,0) 
	else 0 end as qret_rx_s,
	
	case when o.type = 'c' and i.type_code in ('FRAME','SUN') 
		and isnull(left(o.user_category,2),'st')<>'RX' 
		and ( ol.return_code not in ('01-04','05-01','05-24','05-35','06-22') 
		and ol.return_code not like '04-%')
	then
		isnull(ol.cr_shipped,0) 
	else 0 end as qret_st_s
		
from ord_list ol (nolock)
inner join orders o (nolock) on ol.order_no = o.order_no and ol.order_ext = o.ext
LEFT OUTER join orders_invoice oi (nolock) on o.order_no = oi.order_no and o.ext = oi.order_ext
left outer join artrx xx (nolock) on oi.trx_ctrl_num = xx.trx_ctrl_num 
left outer join cvo_ord_list cl (nolock) 
	on ol.order_no = cl.order_no and ol.order_ext = cl.order_ext and ol.line_no = cl.line_no
left outer join inv_master i (nolock) on ol.part_no = i.part_no
left outer join inv_master_add ia (nolock) on i.part_no = ia.part_no
where 1=1
and xx.trx_type in (2031,2032) 
and xx.void_flag = 0 and xx.posted_flag = 1
and (ol.shipped <> 0 or ol.cr_shipped <> 0) and ol.status = 'T'
and xx.date_applied between @jfirst and @jlast
and xx.doc_desc not like 'converted%' and xx.doc_desc not like '%nonsales%' 
and xx.doc_ctrl_num not like 'cb%' and xx.doc_ctrl_num not like 'fin%'


-- unposted invoices

insert into #cvo_csbm_det
select
	customer = isnull(o.cust_code,''),
	ship_to = isnull(o.ship_to,''),
		
	datepart(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))x_month,
	datename(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))month,
	datepart(year,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))year,
	
	cast(datepart(month,
	convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101)) as varchar(2) ) +
	'/1/'+
	cast(datepart(year,
		convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101)) as varchar(4) )
	as yyyymmdd,
	
	
	CASE o.type WHEN 'I' THEN 
		CASE isnull(cl.is_amt_disc,'N')   
		WHEN 'Y' THEN	round(ol.shipped * ol.curr_price,2) -  
					round((ol.shipped * isnull(cl.amt_disc,0)),2)		
		ELSE	round(ol.shipped * ol.curr_price,2) -   
				round(( (ol.shipped * ol.curr_price) * (ol.discount / 100.00)),2) 
		END			
	else 0 END as asales,
	
	CASE when o.type = 'i' and left(o.user_category,2)='RX' THEN 
		CASE isnull(cl.is_amt_disc,'N')   
		WHEN 'Y' THEN	round(ol.shipped * ol.curr_price,2) -  
					round((ol.shipped * isnull(cl.amt_disc,0)),2)		
		ELSE	round(ol.shipped * ol.curr_price,2) -   
				round(( (ol.shipped * ol.curr_price) * (ol.discount / 100.00)),2) 
		END			
	else 0 END as asales_rx,
	
	CASE when o.type = 'i' and isnull(left(o.user_category,2),'st')<>'RX' THEN 
		CASE isnull(cl.is_amt_disc,'N')   
		WHEN 'Y' THEN	round(ol.shipped * ol.curr_price,2) -  
					round((ol.shipped * isnull(cl.amt_disc,0)),2)		
		ELSE	round(ol.shipped * ol.curr_price,2) -   
				round(( (ol.shipped * ol.curr_price) * (ol.discount / 100.00)),2) 
		END			
	else 0 END as asales_st,
	
	CASE o.type WHEN 'C' THEN 
		 round(ol.cr_shipped * ol.curr_price,2) -  
		 round(((ol.cr_shipped * ol.curr_price) * (ol.discount / 100.00)),2) 	
	else 0 end as areturns,
	
	CASE when o.type = 'C' and left(o.user_category,2)='RX' THEN 
		 round(ol.cr_shipped * ol.curr_price,2) -  
		 round(((ol.cr_shipped * ol.curr_price) * (ol.discount / 100.00)),2) 	
	else 0 end as aret_rx,
	
	CASE when o.type = 'C' and isnull(left(o.user_category,2),'st')<>'RX' THEN 
		 round(ol.cr_shipped * ol.curr_price,2) -  
		 round(((ol.cr_shipped * ol.curr_price) * (ol.discount / 100.00)),2) 	
	else 0 end as aret_st,

	case when o.type = 'i' and i.type_code in ('FRAME','SUN') and right(o.user_category,2)<> 'rb' then
		isnull(ol.shipped,0) 
	else 0 end as qsales,
	
	case when o.type = 'i' and i.type_code in ('FRAME','SUN') 
		and right(o.user_category,2)<> 'rb' and left(o.user_category,2)='RX' then
		isnull(ol.shipped,0) 
	else 0 end as qsales_rx,
	
	case when o.type = 'i' and i.type_code in ('FRAME','SUN') 
		and right(o.user_category,2)<> 'rb' and isnull(left(o.user_category,2),'st')<>'RX' then
		isnull(ol.shipped,0) 
	else 0 end as qsales_st,
	
	case when o.type = 'c' and i.type_code in ('FRAME','SUN') 
		and left(ol.return_code,2)<> '05' then
		isnull(ol.cr_shipped,0) 
	else 0 end as qreturns,
	
	case when o.type = 'c' and i.type_code in ('FRAME','SUN') 
		and left(ol.return_code,2)<> '05' and left(o.user_category,2)='RX' then
		isnull(ol.cr_shipped,0) 
	else 0 end as qret_rx,
	
	case when o.type = 'c' and i.type_code in ('FRAME','SUN') 
		and left(ol.return_code,2)<> '05' and isnull(left(o.user_category,2),'st')<>'RX' then
		isnull(ol.cr_shipped,0) 
	else 0 end as qret_st,

	-- new sales fields
	
	CASE when o.type = 'C'  
	and ( ol.return_code not in ('01-04','05-01','05-24','05-35','06-22') 
	and ol.return_code not like '04-%')
	THEN 
		 round(ol.cr_shipped * ol.curr_price,2) -  
		 round(((ol.cr_shipped * ol.curr_price) * (ol.discount / 100.00)),2) 	
	else 0 end as areturn_s,
	
	CASE when o.type = 'C' and left(o.user_category,2)='RX'
		and ( ol.return_code not in ('01-04','05-01','05-24','05-35','06-22') 
		and ol.return_code not like '04-%') THEN 
		 round(ol.cr_shipped * ol.curr_price,2) -  
		 round(((ol.cr_shipped * ol.curr_price) * (ol.discount / 100.00)),2) 	
	else 0 end as aret_rx_s,
	
	CASE when o.type = 'C' and isnull(left(o.user_category,2),'st')<>'RX'
		and ( ol.return_code not in ('01-04','05-01','05-24','05-35','06-22') 
		and ol.return_code not like '04-%') THEN 
		 round(ol.cr_shipped * ol.curr_price,2) -  
		 round(((ol.cr_shipped * ol.curr_price) * (ol.discount / 100.00)),2) 	
	else 0 end as aret_st_s,
	
	case when o.type = 'c' and i.type_code in ('FRAME','SUN') 
		and ( ol.return_code not in ('01-04','05-01','05-24','05-35','06-22') 
		and ol.return_code not like '04-%') then
		isnull(ol.cr_shipped,0) 
	else 0 end as qreturns_s,
	
	case when o.type = 'c' and i.type_code in ('FRAME','SUN') 
		and left(o.user_category,2)='RX'  
		and ( ol.return_code not in ('01-04','05-01','05-24','05-35','06-22') 
		and ol.return_code not like '04-%')
	then
		isnull(ol.cr_shipped,0) 
	else 0 end as qret_rx_s,
	
	case when o.type = 'c' and i.type_code in ('FRAME','SUN') 
		and isnull(left(o.user_category,2),'st')<>'RX' 
		and ( ol.return_code not in ('01-04','05-01','05-24','05-35','06-22') 
		and ol.return_code not like '04-%')
	then
		isnull(ol.cr_shipped,0) 
	else 0 end as qret_st_s

from ord_list ol (nolock)
inner join orders o (nolock) on ol.order_no = o.order_no and ol.order_ext = o.ext
LEFT OUTER join orders_invoice oi (nolock) on o.order_no = oi.order_no and o.ext = oi.order_ext
left outer join arinpchg xx (nolock) on oi.trx_ctrl_num = xx.trx_ctrl_num 
left outer join cvo_ord_list cl (nolock) 
	on ol.order_no = cl.order_no and ol.order_ext = cl.order_ext and ol.line_no = cl.line_no
left outer join inv_master i (nolock) on ol.part_no = i.part_no
left outer join inv_master_add ia (nolock) on i.part_no = ia.part_no
where 1=1
and xx.trx_type in (2031,2032) 
-- and xx.void_flag = 0 and xx.posted_flag = 1
and (ol.shipped <> 0 or ol.cr_shipped <> 0) and ol.status = 'T'
and xx.date_applied between @jfirst and @jlast
and xx.doc_desc not like 'converted%' and xx.doc_desc not like '%nonsales%' 
and xx.doc_ctrl_num not like 'cb%' and xx.doc_ctrl_num not like 'fin%'

-- AR Only Transactions
--tempdb..sp_help #cvo_csbm_det

insert into #cvo_csbm_det
select
	customer = isnull(x.customer_code,''),
	ship_to = isnull(x.ship_to_code,''),

	datepart(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))x_month,
	datename(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))month,
	datepart(year,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))year,
	
	cast(datepart(month,
	convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101)) as varchar(2) ) +
	'/1/'+
	cast(datepart(year,
		convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101)) as varchar(4) )
	as yyyymmdd,
	case when xx.trx_type = 2031
	then isnull(xx.qty_shipped * (xx.unit_price - xx.discount_amt), 0)
	else 0 end as asales,
	0 as asales_rx,
	case when xx.trx_type = 2031
	then isnull(xx.qty_shipped * (xx.unit_price - xx.discount_amt), 0)
	else 0 end as asales_st,
	
	case when xx.trx_type = 2032 
	then isnull(xx.qty_returned * (xx.unit_price - xx.discount_amt), 0) 
	else 0 end as areturns,
	0 as aret_rx,
	case when xx.trx_type = 2032 
	then isnull(xx.qty_returned * (xx.unit_price - xx.discount_amt), 0) 
	else 0 end as aret_st,
	
	--case when xx.trx_type = 2031 and i.type_code in ('FRAME','SUN') 
	--then isnull(xx.qty_shipped,0) else 0 end as qsales,
	0 as qsales,
	0 as qsales_rx,
	0 as qsales_st,
	--case when xx.trx_type = 2031 and i.type_code in ('FRAME','SUN') 
	--then isnull(xx.qty_shipped,0) else 0 end as qsales_st,
	
	--case when xx.trx_type = 2032 and i.type_code in ('FRAME','SUN') 
	--then isnull(xx.qty_returned,0) else 0 end as qreturns,
	0 as qreturns,
	0 as qret_rx,
	0 as qret_st,
	--case when xx.trx_type = 2032 and i.type_code in ('FRAME','SUN') 
	--then isnull(xx.qty_returned,0) else 0 end as qret_st,
	
	case when xx.trx_type = 2032 
	then isnull(xx.qty_returned * (xx.unit_price - xx.discount_amt), 0) 
	else 0 end as areturns_s,
	0 as aret_rx_s,
	case when xx.trx_type = 2032
	then isnull(xx.qty_returned * (xx.unit_price - xx.discount_amt), 0) 
	else 0 end as aret_st_s,
	
	--case when xx.trx_type = 2032 and i.type_code in ('FRAME','SUN') 
	--then isnull(xx.qty_returned,0) else 0 end as qreturns_s,
	0 as qreturns_s,
	0 as qret_rx_s,
	0 as qret_st_s
	--case when xx.trx_type = 2032 and i.type_code in ('FRAME','SUN') 
	--then isnull(xx.qty_returned,0) else 0 end as qret_st_s
	
	
From artrxcdt xx (nolock)
inner join artrx x (nolock) on xx.trx_ctrl_num = x.trx_ctrl_num 
left outer join inv_master i (nolock) on xx.item_code = i.part_no
left outer join inv_master_add ia (nolock) on xx.item_code = ia.part_no
where 1=1
and not exists (select * from orders_invoice oi where x.trx_ctrl_num = oi.trx_ctrl_num)
and xx.trx_type in (2031,2032)
and x.doc_desc not like 'converted%' and x.doc_desc not like '%nonsales%' 
and x.doc_ctrl_num not like 'cb%' and x.doc_ctrl_num not like 'fin%'
and x.terms_code not like 'ins%'
and x.void_flag = 0 and x.posted_flag = 1


-- Create summary table by month

insert cvo_csbm_shipto
 select 
 customer,
 ship_to,
 (select top 1 address_name from armaster (nolock) 
  where customer = armaster.customer_code and ship_to_code=ship_to) customer_name,
 x_month,
 month,
 year,
 sum(asales)asales,
 sum(asales_rx)asales_rx,
 sum(asales_st)asales_st,
 sum(areturns)areturns,
 sum(aret_rx)aret_rx,
 sum(aret_st)aret_st,
 sum(asales)-sum(areturns) as anet,
 
 sum(areturns_s) areturns_s,
 sum(aret_rx_s) aret_rx_s,
 sum(aret_st_s) aret_st_s,
 
 sum(qsales)qsales,
 sum(qsales_rx)qsales_rx,
 sum(qsales_st)qsales_st,
 sum(qreturns)qreturns,
 sum(qret_rx)qret_rx,
 sum(qret_st)qret_st,
 sum(qsales) - sum(qreturns) as qnet,

 sum(qreturns_s) as qreturns_s,
 sum(qret_rx_s) as qret_rx_s,
 sum(qret_st_s) as qret_st_s,

 yyyymmdd
-- cast ((cast([x_month] as varchar(2))+'/01/'+cast([year] as varchar(4))) as datetime) as yyyymmdd 
 from #cvo_csbm_det
 group by customer, ship_to,  x_month, month, year, yyyymmdd

END



GO
