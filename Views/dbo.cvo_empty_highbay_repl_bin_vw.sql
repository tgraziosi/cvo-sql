SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[cvo_empty_highbay_repl_bin_vw] as
SELECT     dbo.CVO_bin_replenishment_tbl.bin_no, dbo.CVO_bin_replenishment_tbl.part_no, 
					dbo.CVO_bin_replenishment_tbl.min_qty, 
                    ISNULL(SUM(lot_bin_stock_1.qty), 0) AS repl_bin_qty, 
					--SUM(ISNULL (lot_bin_stock_1.qty,0)) AS stock_qty, 
					dbo.CVO_bin_replenishment_tbl.rep_qty,
					dbo.tdc_bin_master.group_code
FROM         dbo.CVO_bin_replenishment_tbl LEFT OUTER JOIN
                      dbo.tdc_bin_master ON dbo.CVO_bin_replenishment_tbl.bin_no = dbo.tdc_bin_master.bin_no LEFT OUTER JOIN
                      dbo.lot_bin_stock AS lot_bin_stock_1 ON dbo.CVO_bin_replenishment_tbl.bin_no = lot_bin_stock_1.bin_no AND 
                      dbo.CVO_bin_replenishment_tbl.part_no = lot_bin_stock_1.part_no
GROUP BY dbo.CVO_bin_replenishment_tbl.bin_no, dbo.CVO_bin_replenishment_tbl.part_no, dbo.CVO_bin_replenishment_tbl.min_qty, 
                      dbo.tdc_bin_master.group_code, dbo.CVO_bin_replenishment_tbl.rep_qty
HAVING      (ISNULL(SUM(lot_bin_stock_1.qty), 0) = 0) AND (dbo.tdc_bin_master.group_code = 'highbay')

GO
GRANT REFERENCES ON  [dbo].[cvo_empty_highbay_repl_bin_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_empty_highbay_repl_bin_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_empty_highbay_repl_bin_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_empty_highbay_repl_bin_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_empty_highbay_repl_bin_vw] TO [public]
GO
