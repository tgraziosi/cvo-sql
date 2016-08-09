SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Tine Graziosi - CVO
-- Create date: 6/1/2012
-- Description:	Sales Detail By Day - for Reporting
-- =============================================
-- exec [dbo].[CVO_sbm_details_sp]
-- select asales, areturns, lsales, * from cvo.dbo.cvo_sbm_details where iscl = 1 -- order by customer, ship_to, month 
-- select * From tempdb.dbo.#cvo_sbm_det
/*
select sum(asales), sum(areturns), sum(qsales), sum(qreturns),sum(anet), sum(lsales),
sum(csales) from cvo_sbm_details  WHERE CUSTOMER = '011111'
select * from cvo_sbm_details where part_No = 'bcgcolink5316'
select sum(asales), sum(areturns), sum(qsales), sum(qreturns) from cvo_csbm_shipto_daily  WHERE CUSTOMER = '011111'
*/
--select sum(asales), sum(areturns), sum(qsales), sum(qreturns) from cvo_csbm_shipto WHERE CUSTOMER = '011111'

/* 9/5/2012 - make qty's frames and suns only, and add unposted AR */
/* 9/9/2013 - add location for DRP support */
-- 11/8/2013 - add identity column for Data Warehouse. move Drop/Create table right before insert
-- 5/2014 - add isCL and isBO indicators
-- 10/2014 - add salesperson on order/invoice for Sales Details in Cube
-- 03/16 - fix asales calculation for rounding of discounts

CREATE PROCEDURE [dbo].[CVO_sbm_details_sp]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- exec cvo_sbm_details_sp
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


IF(OBJECT_ID('tempdb.dbo.#cvo_sbm_det') is not null)  
	drop table #cvo_sbm_det


IF(OBJECT_ID('tempdb.dbo.#cvo_sbm_det') is  null)  
begin
CREATE TABLE #cvo_sbm_det
(customer varchar(10),
ship_to varchar(10),
part_no varchar(30),
PROMO_ID VARCHAR(20),
promo_level varchar(30),
return_code varchar(10),
user_category varchar(10),
location varchar(10), -- tag 090913
c_month int,
c_year int,
x_month int,
month varchar(16),
year int,
asales decimal(20,6),
areturns decimal(20,6),
qsales decimal(20,0),
qreturns decimal(20,0),
csales float,
lsales float,
DateShipped datetime,
DateOrdered datetime,
isCL int -- 4/25/2014 - closeout flag  0=no, 1= yes.  80% - 99% discounts should be classed as CLs
, isBO int -- is this a backorder 0 = no, 1 = yes
, slp varchar(10)
)
end


CREATE NONCLUSTERED INDEX [idx_sbm_det_tmp]
ON #cvo_sbm_det ([asales],[areturns],[qsales],[qreturns],[lsales])


-- load live data - use artrx to capture validated sales #

insert into #cvo_sbm_det
select
customer = isnull(xx.customer_code,''),
ship_to = isnull(xx.ship_to_code,''),
isnull(i.part_no,'CVZPOSTAGE') AS PART_NO,
case when ol.return_code = '05-24' and co.promo_id = 'BEP'
then '' else isnull(co.promo_id,'') end as promo_id,
case when ol.return_code = '05-24' and co.promo_id = 'BEP'
then '' else isnull(co.promo_level,'') end as promo_level,
isnull(ol.return_code,'') return_code,
isnull(o.user_category,'ST') user_category,
ol.location, -- tag 090913
datepart(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))c_month,
datepart(year,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))c_year,
datepart(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))x_month,
datename(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))month,
datepart(year,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))year,
--case o.type when 'i' then 
--	case isnull(cl.is_amt_disc,'n')
--		when 'y' then round (ol.shipped * ol.curr_price,2) - round(ol.shipped*isnull(cl.amt_disc,0),2)
--		else round(ol.shipped*ol.curr_price,2) - round(ol.shipped*(ol.curr_price*(ol.discount/100.00)),2) 
--	end
--else 0
--end as asales,

case o.type when 'i' then 
	case isnull(cl.is_amt_disc,'n')
		when 'y' then round (ol.shipped * (ol.curr_price - ROUND(ISNULL(cl.amt_disc,0),2)),2,1)
		ELSE ROUND( ol.shipped * (ol.curr_price - ROUND(ol.curr_price*(ol.discount/100.00),2)) ,2) 
	end
else 0
end as asales,

case o.type when 'c' then 
	round(ol.cr_shipped * ol.curr_price,2) - round(ol.cr_shipped * (ol.curr_price * (ol.discount/100.00)),2)
else 0
end as areturns,
case when o.type = 'i' then ol.shipped else 0 end as qsales,
case when o.type = 'c' then ol.cr_shipped else 0 end as qreturns,
-- add cost and list 11/12/13
round((ol.shipped-ol.cr_shipped) * (ol.cost+ol.ovhd_dolrs+ol.util_dolrs),2) as csales,
round((ol.shipped-ol.cr_shipped) * cl.list_price,2) as lsales,
--
convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101) DateShipped,
dateadd(dd, datediff(dd,0,oo.date_entered), 0) DateOrdered
, 0 -- isCL
, case when o.who_entered <> 'BACKORDR' THEN 0 ELSE 1 END  -- isBO
,  o.salesperson slp -- salesperson on this order -- 100314

from orders o (nolock)
	inner join cvo_orders_all co (nolock) on co.order_no = o.order_no and co.ext = o.ext
	inner join ord_list ol (nolock) on ol.order_no = o.order_no and ol.order_ext = o.ext
	left outer join cvo_ord_list cl (nolock) on cl.order_no = ol.order_no and cl.order_ext = ol.order_ext
		and cl.line_no = ol.line_no
left outer join orders_invoice oi (nolock) on oi.order_no = o.order_no and oi.order_ext = o.ext
left outer join artrx xx (nolock) on xx.trx_ctrl_num = oi.trx_ctrl_num

left outer join 
(select order_no, min(ooo.date_entered) from orders ooo(nolock) where ooo.status <> 'v' group by ooo.order_no)
as oo (order_no, date_entered) on oo.order_no = o.order_no
-- tag 013114
left outer join inv_master i on i.part_no = ol.part_no

where 1=1
and xx.date_applied between @jfirst and @jlast
and xx.trx_type in (2031,2032) 
and xx.doc_desc not like 'converted%' and xx.doc_desc not like '%nonsales%' 
and xx.doc_ctrl_num not like 'cb%' and xx.doc_ctrl_num not like 'fin%'
and xx.void_flag = 0 and xx.posted_flag = 1


-- unposted invoices

insert into #cvo_sbm_det
select
customer = isnull(xx.customer_code,''),
ship_to = isnull(xx.ship_to_code,''),
isnull(i.part_no,'CVZPOSTAGE') AS PART_NO,
case when ol.return_code = '05-24' and co.promo_id = 'BEP'
then '' else isnull(co.promo_id,'') end as promo_id,
case when ol.return_code = '05-24' and co.promo_id = 'BEP'
then '' else isnull(co.promo_level,'') end as promo_level,
isnull(ol.return_code,'') return_code,
isnull(o.user_category,'ST') user_category,
ol.location, -- 090913 tag
datepart(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))c_month,
datepart(year,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))c_year,
datepart(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))x_month,
datename(month,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))month,
datepart(year,convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101))year,
--case o.type when 'i' then 
--	case isnull(cl.is_amt_disc,'n')
--		when 'y' then round (ol.shipped * ol.curr_price,2) - round(ol.shipped*isnull(cl.amt_disc,0),2)
--		else round(ol.shipped*ol.curr_price,2) - round(ol.shipped*(ol.curr_price*(ol.discount/100.00)),2) 
--	end
--else 0
--end as asales,


case o.type when 'i' then 
	case isnull(cl.is_amt_disc,'n')
		when 'y' then round (ol.shipped * (ol.curr_price - ROUND(ISNULL(cl.amt_disc,0),2)),2,1)
		else round(ol.shipped*ol.curr_price,2) - round(ol.shipped*(ol.curr_price*(ol.discount/100.00)),2) 
	end
else 0
end as asales,

case o.type when 'c' then 
	round(ol.cr_shipped * ol.curr_price,2) - round(ol.cr_shipped * (ol.curr_price * (ol.discount/100.00)),2)
else 0
end as areturns,
case when o.type = 'i' then ol.shipped else 0 end as qsales,
case when o.type = 'c' then ol.cr_shipped else 0 end as qreturns,
-- add cost and list 11/12/13
round((ol.shipped-ol.cr_shipped) * (ol.cost+ol.ovhd_dolrs+ol.util_dolrs),2) as csales,
round((ol.shipped-ol.cr_shipped) * cl.list_price,2) as lsales,
--

convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101) DateShipped,
isnull(dateadd(dd, datediff(dd,0,oo.date_entered), 0) , 
       convert(varchar,dateadd(d,xx.date_applied-711858,'1/1/1950'),101)) as dateOrdered
, 0
, case when o.who_entered <> 'BACKORDR' THEN 0 ELSE 1 END
, o.salesperson slp

from orders o (nolock)
	inner join cvo_orders_all co (nolock) on co.order_no = o.order_no and co.ext = o.ext
	inner join ord_list ol (nolock) on ol.order_no = o.order_no and ol.order_ext = o.ext
	left outer join cvo_ord_list cl (nolock) on cl.order_no = ol.order_no and cl.order_ext = ol.order_ext
		and cl.line_no = ol.line_no
inner join orders_invoice oi (nolock) on oi.order_no = o.order_no and oi.order_ext = o.ext
left outer join arinpchg xx (nolock) on xx.trx_ctrl_num = oi.trx_ctrl_num
left outer join 
(select order_no, min(ooo.date_entered) from orders ooo(nolock) where ooo.status <> 'v' group by ooo.order_no)
as oo (order_no, date_entered) on oo.order_no = o.order_no
-- 013114
left outer join inv_master i on i.part_no = ol.part_no

where 1=1
and xx.date_applied between @jfirst and @jlast
and xx.trx_type in (2031,2032) 
and xx.doc_desc not like 'converted%' and xx.doc_desc not like '%nonsales%' 
and xx.doc_ctrl_num not like 'cb%' and xx.doc_ctrl_num not like 'fin%'

-- AR Only Activity

insert into #cvo_sbm_det
select   
h.customer_code customer,
h.ship_to_code ship_to,
isnull(i.part_no,'CVZPOSTAGE') AS PART_NO,
/*case when d.item_code = '' 
	 OR NOT EXISTS (SELECT 1 FROM INV_MASTER WHERE PART_NO = D.ITEM_CODE) 
	then 'CVZPOSTAGE' ELSE D.ITEM_CODE END AS  part_no,
*/
case when charindex('-',h.order_ctrl_num)<=1 then ''
	else
		isnull((select top 1 promo_id from cvo_orders_all co where co.order_no = 
		left(h.order_ctrl_num,charindex('-',h.order_ctrl_num)-1) and co.ext = 0),'')
end as promo_id,
case when charindex('-',h.order_ctrl_num)<=1 then ''
	else
		isnull((select top 1 promo_level from cvo_orders_all co where co.order_no = 
		left(h.order_ctrl_num,charindex('-',h.order_ctrl_num)-1) and co.ext = 0),'')
end as promo_level,
case when h.trx_type = 2032 then '06-13' else '' end as return_code,
case when charindex('-',h.order_ctrl_num)<=1 then ''
	else
		isnull((select top 1 user_category from orders co where co.order_no = 
		left(h.order_ctrl_num,charindex('-',h.order_ctrl_num)-1) and co.ext = 0),'') 
end as user_category,
'001' as location, -- tag - 090913 
datepart(month,convert(varchar,dateadd(d,h.date_applied-711858,'1/1/1950'),101))c_month,
datepart(year,convert(varchar,dateadd(d,h.date_applied-711858,'1/1/1950'),101))c_year,
datepart(month,convert(varchar,dateadd(d,h.date_applied-711858,'1/1/1950'),101))x_month,
datename(month,convert(varchar,dateadd(d,h.date_applied-711858,'1/1/1950'),101))month,
datepart(year,convert(varchar,dateadd(d,h.date_applied-711858,'1/1/1950'),101))year,
case when h.trx_type = 2031 then round(d.extended_price ,2) else 0 end as asales,
case when h.trx_type = 2032 then round(d.extended_price ,2) else 0 end as areturns,
case when h.trx_type = 2031 then round((d.qty_shipped) ,2) else 0 end as qsales,
case when h.trx_type = 2032 then round((d.qty_returned) ,2) else 0 end as qreturns,
case when h.trx_type = 2031 then round(d.amt_cost * d.qty_shipped,2) 
     when h.trx_type = 2032 then round(d.amt_cost * d.qty_returned * -1,2) end as csales,
case when h.trx_type = 2031 then round(d.extended_price,2) 
     when h.trx_type = 2032 then round(d.extended_price*-1,2) end as lsales,
convert(varchar,dateadd(d,h.date_applied-711858,'1/1/1950'),101) DateShipped
,convert(varchar,dateadd(d,h.date_applied-711858,'1/1/1950'),101) as dateOrdered
, 0
, 0
, h.salesperson_code as slp

from artrx_all h (nolock)  
join artrxcdt d (nolock) on h.trx_ctrl_num = d.trx_ctrl_num  
-- 013114
left outer join inv_master i on i.part_no = d.item_code

where 
not exists(select 1 from orders_invoice oi where oi.trx_ctrl_num =  h.trx_ctrl_num)
and h.date_applied between @jfirst and @jlast
and h.trx_type in (2031,2032)  
and h.doc_ctrl_num not like 'FIN%' and h.doc_ctrl_num not like 'CB%'   
and h.doc_desc not like 'converted%' and h.doc_desc not like '%nonsales%' 
and h.terms_code not like 'ins%'
and (d.gl_rev_acct like '4000%' or 
     d.gl_rev_acct like '4500%' or
     d.gl_rev_acct like '4530%' or -- 022514 - tag - add account for debit promo's
     d.gl_rev_acct like '4600%' or 
     d.gl_rev_acct like '4999%')  
and h.void_flag <> 1     --v2.0  

-- ar unposted

insert into #cvo_sbm_det
select   
h.customer_code customer,
h.ship_to_code ship_to, 
isnull(i.part_no,'CVZPOSTAGE') AS PART_NO,
/*case when d.item_code = '' 
	OR NOT EXISTS (SELECT 1 FROM INV_MASTER WHERE PART_NO = D.ITEM_CODE) 
	then 'CVZPOSTAGE' ELSE D.ITEM_CODE END AS  part_no, 
*/
-- d.item_code part_no,
case when charindex('-',h.order_ctrl_num)<=1 then ''
	else
		isnull((select top 1 promo_id from cvo_orders_all co where co.order_no = 
		left(h.order_ctrl_num,charindex('-',h.order_ctrl_num)-1) and co.ext = 0),'')
end as promo_id,
case when charindex('-',h.order_ctrl_num)<=1 then ''
	else
		isnull((select top 1 promo_level from cvo_orders_all co where co.order_no = 
		left(h.order_ctrl_num,charindex('-',h.order_ctrl_num)-1) and co.ext = 0),'')
end as promo_level,
case when h.trx_type = 2032 then '06-13' else '' end as return_code,
case when charindex('-',h.order_ctrl_num)<=1 then ''
	else
		isnull((select top 1 user_category from orders co where co.order_no = 
		left(h.order_ctrl_num,charindex('-',h.order_ctrl_num)-1) and co.ext = 0),'') 
end as user_category,
'001' as location, -- 090913 tag
datepart(month,convert(varchar,dateadd(d,h.date_applied-711858,'1/1/1950'),101))c_month,
datepart(year,convert(varchar,dateadd(d,h.date_applied-711858,'1/1/1950'),101))c_year,
datepart(month,convert(varchar,dateadd(d,h.date_applied-711858,'1/1/1950'),101))x_month,
datename(month,convert(varchar,dateadd(d,h.date_applied-711858,'1/1/1950'),101))month,
datepart(year,convert(varchar,dateadd(d,h.date_applied-711858,'1/1/1950'),101))year,
case when h.trx_type = 2031 then round(d.extended_price ,2) else 0 end as asales,
case when h.trx_type = 2032 then round(d.extended_price ,2) else 0 end as areturns,
case when h.trx_type = 2031 then round((d.qty_shipped) ,2) else 0 end as qsales,
case when h.trx_type = 2032 then round((d.qty_returned) ,2) else 0 end as qreturns,
case when h.trx_type = 2031 then round(d.unit_cost * d.qty_shipped,2) 
     when h.trx_type = 2032 then round(d.unit_cost * d.qty_returned * -1,2) end as csales,
case when h.trx_type = 2031 then round(d.extended_price,2) 
     when h.trx_type = 2032 then round(d.extended_price*-1,2) end as lsales,
convert(varchar,dateadd(d,h.date_applied-711858,'1/1/1950'),101) DateShipped
,convert(varchar,dateadd(d,h.date_applied-711858,'1/1/1950'),101) as dateOrdered
, 0
, 0
, h.salesperson_code slp

from arinpchg h (nolock)  
join arinpcdt d (nolock) on h.trx_ctrl_num = d.trx_ctrl_num  
-- 013114
left outer join inv_master i on i.part_no = d.item_code

where 
not exists(select 1 from orders_invoice oi where oi.trx_ctrl_num = h.trx_ctrl_num)
and h.trx_type in (2031,2032)  
and h.date_applied between @jfirst and @jlast
and h.doc_ctrl_num not like 'FIN%' and h.doc_ctrl_num not like 'CB%'   
and h.terms_code not like 'ins%'
and h.doc_desc not like 'converted%' and h.doc_desc not like '%nonsales%' 
and (d.gl_rev_acct like '4000%' or
     d.gl_rev_acct like '4500%' or
     d.gl_rev_acct like '4530%' or
     d.gl_rev_acct like '4600%' or 
     d.gl_rev_acct like '4999%')  
-- load history data

insert into #cvo_sbm_det
select 
customer = isnull(oa.cust_code,''),
case
	when not exists (select * from armaster ar where ar.customer_code=oa.cust_code 
					 and ar.ship_to_code=oa.ship_to) then ''
	when oa.ship_to is null then ''
	else oa.ship_To
end as ship_to,

isnull(i.part_no, 'CVZPOSTAGE') part_no,
isnull(oa.user_def_fld3,'') as promo_id,
isnull(oa.user_def_fld9,'') as promo_level,
isnull(o.return_code,'') as return_code,
isnull(oa.user_category,'ST') as user_category,
isnull(o.location,'001') location, -- 090913 tag
isnull(datepart(month,oa.date_shipped),'') as c_month,
isnull(datepart(year,oa.date_shipped),'') as c_year,
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
case when type = 'I' then isnull(o.shipped,0) else 0 end as qsales,
case when type = 'C' then isnull(o.cr_shipped,0) else 0 end as qreturns,
-- 11/12/13
isnull((o.shipped-o.cr_shipped)*o.cost,0) as csales,
isnull((o.shipped-o.cr_shipped)*pp.price_a,0) as lsales,   

convert(varchar(10),oa.date_shipped,101) DateShipped -- for daily version
, oo.date_entered as dateOrdered
, 0
, 0
, oa.salesperson slp

--
from cvo_orders_all_hist oa (nolock)
inner join cvo_ord_list_hist o (nolock) on oa.order_no = o.order_no and oa.ext = o.order_ext
left outer join inv_master i (nolock) on o.part_no = i.part_no
left outer join part_price pp (nolock) on pp.part_no = o.part_no
left outer join 
(select order_no, min(ooo.date_entered) from cvo_orders_all_hist ooo(nolock) where ooo.status <> 'v' group by ooo.order_no)
as oo (order_no, date_entered) on oo.order_no = oa.order_no

where 1=1
and oa.date_shipped between @first and @last

-- 4/25/2014 - classify closeouts

update #cvo_sbm_det set isCL = 1
where lsales <> 0  and (1 - (asales-areturns)/lsales) between .8 and .99 

if (object_id('cvo.dbo.cvo_sbm_details') is not null)
	drop table cvo.dbo.cvo_sbm_details


if (object_id('cvo.dbo.cvo_sbm_details') is null)
 begin
 CREATE TABLE [dbo].[cvo_sbm_details]
(
	[customer] [varchar](10) NOT NULL,
	[ship_to] [varchar](10),
	[customer_name] [varchar](40),
	-- new
	[part_no] varchar(30) null,
	[promo_id] varchar(20) null,
	[promo_level] varchar(30) null,
	[return_code] varchar(10) null,
	[user_category] varchar(10) null,
	-- new
	[location] varchar(10) null, 	-- tag 090913
	[c_month] int null, -- 061213 - calendar month
	[c_year] int null,
	[X_MONTH] [int] NULL, -- fiscal month
	[month] [varchar](15) NULL,
	[year] [int] NULL,
	[asales] [float] NULL,
	[areturns] [float] NULL,
	[anet] [float] NULL,
	[qsales] [float] NULL,
	[qreturns] [float] NULL,
	[qnet] [float] NULL,
	[csales] float null,
	[lsales] float null,
	[yyyymmdd] [datetime],
	[DateOrdered] [datetime],
	[orig_return_code] varchar(10), -- for EL 12/10/2013
	[id] int identity, -- 11/8/2013 - for DW
	[isCL] int -- 4/25/2014 - Close out flag
	, [isBO] int
	, [slp] varchar(10)

 ) ON [PRIMARY]
 GRANT SELECT ON [dbo].[cvo_sbm_details] TO [public]

 CREATE CLUSTERED INDEX [pk_sbm_details] ON [dbo].[cvo_sbm_details]
 (
	[id] ASC
 )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]


 CREATE NONCLUSTERED INDEX [idx_cvo_sbm_cust] ON [dbo].[cvo_sbm_details] 
 (
	[Customer] ASC,
	[ship_to] asc,
	[yyyymmdd] asc,
	[dateordered] asc
 ) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]
end

create index idx_cvo_sbm_prod on cvo_sbm_details
( 
part_no asc,
yyyymmdd asc
)

create index idx_cvo_sbm_prod on #cvo_sbm_det
( part_no asc )

create index idx_cvo_sbm_cust_part on cvo_sbm_details
( 
customer asc,
part_no asc
)

CREATE NONCLUSTERED INDEX [idx_sbm_det_for_drp] ON [dbo].[cvo_sbm_details] 
(
	[part_no] ASC,
	[location] ASC,
	[qsales] ASC,
	[qreturns] ASC
)
WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]


CREATE NONCLUSTERED INDEX [idx_sbm_details_amts] 
ON [dbo].[cvo_sbm_details] ([asales],[areturns],[qsales],[qreturns],[lsales])

CREATE NONCLUSTERED INDEX [idx_cvo_sbm_yyyymmdd]
ON [dbo].[cvo_sbm_details] ([yyyymmdd])
INCLUDE ([customer],[ship_to],[part_no],[user_category],[c_month],[c_year],[anet])

--11/17/2015 - for new HS CIR
CREATE NONCLUSTERED INDEX [idx_cvo_sbm_yyyymmdd_cir]
ON [dbo].[cvo_sbm_details] ([yyyymmdd])
INCLUDE ([customer],[ship_to],[part_no],[return_code],[user_category],[qsales],[qreturns],[DateOrdered],[isCL])

-- 8/9/2016 - for r12 net sales 
CREATE NONCLUSTERED INDEX [idx_sbm_details_r12]
ON [dbo].[cvo_sbm_details] ([yyyymmdd])
INCLUDE ([X_MONTH],[anet])

insert cvo_sbm_details
 select 
 customer,
 ship_to,
 ar.address_name customer_name,
 part_no,
 isnull(promo_id,'') promo_id,
 isnull(promo_level,'') promo_level,
 case 
 when return_code like '04%' then 'WTY'
 -- 030514 - tag dont' mark sales as exc returns -- oops
 when return_code not in ('06-13','06-13B','06-27','06-32','') then 'EXC'
 when return_code is null then ''
 else '' END as return_code,
 isnull(user_Category,'ST') as user_category,
 isnull(location,'001') location, -- 090913 tag
 c_month,
 c_year,
 X_MONTH,
 [month],
 [year],
 sum(asales)asales,
 sum(areturns)areturns,
 sum(asales) - sum(areturns) as anet,
 sum(qsales)qsales,
 sum(qreturns)qreturns,
 sum(qsales) - sum(qreturns) as qnet,
 sum(isnull(csales,0)) csales,
 sum(isnull(lsales,0)) lsales,
 DateShipped as yyyymmdd,
 DateOrdered
 , return_code as orig_return_code
 , isCL
 , isBO
 , slp

 from #cvo_sbm_det
 left outer join armaster (nolock) ar  on ar.customer_code = customer and ar.ship_to_code=ship_to
 group by customer, ship_to,  ar.address_Name, part_no,
 promo_id,
 promo_level,
 return_code,
 user_category, location, year, c_year, c_month, X_MONTH, [month], dateshipped
 , dateordered, isCL, isBO, slp

delete from cvo_sbm_details 
where asales = 0 and qsales = 0 and areturns = 0 and qreturns = 0

END


GO
