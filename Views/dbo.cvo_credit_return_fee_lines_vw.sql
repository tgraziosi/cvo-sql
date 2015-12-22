SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:			cvo_credit_return_fee_lines_vw.sql
Type:			View
Called From:	Enterprise
Description:	Returns fee lines on credit returns
Developer:		Chris Tyler
Date:			21st March 2013

Revision History
*/

CREATE VIEW [dbo].[cvo_credit_return_fee_lines_vw]
AS

SELECT
	'CRM' + RIGHT('0000000' + CAST(a.invoice_no AS VARCHAR(7)),7) AS doc_ctrl_num,
	a.order_no,
	a.ext,
	c.line_no,
	ABS(ROUND((c.curr_price * c.cr_shipped),2)) AS Fee,
	c.part_no
FROM
	dbo.cvo_orders_all b (NOLOCK)
INNER JOIN
	dbo.orders_all a (NOLOCK)
ON
	a.order_no = b.order_no
	AND a.ext = b.ext
	AND ISNULL(b.fee_line,0) <> 0
INNER JOIN
	ord_list c (NOLOCK)
ON	
	b.order_no = c.order_no
	AND b.ext = c.order_ext
	AND b.fee_line = c.line_no
WHERE
	a.type = 'C'
	AND ISNULL(b.fee_line,0) <> 0


GO
GRANT SELECT ON  [dbo].[cvo_credit_return_fee_lines_vw] TO [public]
GO
