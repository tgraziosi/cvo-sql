SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			cvo_hard_allocated_vw.sql
Type:			View
Called From:	Enterprise
Description:	Returns qty of order/transfer line that is hard allocated
Developer:		Chris Tyler
Date:			28th March 2013

Revision History
*/

CREATE VIEW [dbo].[cvo_hard_allocated_vw]
AS

SELECT 
	order_no,
	order_ext, 
	line_no,
	order_type,
	SUM(qty) AS qty
FROM
	tdc_soft_alloc_tbl
WHERE
	order_no <> 0
GROUP BY
	order_no,
	order_ext, 
	line_no,
	order_type

GO
GRANT SELECT ON  [dbo].[cvo_hard_allocated_vw] TO [public]
GO
