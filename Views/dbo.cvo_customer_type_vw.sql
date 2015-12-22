SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			cvo_customer_type_vw.sql
Type:			View
Called From:	Enterprise
Description:	Returns list of customer types
Developer:		Chris Tyler
Date:			28th March 2013

Revision History
*/

CREATE VIEW [dbo].[cvo_customer_type_vw]
AS

SELECT DISTINCT
	addr_sort1 as customer_type,
	addr_sort1 as customer_type_desc
FROM
	dbo.armaster_all (NOLOCK)
WHERE
	address_type = 0
	AND ISNULL(addr_sort1,'') <> ''

GO
GRANT SELECT ON  [dbo].[cvo_customer_type_vw] TO [public]
GO
