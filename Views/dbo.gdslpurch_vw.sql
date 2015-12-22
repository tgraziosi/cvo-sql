SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[gdslpurch_vw]
AS
SELECT     dbo.lot_bin_recv.part_no, dbo.lot_bin_recv.qty, dbo.lot_bin_recv.uom, dbo.lot_bin_recv.lot_ser, dbo.lot_bin_recv.cost, dbo.lot_bin_recv.date_tran, 
                      dbo.lot_bin_recv.tran_no AS Receipt_no, receipts_all.po_no AS PO, receipts_all.vendor, dbo.lot_bin_recv.location
FROM         dbo.lot_bin_recv LEFT OUTER JOIN
                      receipts_all ON dbo.lot_bin_recv.part_no = receipts_all.part_no AND dbo.lot_bin_recv.tran_no = receipts_all.receipt_no  
GO
GRANT REFERENCES ON  [dbo].[gdslpurch_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[gdslpurch_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gdslpurch_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gdslpurch_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gdslpurch_vw] TO [public]
GO
