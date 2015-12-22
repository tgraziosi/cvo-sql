SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			cvo_credit_return_ra_vw.sql
Type:			View
Called From:	Enterprise
Description:	Returns ra numbers for credit returns
Developer:		Chris Tyler
Date:			11th October 2012

Revision History
*/

CREATE VIEW [dbo].[cvo_credit_return_ra_vw]
AS

SELECT
	order_no,
	ext, 
	ra1 ra,
	1 ra_no
FROM
	cvo_orders_all (NOLOCK)
WHERE
	ra1 IS NOT NULL
UNION
SELECT
	order_no,
	ext, 
	ra2 ra,
	2 ra_no
FROM
	cvo_orders_all (NOLOCK)
WHERE
	ra2 IS NOT NULL
UNION
SELECT
	order_no,
	ext,  
	ra3 ra,
	3 ra_no
FROM
	cvo_orders_all (NOLOCK)
WHERE
	ra3 IS NOT NULL
UNION
SELECT
	order_no,
	ext, 
	ra4 ra,
	4 ra_no
FROM
	cvo_orders_all (NOLOCK)
WHERE
	ra4 IS NOT NULL
UNION
SELECT
	order_no,
	ext, 
	ra5 ra,
	5 ra_no
FROM
	cvo_orders_all (NOLOCK)
WHERE
	ra5 IS NOT NULL
UNION
SELECT 
	order_no,
	ext,
	ra6 ra,
	6 ra_no
FROM
	cvo_orders_all (NOLOCK)
WHERE
	ra6 IS NOT NULL
UNION
SELECT 
	order_no,
	ext,
	ra7 ra,
	7 ra_no
FROM
	cvo_orders_all (NOLOCK)
WHERE
	ra7 IS NOT NULL
UNION
SELECT
	order_no,
	ext, 
	ra8 ra,
	8 ra_no
FROM
	cvo_orders_all (NOLOCK)
WHERE
	ra8 IS NOT NULL

GO
GRANT SELECT ON  [dbo].[cvo_credit_return_ra_vw] TO [public]
GO
