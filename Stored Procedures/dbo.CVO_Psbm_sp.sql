SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Tine Graziosi - CVO
-- Create date: 6/19/2012
-- Description:	Product Sales by Month/Year
-- 1/30/2013 - add pom date - tag
-- =============================================
-- exec [dbo].[CVO_psbm_sp]
-- select * From cvo_psbm

CREATE PROCEDURE [dbo].[CVO_Psbm_sp]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

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

if (object_id('cvo.dbo.cvo_psbm') is not null)
	drop table cvo.dbo.cvo_psbm

if (object_id('cvo.dbo.cvo_psbm') is null)
 begin
 CREATE TABLE [dbo].[cvo_psbm]
(
	[part_no] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[description] [varchar] (60),
	[Brand] [varchar](10), -- i.category
	[Model] [varchar](40), -- ia.field_2
	[type_code] [varchar](10),
	[pom_date] datetime,
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
 
GRANT SELECT ON [dbo].[cvo_psbm] TO [public]

CREATE NONCLUSTERED INDEX [idx_cvo_psbm] ON [dbo].[cvo_psbm] 
 (
	[part_no] ASC,
	[brand] asc,
	[model] asc,
	[month] ASC,
	[year] ASC,
	[yyyymmdd] asc
 ) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]
end


IF(OBJECT_ID('tempdb.dbo.#cvo_psbm') is not null)  
	drop table #cvo_psbm

create table dbo.#cvo_psbm
(part_no varchar(30),
description varchar(60),
brand varchar(10),
style varchar(40),
type_code varchar(10),
pom_date datetime,
x_month int,
month varchar(15),
year int,
asales decimal(20,8),
areturns decimal(20,8),
qsales decimal(20,0),
qreturns decimal(20,0),
order_no int,
order_ext int,
[type] varchar(1))

-- load history data

insert into #cvo_psbm
select 
part_no = o.part_no,
description = substring(i.description,1,60),
Brand = isnull(i.category,''),
Style = isnull(ia.field_2,''),
Type_code = isnull(i.type_code,''),
pom_date = ia.field_28,
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
case when type = 'I' then isnull(o.shipped*o.price,0) else 0 end as asales,
case when type = 'C' then isnull(o.cr_shipped*o.price,0) else 0 end as areturns,
case when type = 'I' 
-- and i.type_code in ('frame','sun') 
then isnull(o.shipped,0) else 0 end as qsales,
case when type = 'C' 
-- and i.type_code in ('frame','sun') 
then isnull(o.cr_shipped,0) else 0 end as qreturns
,oa.order_no, oa.ext, oa.[type] 

--cvo_psbm
from cvo_orders_all_hist oa (nolock)
inner join cvo_ord_list_hist o (nolock) on oa.order_no = o.order_no and oa.ext = o.order_ext 
left outer  join inv_master i (nolock) on o.part_no = i.part_no
left outer  join inv_master_add ia (nolock) on o.part_no = ia.part_no
where 1=1
and oa.date_shipped between @first and @last

-- load live data - use artrx to capture validated sales #
insert into #cvo_psbm
select
part_no = isnull(ol.part_no,''),
description = substring(i.description,1,60),
Brand = isnull(i.category,''),
Style = isnull(ia.field_2,''),
Type_code = isnull(i.type_code,''),
pom_date = ia.field_28,
datepart(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))x_month,
datename(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))month,
datepart(year,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))year,

CASE o.type WHEN 'I' THEN 
			CASE isnull(cl.is_amt_disc,'N')   
			WHEN 'Y' THEN	round(ol.shipped * ol.curr_price,2) -  
						round((ol.shipped * isnull(cl.amt_disc,0)),2)		
			ELSE	round(ol.shipped * ol.curr_price,2) -   
					round(( (ol.shipped * ol.curr_price) * (ol.discount / 100.00)),2) 
			END			
END as asales,

CASE o.type WHEN 'C' THEN 
     round(ol.cr_shipped * ol.curr_price,2) -  
     round(((ol.cr_shipped * ol.curr_price) * (ol.discount / 100.00)),2) 	
end as areturns,

case when o.type = 'I'
	and right(o.user_category,2) <> 'RB' then isnull(ol.shipped,0) else 0 end as qsales,
case when o.type = 'C'
	and left(ol.return_code,2) <> '05' then isnull(ol.cr_shipped,0) else 0 end as qreturns,

ol.order_no, ol.order_ext, o.[type]

from ord_list ol (nolock)
inner join orders o (nolock) on ol.order_no = o.order_no and ol.order_ext = o.ext
LEFT OUTER join orders_invoice oi (nolock) on o.order_no = oi.order_no and o.ext = oi.order_ext
left outer join artrx xx (nolock) on oi.trx_ctrl_num = xx.trx_ctrl_num 
left outer join cvo_ord_list cl (nolock) 
	on ol.order_no = cl.order_no and ol.order_ext = cl.order_ext and ol.line_no = cl.line_no
left outer join inv_master i (nolock) on ol.part_no = i.part_no
left outer join inv_master_add ia (nolock) on i.part_no = ia.part_no
where 1=1

and (ol.shipped <> 0 or ol.cr_shipped <> 0) and ol.status = 'T'
and xx.date_applied between @jfirst and @jlast
and xx.trx_type in (2031,2032) 
and xx.doc_desc not like 'converted%' and xx.doc_desc not like '%nonsales%' 
and xx.doc_ctrl_num not like 'cb%' and xx.doc_ctrl_num not like 'fin%'
and xx.void_flag = 0 and xx.posted_flag = 1

--2) Unposted

insert into #cvo_psbm
select
part_no = isnull(ol.part_no,''),
description = substring(i.description,1,60),
Brand = isnull(i.category,''),
Style = isnull(ia.field_2,''),
Type_code = isnull(i.type_code,''),
pom_date = ia.field_28,
datepart(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))x_month,
datename(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))month,
datepart(year,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))year,
CASE o.type WHEN 'I' THEN 
			CASE isnull(cl.is_amt_disc,'N')   
			WHEN 'Y' THEN	round(ol.shipped * ol.curr_price,2) -  
						round((ol.shipped * isnull(cl.amt_disc,0)),2)		
			ELSE	round(ol.shipped * ol.curr_price,2) -   
					round(( (ol.shipped * ol.curr_price) * (ol.discount / 100.00)),2) 
			END			
END as asales,

CASE o.type WHEN 'C' THEN 
     round(ol.cr_shipped * ol.curr_price,2) -  
     round(((ol.cr_shipped * ol.curr_price) * (ol.discount / 100.00)),2) 	
end as areturns,
case when o.type = 'I'
	and right(o.user_category,2) <> 'RB' then isnull(ol.shipped,0) else 0 end as qsales,
case when o.type = 'C'
	and left(ol.return_code,2) <> '05' then isnull(ol.cr_shipped,0) else 0 end as qreturns
,ol.order_no, ol.order_ext, o.[type]
from ord_list ol (nolock)
inner join orders o (nolock) on ol.order_no = o.order_no and ol.order_ext = o.ext
left outer join orders_invoice oi (nolock) on o.order_no = oi.order_no and o.ext = oi.order_ext
left outer join arinpchg xx (nolock) on oi.trx_ctrl_num = xx.trx_ctrl_num 
left outer join cvo_ord_list cl (nolock) on ol.order_no = cl.order_no and ol.order_ext = cl.order_ext
	and ol.line_no = cl.line_no
left outer join inv_master i (nolock) on ol.part_no = i.part_no
left outer join inv_master_add ia (nolock) on i.part_no = ia.part_no
where 1=1

and (ol.shipped <> 0 or ol.cr_shipped <> 0)
and xx.date_applied between @jfirst and @jlast
and xx.trx_type in (2031,2032) 
and xx.doc_desc not like 'converted%' and xx.doc_desc not like '%nonsales%' 
and xx.doc_ctrl_num not like 'cb%' and xx.doc_ctrl_num not like 'fin%'

--3) AR only details
insert into #cvo_psbm
select
part_no = isnull(i.part_no,'NA'),
description = left(isnull(i.description,'AR Only Transaction'),60),
Brand = isnull(i.category,'ZZ'),
Style = isnull(ia.field_2,'ZZ'),
Type_code = isnull(i.type_code,'ZZ'),
pom_date = ia.field_28,
datepart(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))x_month,
datename(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))month,
datepart(year,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))year,
case when xx.trx_type = 2031
	then isnull(xx.qty_shipped * (xx.unit_price - xx.discount_amt), 0)
	else 0 end as asales,
case when xx.trx_type = 2032 
	then isnull(xx.qty_returned * (xx.unit_price - xx.discount_amt), 0) 
	else 0 end as areturns,
case when xx.trx_type = 2031 then isnull(xx.qty_shipped,0) else 0 end as qsales,
case when xx.trx_type = 2032 then isnull(xx.qty_returned,0) else 0 end as qreturns,
0 as order_no,
0 as order_ext,
case when xx.trx_type = 2031 then 'I' else 'C' end as [type]
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

insert cvo_psbm
 select 
 part_no,
 description,
 brand,
 style,
 type_code,
 pom_date,
 X_MONTH,
 [month],
 [year],
 sum(isnull(asales,0))asales,
 sum(isnull(areturns,0))areturns,
 sum(isnull(asales,0))-sum(isnull(areturns,0)) as anet,
 sum(isnull(qsales,0))qsales,
 sum(isnull(qreturns,0))qreturns,
 sum(isnull(qsales,0)) - sum(isnull(qreturns,0)) as qnet,
 cast ((cast([x_month] as varchar(2))+'/01/'+cast([year] as varchar(4))) as datetime) as yyyymmdd 
 from #cvo_psbm
 group by part_no, description, brand, style, type_code, pom_date, X_MONTH, [month], [year]

END


GO
