SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			cvo_order_line_sales_vw.sql
Type:			View
Called From:	CVO_verify_customer_quali_sp
Description:	Returns order line sales amounts and brand/category of part
Developer:		Chris Tyler
Date:			13th July 2011

Revision History
v1.0	CT	13/07/11	Original version
v1.1	CT	10/08/11	Include order details from cvo_ord_list_hist
v1.2	CT	24/08/11	cvo_ord_list_hist.order_no is now an INT (was VARCHAR)
v1.3	CB	11/09/12	Fix issue - credits not calculated correctly and should be using shipped quantities
v1.4	CT	06/02/13	Add Gender
v1.5	CT	06/02/13	Add Piece_qty
v1.6	CT	06/02/13	Add Attribute (specialty fit)
v1.7	CT	07/02/13	Fix to identifying credit return lines in cvo_ord_list_hist - data is incorrect so needs workaround
*/

CREATE VIEW [dbo].[cvo_order_line_sales_vw]
AS

SELECT 
	a.order_no,
	a.order_ext,
	a.line_no, 
	a.part_no, 
-- v1.3	(a.price - ISNULL(b.amt_disc,0)) * a.ordered line_amt,
	CASE WHEN a.ordered = 0 THEN (((a.price - ISNULL(b.amt_disc,0)) * a.cr_shipped) * -1) ELSE ((a.price - ISNULL(b.amt_disc,0)) * a.shipped) END line_amt, -- v1.3
	c.category brand,
	c.type_code category,
	0 historic,	-- v1.1
	CAST(a.order_no AS varchar(20)) order_no_text, -- v1.1
	ISNULL(d.category_2,'') gender,	-- v1.4
	ISNULL(d.field_32,'') attribute,	-- v1.6
	-- START v1.5
	CASE c.type_code WHEN 'FRAME' THEN (CASE a.ordered WHEN 0 THEN a.cr_shipped * -1 ELSE a.shipped END)  
					 WHEN 'SUN' THEN (CASE a.ordered WHEN 0 THEN a.cr_shipped * -1 ELSE a.shipped END)
					 ELSE 0 END piece_qty 
	-- END v1.5
FROM 
	dbo.ord_list a (NOLOCK)
INNER JOIN 
	dbo.cvo_ord_list b (NOLOCK)
ON 
	a.order_no = b.order_no 
	and a.order_ext = b.order_ext 
	and a.line_no = b.line_no  
LEFT JOIN
	dbo.inv_master c (NOLOCK)
ON
	a.part_no = c.part_no
-- START v1.4
LEFT JOIN
	dbo.inv_master_add d (NOLOCK)
ON
	c.part_no = d.part_no
-- END v1.4
-- START v1.1
UNION
SELECT 
	--CAST('-' + SUBSTRING(a.order_no,3,(LEN(a.order_no) - 2)) AS INT) order_no,
	a.order_no,		-- v1.2
	a.order_ext,
	a.line_no, 
	a.part_no, 
-- v1.3	a.price * a.ordered line_amt,
	-- START v1.7
	CASE WHEN ISNULL(a.cr_shipped,0) <> 0 THEN ((a.price * a.cr_shipped)*-1) ELSE (a.price * ISNULL(a.shipped,0)) END line_amt, 
	--CASE WHEN a.ordered = 0 THEN ((a.price * a.cr_shipped)*-1) ELSE (a.price * a.shipped) END line_amt, -- v1.3
	-- END v1.7
	c.category brand,
	c.type_code category,
	1 historic,
	CAST(a.order_no AS varchar(20)) order_no_text,
	ISNULL(d.category_2,'') gender,	-- v1.4
	ISNULL(d.field_32,'') attribute,	-- v1.6
	-- START v1.5
	CASE c.type_code WHEN 'FRAME' THEN (CASE WHEN ISNULL(a.cr_shipped,0) <> 0 THEN a.cr_shipped * -1 ELSE ISNULL(a.shipped,0) END)  
					 WHEN 'SUN' THEN (CASE WHEN ISNULL(a.cr_shipped,0) <> 0 THEN a.cr_shipped * -1 ELSE ISNULL(a.shipped,0) END)
					 ELSE 0 END piece_qty 
	-- END v1.5
FROM 
	dbo.cvo_ord_list_hist a (NOLOCK)
LEFT JOIN
	dbo.inv_master c (NOLOCK)
ON
	CAST(a.part_no AS VARCHAR(30)) = c.part_no -- v1.4 change to same data type as in inv_master
-- START v1.4
LEFT JOIN
	dbo.inv_master_add d (NOLOCK)
ON
	c.part_no = d.part_no
-- END v1.4
-- END v1.1
GO
GRANT SELECT ON  [dbo].[cvo_order_line_sales_vw] TO [public]
GO
