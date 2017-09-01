SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[cvo_bin_alloc_analysis_vw] AS 
-- select * from [cvo_bin_alloc_analysis_vw]
SELECT 
a.part_no,
c.description, 
c.type_code,
ISNULL(CONVERT(VARCHAR(12),ia.field_28,101),'Current') AS pom_date,
e.group_code,
e.usage_type_code,
a.bin_no, 
a.numallocs,
CAST(a.qty AS DECIMAL(10,0)) AS allocated,
CAST(ISNULL(d.qty,0) AS DECIMAL(10,0)) AS bin_qty,
CASE WHEN d.qty = 0 OR d.qty IS NULL THEN 0 ELSE CAST(ROUND((a.qty/d.qty)*100,0) AS DECIMAL(10,0))  END AS pct_alloc,
e.maximum_level max_lvl,
CASE WHEN e.maximum_level = 0 THEN 0 ELSE CAST((a.qty/e.maximum_level*100) AS INTEGER) END AS pct_max,
CASE WHEN e.maximum_level = 0 THEN 0 ELSE CAST((d.qty/e.maximum_level*100) AS INTEGER) END AS pct_bin_full,
ISNULL((SELECT SUM(aa.qty) qty FROM tdc_soft_alloc_tbl (NOLOCK) aa WHERE aa.location = a.location AND aa.part_no = a.part_no AND aa.order_no = 0), 0) open_replen_qty,
ISNULL(hb.bin_no,'') hb_bin_no,
ISNULL(hb.qty,0) hb_qty,
ISNULL(W.QTY,0) w_qty,
(SELECT TOP 1 CONVERT(VARCHAR(12), date_tran, 101) FROM lot_bin_tran WHERE direction = 1 AND tran_code = 'I' AND location = a.location AND part_no = a.part_no AND bin_no = a.bin_no
 ORDER BY date_tran DESC) AS last_trn_date,
 (SELECT TOP 1 qty FROM lot_bin_tran WHERE direction = 1 AND tran_code = 'I' AND location = a.location AND part_no = a.part_no AND bin_no = a.bin_no
 ORDER BY date_tran DESC) AS last_trn_in,
drp.e4_wu,
-- (select top 1 isnull(e4_wu,0) from drp where part_no = a.part_no and location = a.location) as e4_wu, 
ISNULL(br.replenish_min_lvl,0) replen_min,
ISNULL(br.replenish_max_lvl,0) replen_max,
ISNULL(br.replenish_qty,0) replen_qty,
ISNULL(br.auto_replen,0) auto_replen


FROM 
(SELECT part_no, location, bin_no, SUM(ISNULL(qty,0)) qty, COUNT(qty) numallocs FROM tdc_soft_alloc_tbl (NOLOCK) 
  WHERE location = '001' AND (order_no <>0 OR (order_no = 0 AND dest_bin = 'CUSTOM'))
  GROUP BY part_no, location, bin_no) a 
INNER JOIN inv_master c (NOLOCK) ON a.part_no = c.part_no 
INNER JOIN inv_master_add ia (NOLOCK) ON a.part_no = ia.part_no
INNER JOIN tdc_bin_master e (NOLOCK) ON a.bin_no = e.bin_no AND a.location = e.location
LEFT OUTER JOIN lot_bin_stock d (NOLOCK) ON a.part_no = d.part_no AND a.bin_no = d.bin_no AND a.location = d.location
LEFT OUTER JOIN tdc_bin_replenishment br (NOLOCK) ON a.part_no = br.part_no AND a.bin_no = br.bin_no AND a.location = br.location
LEFT OUTER JOIN
(SELECT bp.location, bp.part_no, bp.bin_no, SUM(ISNULL(lb.qty,0)) qty FROM tdc_bin_part_qty bp (NOLOCK) 
  INNER JOIN tdc_bin_master bm (NOLOCK) ON bp.location = bm.location AND bp.bin_no = bm.bin_no 
  LEFT OUTER JOIN lot_bin_stock lb (NOLOCK) ON bp.location = lb.location AND bp.bin_no = lb.bin_no AND bp.part_no = lb.part_no
  WHERE group_code = 'HIGHBAY'
  GROUP BY bp.location, bp.part_no, bp.bin_no) hb 
ON hb.part_no = a.part_no AND hb.location = a.location

-- add whse qty

LEFT OUTER JOIN
(SELECT lb.location, lb.part_no, SUM(ISNULL(lb.qty,0)) qty FROM 
  lot_bin_stock lb (NOLOCK)  
  LEFT OUTER JOIN tdc_bin_master bm (NOLOCK) ON BM.location = lb.location AND BM.bin_no =lb.bin_no
  WHERE BM.group_code = 'BULK' AND bm.usage_type_code IN ('replenish','open')
  GROUP BY lb.location, lb.part_no) w 
ON W.part_no = a.part_no AND W.location = a.location

LEFT OUTER JOIN
( SELECT part_no, e4_wu FROM dbo.f_cvo_calc_weekly_usage_coll('o',null) AS fccwu
	WHERE fccwu.location = '001' ) drp ON drp.part_no = a.part_no

WHERE  1=1
AND e.group_code = 'PICKAREA' AND E.USAGE_TYPE_CODE = 'REPLENISH'
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
