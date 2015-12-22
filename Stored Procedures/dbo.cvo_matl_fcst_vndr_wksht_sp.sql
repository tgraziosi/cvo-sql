SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_matl_fcst_vndr_wksht_sp] @Vendor varchar(1024) = null

as

-- exec cvo_matl_fcst_vndr_wksht_sp 'counto'

CREATE TABLE #vendor ([vendor] VARCHAR(40),
					  [address_name] varchar(40) )
if @Vendor is null
begin
	insert into #vendor (vendor, address_name)
	select distinct vendor, address_name 
		from inv_master i  (nolock)
		inner join apmaster ap (nolock) on ap.vendor_code = i.vendor where i.void = 'n' 
end
else
begin
	INSERT INTO #vendor ([vendor], address_name)
	SELECT  LISTITEM, address_name
	FROM dbo.f_comma_list_to_table(@vendor)
	inner join apmaster ap on ap.vendor_code = listitem
end

IF(OBJECT_ID('tempdb.dbo.#matlfcst') is not null)  drop table #matlfcst
SELECT -- distinct 
	   i.category brand
	  , ia.field_2 style
  into #matlfcst
  FROM inv_master i (nolock) 
  inner join inv_master_add ia (nolock) On ia.part_no = i.part_no
  inner join #vendor v on v.vendor = i.vendor
  where type_code in ('frame','sun','bruit')
  group by  i.category, ia.field_2

  -- select datediff(dd, '6/15/2015', '7/15/2015')

declare @brand varchar(1000), @style varchar(5000)
select @brand = 
  	  stuff (( select distinct ',' + brand from #matlfcst for xml path('') ),1,1, '' ) 
select @style = 
  	  stuff (( select distinct ',' + style from #matlfcst for xml path('') ),1,1, '' ) 

declare @asofdate datetime, @rankdate datetime -- beginning of ranks
select @asofdate = dateadd(mm,datediff(mm,0,getdate()),0) -- start of this month
select @rankdate = '12/23/2013'

create table #mfcst
( brand varchar(20),
style varchar(40),
vendor varchar(40),
type_code varchar(20),
gender varchar(40),
material varchar(40), 
moq varchar(255),
watch varchar(1), 
rel_date datetime,
pom_date datetime, 
mth_since_rel int, 
mths_left_y2 int,
mths_left_y1 int,
inv_rank varchar(1),
rank_24m_sales decimal(20,0),
rank_12m_sales decimal(20,0),
sales_y2tg decimal(20,0),
sales_y1tg decimal(20,0),
s_sales_m1_3 decimal(20,0),
s_sales_m1_12 decimal(20,0),
s_e4_wu decimal(20,0),
s_e12_wu decimal(20,0),
s_e52_wu decimal(20,0),
line_type varchar(3),
sku varchar(40),
mm int,
p_rel_date datetime,
p_pom_date datetime,
lead_time int,
bucket datetime,
qoh int,
quantity int,
mult decimal(20,8),
sort_seq int,
pct_of_style decimal(20,8),
pct_first_po decimal(20,8),
pct_sales_style_m1_3 decimal(20,8),
p_e4_wu int,
p_e12_wu int,
p_e52_wu int,
s_mth_usg decimal(20,0),
p_mth_usg decimal(20,0),
s_mth_usg_mult decimal(20,8),
sales_y2tg_per_month int,
sales_y1tg_per_month int,
p_sales_y2tg int,
p_sales_y1tg int,
p_po_qty_y1 decimal(20,0)
)

insert into #mfcst
exec cvo_matl_fcst_style_sp @rankdate, @asofdate , 0,1 , @brand, @style


-- epicor
select m.brand, m.style, m.sku, isnull(ia.field_3,'') colorname, m.rel_date, m.pom_date
, sbm.r12ns
, fcst_m1to6 = sum(case when m.sort_seq between 1 and 6 and inv_rank = 'c' and line_type = 'fct' then quantity
				   when m.sort_seq between 1 and 6 and inv_rank <> 'c' and line_type ='drp' then quantity
				       else 0 end)
, fcst_m7to12 = sum(case when m.sort_seq between 7 and 12 and inv_rank = 'c' and line_type = 'fct' then quantity
					when m.sort_seq between 7 and 12 and inv_rank <> 'c' and line_type = 'drp' then quantity
				       else 0 end)
, m.vendor, 'e' as source

into #summary

from #mfcst m
inner join inv_master_add ia (nolock) on ia.part_no = m.sku
inner join #vendor v on v.vendor = m.vendor
left outer join 
(select part_no, sum(qnet) r12ns from cvo_sbm_details 
	where yyyymmdd between dateadd(yy,-1,@asofdate) and @asofdate
	group by part_no
) as sbm on sbm.part_no = m.sku

group by m.brand, m.style, m.sku, ia.field_3, m.rel_date, m.pom_date, sbm.r12ns,
	  m.vendor, m.sort_seq, m.line_type, m.inv_rank

-- union all 
-- cmi only

insert into #summary
select cmi.collection, cmi.model, 'N/A' as sku, isnull(cmi.colorname,'') colorname, cmi.variant_release_date , null as pom_date
,0 as R12ns
, fcst_m1to6 = isnull(cmi.ws_ship1_qty,0) + isnull(cmi.ws_ship2_qty,0) + isnull(cmi.ws_ship3_qty,0)
, fcst_m7to12 = 0
, v.vendor
, 'c' as source
From cvo_cmi_catalog_view cmi
inner join 
#vendor v on v.address_name = cmi.supplier

where not exists 
(select 1 from cvo_inv_master_r2_vw e 
where e.collection = cmi.collection and e.model = cmi.model)

select 
brand, style, sku, colorname, rel_date, pom_date
, isnull(sbm.r12ns,0) r12ns
, sum(isnull(fcst_m1to6,0)) fcst_m1to6
, sum(isnull(fcst_m7to12,0)) fcst_m7to12 
, vendor
, 0 as open_ord_qty, '' as cust_po, '' as ship_to_name
, source
from #summary
left outer join
(select part_no, sum(qnet) r12ns from cvo_sbm_details 
	where yyyymmdd between dateadd(yy,-1,@asofdate) and @asofdate
	group by part_no
) as sbm on sbm.part_no = #summary.sku

group by vendor, brand, style, sku, colorname, rel_date, pom_date, sbm.r12ns, source

union all
-- get Large Accounts info not forecasted
select brand, style, c.part_no sku , ia.field_3 colorname, ia.field_26 rel_date, ia.field_28 pom_date,
sbm.r12ns, 0 as fcst_m1to6, 0 as fcst_m7to12
, i.vendor
, open_ord_qty, cust_po, ship_to_name
, 'L' as source
From cvo_open_order_detail_vw c 
inner join inv_master i on i.part_no = c.part_no
inner join inv_master_add ia on ia.part_no = c.part_no
inner join #vendor v on v.vendor = i.vendor 
left outer join
(select part_no, sum(qnet) r12ns from cvo_sbm_details 
	where yyyymmdd between dateadd(yy,-1,@asofdate) and @asofdate
	group by part_no
) as sbm on sbm.part_no = c.part_no
where cust_code in ('045733','019482','045217')
and restype in ('frame','sun','bruit')

GO
