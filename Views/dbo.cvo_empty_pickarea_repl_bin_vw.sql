SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[cvo_empty_pickarea_repl_bin_vw] as
SELECT     dbo.tdc_bin_replenishment.bin_no, dbo.tdc_bin_replenishment.part_no, 
					dbo.tdc_bin_replenishment.replenish_min_lvl, 
                    ISNULL(SUM(lot_bin_stock_1.qty), 0) AS repl_bin_qty, 
					--SUM(ISNULL (lot_bin_stock_1.qty,0)) AS stock_qty, 
					dbo.tdc_bin_replenishment.replenish_qty,
					dbo.tdc_bin_master.group_code
FROM         dbo.tdc_bin_replenishment LEFT OUTER JOIN
                      dbo.tdc_bin_master ON dbo.tdc_bin_replenishment.bin_no = dbo.tdc_bin_master.bin_no LEFT OUTER JOIN
                      dbo.lot_bin_stock AS lot_bin_stock_1 ON dbo.tdc_bin_replenishment.bin_no = lot_bin_stock_1.bin_no AND 
                      dbo.tdc_bin_replenishment.part_no = lot_bin_stock_1.part_no
GROUP BY dbo.tdc_bin_replenishment.bin_no, dbo.tdc_bin_replenishment.part_no, dbo.tdc_bin_replenishment.replenish_min_lvl, 
                      dbo.tdc_bin_master.group_code, dbo.tdc_bin_replenishment.replenish_qty
HAVING      (ISNULL(SUM(lot_bin_stock_1.qty), 0) = 0) AND (dbo.tdc_bin_master.group_code = 'PICKAREA')



GO
GRANT REFERENCES ON  [dbo].[cvo_empty_pickarea_repl_bin_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_empty_pickarea_repl_bin_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_empty_pickarea_repl_bin_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_empty_pickarea_repl_bin_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_empty_pickarea_repl_bin_vw] TO [public]
GO
