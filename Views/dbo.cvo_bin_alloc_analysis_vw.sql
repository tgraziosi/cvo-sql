SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[cvo_bin_alloc_analysis_vw] as 
-- select * from [cvo_bin_alloc_analysis_vw]
Select 
a.part_no,
c.description, 
c.type_code,
isnull(convert(varchar(12),ia.field_28,101),'Current') as pom_date,
e.group_code,
e.usage_type_code,
a.bin_no, 
a.numallocs,
cast(a.qty as decimal(10,0)) as allocated,
cast(isnull(d.qty,0) as decimal(10,0)) as bin_qty,
case when d.qty = 0 or d.qty is null then 0 else cast(round((a.qty/d.qty)*100,0) as decimal(10,0))  end as pct_alloc,
e.maximum_level max_lvl,
case when e.maximum_level = 0 then 0 else cast((a.qty/e.maximum_level*100) as integer) end as pct_max,
case when e.maximum_level = 0 then 0 else cast((d.qty/e.maximum_level*100) as integer) end as pct_bin_full,
isnull((select sum(aa.qty) qty from tdc_soft_alloc_tbl (nolock) aa where aa.location = a.location and aa.part_no = a.part_no and aa.order_no = 0), 0) open_replen_qty,
ISNULL(hb.bin_no,'') hb_bin_no,
isnull(hb.qty,0) hb_qty,
ISNULL(W.QTY,0) w_qty,
(select top 1 convert(varchar(12), date_tran, 101) From lot_bin_tran where direction = 1 and tran_code = 'I' and location = a.location and part_no = a.part_no and bin_no = a.bin_no
 order by date_tran desc) as last_trn_date,
 (select top 1 qty From lot_bin_tran where direction = 1 and tran_code = 'I' and location = a.location and part_no = a.part_no and bin_no = a.bin_no
 order by date_tran desc) as last_trn_in,
(select top 1 isnull(e4_wu,0) from dpr_report where part_no = a.part_no and location = a.location) as e4_wu, 
isnull(br.replenish_min_lvl,0) replen_min,
isnull(br.replenish_max_lvl,0) replen_max,
isnull(br.replenish_qty,0) replen_qty,
isnull(br.auto_replen,0) auto_replen


from 
(select part_no, location, bin_no, SUM(ISNULL(qty,0)) qty, count(qty) numallocs from tdc_soft_alloc_tbl (nolock) 
  where location = '001' and (order_no <>0 OR (order_no = 0 and dest_bin = 'CUSTOM'))
  group by part_no, location, bin_no) a 
inner join inv_master c (nolock) on a.part_no = c.part_no 
inner join inv_master_add ia (nolock) on a.part_no = ia.part_no
inner join tdc_bin_master e (nolock) on a.bin_no = e.bin_no and a.location = e.location
left outer join lot_bin_stock d (nolock) on a.part_no = d.part_no and a.bin_no = d.bin_no and a.location = d.location
left outer join tdc_bin_replenishment br (nolock) on a.part_no = br.part_no and a.bin_no = br.bin_no and a.location = br.location
LEFT OUTER JOIN
(select bp.location, bp.part_no, bp.bin_no, sum(isnull(lb.qty,0)) qty from tdc_bin_part_qty bp (nolock) 
  inner join tdc_bin_master bm (nolock) on bp.location = bm.location and bp.bin_no = bm.bin_no 
  LEFT OUTER join lot_bin_stock lb (nolock) on bp.location = lb.location and bp.bin_no = lb.bin_no and bp.part_no = lb.part_no
  where group_code = 'HIGHBAY'
  group by bp.location, bp.part_no, bp.bin_no) hb 
on hb.part_no = a.part_no and hb.location = a.location

-- add whse qty

LEFT OUTER JOIN
(select lb.location, lb.part_no, sum(isnull(lb.qty,0)) qty from 
  lot_bin_stock lb (nolock)  
  LEFT OUTER join tdc_bin_master bm (nolock) on BM.location = lb.location and BM.bin_no =lb.bin_no
  where BM.group_code = 'BULK' and bm.usage_type_code in ('replenish','open')
  group by lb.location, lb.part_no) w 
on W.part_no = a.part_no and W.location = a.location

where  1=1
and e.group_code = 'PICKAREA' AND E.USAGE_TYPE_CODE = 'REPLENISH'
--order by PCT_ALLOC DESC, a.part_no ASC


GO
GRANT REFERENCES ON  [dbo].[cvo_bin_alloc_analysis_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_bin_alloc_analysis_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_bin_alloc_analysis_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_bin_alloc_analysis_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_bin_alloc_analysis_vw] TO [public]
GO
