SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			CVO_backorder_processing_allocation_issues_vw.sql
Type:			View
Called From:	Enterprise
Description:	Returns orders which failed to fully allocate during backorder processing
Developer:		Chris Tyler
Date:			28th November 2013

Revision History
*/

CREATE VIEW [dbo].[CVO_backorder_processing_allocation_issues_vw]
AS


SELECT 
	template_code, 
	order_no,
	ext,
	is_transfer,
	line_no,
	location,
	part_no,
	qty_reqd,
	qty_allocated,
	rec_date
FROM 
	dbo.CVO_backorder_processing_allocation_issues

GO
GRANT SELECT ON  [dbo].[CVO_backorder_processing_allocation_issues_vw] TO [public]
GO
