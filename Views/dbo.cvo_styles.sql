SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			cvo_styles.sql
Type:			View
Called From:	Enterprise
Description:	Returns list of Styles from inv_master_add
Developer:		Chris Tyler
Date:			23rd March 2011

Revision History
v1.0	CT	23/03/11	Original version
*/

CREATE VIEW [dbo].[cvo_styles]
AS

SELECT DISTINCT 
	a.field_2 AS Style,
	a.field_2 AS [Description]
FROM 
	dbo.inv_master_add a(NOLOCK)
INNER JOIN
	dbo.inv_master b (NOLOCK)
ON
	a.part_no = b.part_no
WHERE 
	ISNULL(a.field_2,'') <> ''
AND
	b.type_code IN('FRAME','SUN')
GO
GRANT SELECT ON  [dbo].[cvo_styles] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_styles] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_styles] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_styles] TO [public]
GO
