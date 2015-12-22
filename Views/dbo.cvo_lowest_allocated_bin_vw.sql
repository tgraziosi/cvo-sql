SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			cvo_lowest_allocated_bin_vw.sql
Type:			View
Called From:	Enterprise
Description:	Returns lowest bin number allocated per order/transfer
Developer:		Chris Tyler
Date:			28th March 2013

Revision History
*/

CREATE VIEW [dbo].[cvo_lowest_allocated_bin_vw]
AS

SELECT 
	order_no,
	order_ext, 
	order_type,
	MIN(bin_no) bin_no
FROM
	tdc_soft_alloc_tbl
WHERE
	order_no <> 0
	AND ISNULL(bin_no, '') <> ''
GROUP BY
	order_no,
	order_ext, 
	order_type

GO
GRANT SELECT ON  [dbo].[cvo_lowest_allocated_bin_vw] TO [public]
GO
