SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_inv_fcst_moved_po_sp]  @DateFrom DATETIME  , @DaysThresh int = 7, @BOThresh int = -50

as

-- exec cvo_inv_fcst_moved_po_sp '08/01/2017' 

-- 021815 - tag - only call out items where the shipment is not yet intransit
-- 030615 -- incorporate new line level packing list setting
-- 081816 -- tag - fix po date logic
-- 111816 - tag - fix for when there multiple po changes for the same style with different dates.  pick the latest change.

SET NOCOUNT ON

declare @fromdate datetime, @days int, @bo_thresh int
--select @fromdate = DATEADD(DAY,DATEDIFF(DAY,0,GETDATE()), -1) -- @DateFrom - yesterday

--DECLARE @datefrom DATETIME, @daysthresh INT, @bothresh INT
--SELECT @datefrom = '11/9/2016'
--select @daysthresh = 7 -- @DaysThresh
--select @bothresh = -50 -- @BOThresh

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
(
    brand VARCHAR(10),
    style VARCHAR(40),
    vendor VARCHAR(12),
    type_code VARCHAR(10),
    gender VARCHAR(15),
    material VARCHAR(40),
    moq VARCHAR(255),
    watch VARCHAR(15),
    sf VARCHAR(40),
    rel_date DATETIME,
    pom_date DATETIME,
    mth_since_rel INT,
    s_sales_m1_3 FLOAT(8),
    s_sales_m1_12 FLOAT(8),
    s_e4_wu INT,
    s_e12_wu INT,
    s_e52_wu INT,
    s_promo_w4 INT,
    s_promo_w12 INT,
    s_gross_w4 INT,
    s_gross_w12 INT,
    LINE_TYPE VARCHAR(3),
    sku VARCHAR(30),
    location VARCHAR(12),
    mm INT,
    p_rel_date DATETIME,
    p_pom_date DATETIME,
    lead_time INT,
    bucket DATETIME,
    QOH INT,
    atp INT,
    reserve_qty INT,
    quantity INT,
    mult DECIMAL(20, 8),
    s_mult DECIMAL(20, 8),
    sort_seq INT,
    alloc_qty INT,
    non_alloc_qty INT,
    pct_of_style DECIMAL(37, 19),
    pct_first_po FLOAT(8),
    pct_sales_style_m1_3 FLOAT(8),
    p_e4_wu INT,
    p_e12_wu INT,
    p_e52_wu INT,
    p_subs_w4 INT,
    p_subs_w12 INT,
    s_mth_usg INT,
    p_mth_usg INT,
    s_mth_usg_mult DECIMAL(31, 8),
    p_sales_m1_3 INT,
    p_po_qty_y1 DECIMAL(38, 8),
    ORDER_THRU_DATE DATETIME,
    TIER VARCHAR(1),
    p_type_code VARCHAR(10),
    s_rx_w4 INT,
    s_rx_w12 INT,
    p_rx_w4 INT,
    p_rx_w12 INT,
    s_ret_w4 INT,
    s_ret_w12 INT,
    p_ret_w4 INT,
    p_ret_w12 INT,
    s_wty_w4 INT,
    s_wty_w12 INT,
    p_wty_w4 INT,
    p_wty_w12 INT,
    p_gross_w4 INT,
    p_gross_w12 INT,
    price DECIMAL(20, 8),
    frame_type VARCHAR(40)

)

insert into #mpo
-- exec cvo_matl_fcst_style_sp 
EXEC dbo.cvo_inv_fcst_r3_sp

	@asofdate = @asofdate 
	, @endrel = @asofdate
	, @location = '001'
	, @current = 0 
	, @collection = @brand
	, @Style = @style
	, @spread = 'CORE'
	, @ResType = 'frame,sun,bruit'


--SELECT @brand, @style
--SELECT * FROM #mpo


IF(OBJECT_ID('tempdb.dbo.#mfcst') is not null)  drop table #mfcst

SELECT date_field_from ,
       date_field_to ,
       #matlfcst.brand ,
       #matlfcst.style ,
       po_no 
INTO #mfcst
FROM #matlfcst 
JOIN
(
SELECT MAX(date_FIEld_to) max_date, brand, style 
FROM #matlfcst 
GROUP BY brand, style
) max_date ON max_date.brand = #matlfcst.brand 
AND max_date.style = #matlfcst.style 
AND max_date.max_date = #matlfcst.date_field_to


select #mpo.brand,
       #mpo.style,
       #mpo.vendor,
       #mpo.type_code,
       #mpo.gender,
       #mpo.material,
       #mpo.moq,
       #mpo.watch,
       #mpo.sf,
       #mpo.rel_date,
       #mpo.pom_date,
       #mpo.mth_since_rel,
       #mpo.s_sales_m1_3,
       #mpo.s_sales_m1_12,
       #mpo.s_e4_wu,
       #mpo.s_e12_wu,
       #mpo.s_e52_wu,
       #mpo.s_promo_w4,
       #mpo.s_promo_w12,
       #mpo.s_gross_w4,
       #mpo.s_gross_w12,
       #mpo.LINE_TYPE,
       #mpo.sku,
       #mpo.location,
       #mpo.mm,
       #mpo.p_rel_date,
       #mpo.p_pom_date,
       #mpo.lead_time,
       #mpo.bucket,
       #mpo.QOH,
       #mpo.atp,
       #mpo.reserve_qty,
       #mpo.quantity,
       #mpo.mult,
       #mpo.s_mult,
       #mpo.sort_seq,
       #mpo.alloc_qty,
       #mpo.non_alloc_qty,
       #mpo.pct_of_style,
       #mpo.pct_first_po,
       #mpo.pct_sales_style_m1_3,
       #mpo.p_e4_wu,
       #mpo.p_e12_wu,
       #mpo.p_e52_wu,
       #mpo.p_subs_w4,
       #mpo.p_subs_w12,
       #mpo.s_mth_usg,
       #mpo.p_mth_usg,
       #mpo.s_mth_usg_mult,
       #mpo.p_sales_m1_3,
       #mpo.p_po_qty_y1,
       #mpo.ORDER_THRU_DATE,
       #mpo.TIER,
       #mpo.p_type_code,
       #mpo.s_rx_w4,
       #mpo.s_rx_w12,
       #mpo.p_rx_w4,
       #mpo.p_rx_w12,
       #mpo.s_ret_w4,
       #mpo.s_ret_w12,
       #mpo.p_ret_w4,
       #mpo.p_ret_w12,
       #mpo.s_wty_w4,
       #mpo.s_wty_w12,
       #mpo.p_wty_w4,
       #mpo.p_wty_w12,
       #mpo.p_gross_w4,
       #mpo.p_gross_w12,
       #mpo.price,
       #mpo.frame_type,
m.po_no, m.date_field_from date_from, m.date_field_to date_to
From #mpo
inner join 
(
select distinct #mpo.brand, #mpo.style 
FROM #mpo 
inner join #mfcst m on m.brand = #mpo.brand and m.style = #mpo.style
where line_type = 'V' and quantity < @bo_thresh
and #mpo.bucket between dateadd(mm,datediff(mm, 0, m.date_field_from), 0) and 
						dateadd(mm,datediff(mm, 0, m.date_field_to), 0)
) 
as x on x.brand = #mpo.brand and x.style = #mpo.style
left outer join #mfcst m on m.brand = #mpo.brand and m.style = #mpo.style





GO
GRANT EXECUTE ON  [dbo].[cvo_inv_fcst_moved_po_sp] TO [public]
GO
