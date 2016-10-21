SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_matl_fcst_moved_po_sp]  @DateFrom DATETIME  , @DaysThresh int = 7, @BOThresh int = -50

as

-- exec cvo_matl_fcst_moved_po_sp '08/17/2016' 

-- 021815 - tag - only call out items where the shipment is not yet intransit
-- 030615 -- incorporate new line level packing list setting
-- 081816 -- tag - fix po date logic

SET NOCOUNT ON

declare @fromdate datetime, @days int, @bo_thresh int
--select @fromdate = DATEADD(DAY,DATEDIFF(DAY,0,GETDATE()), -1) -- @DateFrom - yesterday
--select @days = 7 -- @DaysThresh
--select @bo_thresh = -50 -- @BOThresh

select @fromdate = @DateFrom -- yesterday
select @days =  @DaysThresh
select @bo_thresh =  @BOThresh

IF(OBJECT_ID('tempdb.dbo.#matlfcst') is not null)  drop table #matlfcst
  SELECT distinct po_a.date_field_from -- 9/23/2016 add distinct so that po's with multiple line entries don't report.  don't need them
	  , po_a.date_field_to
	  , i.category brand
	  , ia.field_2 style
	  , po_a.po_no
  INTO #matlfcst
  FROM 
   (SELECT pa.po_no,
		 MIN(CAST(field_from AS DATETIME)) date_field_from,
		 MIN(CAST(field_to AS datetime)) date_field_to 
  FROM dbo.CVO_PO_AUDIT AS pa
  JOIN dbo.purchase_all AS p ON p.po_no = pa.po_no
  WHERE pa.field_name = 'inhouse_date' 
  AND pa.modified_date >= @fromdate
  and ( p.expedite_flag = 0 ) -- 021815
  GROUP BY pa.po_no
  having DATEDIFF(dd,MIN(CAST(field_from AS DATETIME)), MIN(CAST(field_to AS DATETIME))) > @Days
  ) AS po_a
  inner join releases r (nolock) on r.po_no = po_a.po_no
  inner join pur_list pl (nolock) on pl.po_no = r.po_no and pl.part_no = r.part_no and pl.line=r.po_line
  inner join purchase p (nolock) on r.po_no = p.po_no -- 021815
  inner join inv_master i (nolock) on i.part_no = r.part_no 
  inner join inv_master_add ia (nolock) On ia.part_no = i.part_no
  and type_code in ('frame','sun','bruit')
  and ( pl.plrecd = 0 ) -- 021815
  and r.location = '001' -- 031215 - qualify on location



  -- select datediff(dd, '6/15/2015', '7/15/2015')
-- SELECT * FROM #matlfcst

declare @brand varchar(1000), @style varchar(5000)
select @brand = 
  	  stuff (( select distinct ',' + brand from #matlfcst for xml path('') ),1,1, '' ) 
select @style = 
  	  stuff (( select distinct ',' + style from #matlfcst for xml path('') ),1,1, '' ) 

-- SELECT @brand, @style

declare @asofdate datetime, @rankdate datetime -- beginning of ranks
select @asofdate = dateadd(mm,datediff(mm,0,getdate()),0) -- start of this month
select @rankdate = '12/23/2013'

IF(OBJECT_ID('tempdb.dbo.#mpo') is not null)  drop table #mpo

create table #mpo
( brand varchar(20),
style varchar(40),
vendor varchar(40),
type_code varchar(20),
gender varchar(40),
material varchar(40), 
moq varchar(255),
watch varchar(1), 
sf VARCHAR(30),
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
-- 1/12/16
s_promo_w4 DECIMAL(20,0),
s_promo_w12 DECIMAL(20,0),
line_type varchar(3),
sku varchar(40),
mm int,
p_rel_date datetime,
p_pom_date datetime,
lead_time int,
bucket datetime,
qoh int,
atp INT,
quantity int,
mult decimal(20,8),
s_mult DECIMAL(20,8),
sort_seq int,
pct_of_style decimal(20,8),
pct_first_po decimal(20,8),
pct_sales_style_m1_3 decimal(20,8),
p_e4_wu int,
p_e12_wu int,
p_e52_wu int,
p_subs_w4 INT,
p_subs_w12 INT,
s_mth_usg decimal(20,0),
p_mth_usg decimal(20,0),
s_mth_usg_mult decimal(20,8),
sales_y2tg_per_month int,
sales_y1tg_per_month int,
p_sales_y2tg int,
p_sales_y1tg int,
p_po_qty_y1 decimal(20,0)
)

insert into #mpo
-- exec cvo_matl_fcst_style_sp 
exec cvo_matl_fcst_style_season_sp 

	@startrank = @rankdate
	, @asofdate = @asofdate 
	, @endrel = @asofdate
	, @UseDrp = 1
	, @current = 0 
	, @collection = @brand
	, @Style = @style


--SELECT @brand, @style
--SELECT * FROM #mpo

select #mpo.*,
m.po_no, m.date_field_from date_from, m.date_field_to date_to
From #mpo
inner join 
(
select distinct #mpo.brand, #mpo.style from #mpo 
inner join #matlfcst m on m.brand = #mpo.brand and m.style = #mpo.style
where line_type = 'V' and quantity < @bo_thresh
and #mpo.bucket between dateadd(mm,datediff(mm, 0, m.date_field_from), 0) and 
						dateadd(mm,datediff(mm, 0, m.date_field_to), 0)
) 
as x on x.brand = #mpo.brand and x.style = #mpo.style
left outer join #matlfcst m on m.brand = #mpo.brand and m.style = #mpo.style



GO
