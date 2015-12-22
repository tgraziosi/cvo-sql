SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			cvo_masterpack_consolidated_order_lines_vw.sql
Type:			View
Description:	Returns parts on consolidated orders
Developer:		Chris Tyler
Date:			8th April 2014

Revision History
*/

CREATE VIEW [dbo].[cvo_masterpack_consolidated_order_lines_vw]
AS

	SELECT
		b.consolidation_no,
		a.part_no,
		a.location,
		a.part_type,
		a.uom,
		a.[description],
		'' item_note,
		SUM(ordered) ord_qty
	FROM
		dbo.ord_list a (NOLOCK)
	INNER JOIN
		dbo.cvo_masterpack_consolidation_det b (NOLOCK)
	ON
		a.order_no = b.order_no
		AND a.order_ext = b.order_ext
	GROUP BY
		b.consolidation_no,
		a.part_no,
		a.location,
		a.part_type,
		a.uom,
		a.[description]
GO
GRANT SELECT ON  [dbo].[cvo_masterpack_consolidated_order_lines_vw] TO [public]
GO
