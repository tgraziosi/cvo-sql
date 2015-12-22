SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			cvo_hold_credit_return_vw.sql
Type:			View
Called From:	Explorer
Description:	Returns details of credit returns on hold
Developer:		Chris Tyler
Date:			16th October 2012
-- select * from cvo_hold_credit_return_vw
Revision History
*/

CREATE VIEW [dbo].[cvo_hold_credit_return_vw]
AS
SELECT
	o.cust_code,
	c.customer_name,
	o.order_no,
	o.ext,
	o.date_entered,
	o.who_entered,
	o.salesperson,
	o.total_amt_order,
	o.hold_reason,
	o.note,
	x_date_entered = ((datediff(day, '01/01/1900', o.date_entered) + 693596)) + (datepart(hh,o.date_entered)*.01 + datepart(mi,o.date_entered)*.0001 + datepart(ss,o.date_entered)*.000001)
FROM
	dbo.orders_all o (NOLOCK) 
INNER JOIN
	dbo.arcust c (NOLOCK)
ON
	o.cust_code = c.customer_code
WHERE
	o.[type] = 'C'
	AND o.status = 'A'

GO
GRANT SELECT ON  [dbo].[cvo_hold_credit_return_vw] TO [public]
GO
