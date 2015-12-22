SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			cvo_backorder_processing_po_qty_vw.sql
Type:			View
Called From:	Enterprise
Description:	returns qty from PO line that is assigned to via backorder processing
Developer:		Chris Tyler
Date:			27th March 2013

Revision History
*/

CREATE VIEW [dbo].[cvo_backorder_processing_po_qty_vw]
AS


SELECT 
	po_no,
	po_line,
	releases_row_id,
	SUM(qty_ringfenced - qty_received) as qty
FROM 
	dbo.CVO_backorder_processing_orders_po_xref
WHERE
	qty_reqd - qty_received > 0
GROUP BY
	po_no,
	po_line,
	releases_row_id

GO
GRANT SELECT ON  [dbo].[cvo_backorder_processing_po_qty_vw] TO [public]
GO
