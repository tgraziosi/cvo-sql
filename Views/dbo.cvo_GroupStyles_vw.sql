SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			cvo_GroupStyles_vw.sql
Type:			View
Called From:	Enterprise
Description:	Returns list of Styles and Groups
Developer:		Chris Tyler
Date:			03rd May 2011

Revision History
v1.0	CT	03/05/11	Original version
*/

CREATE VIEW [dbo].[cvo_GroupStyles_vw]
AS

SELECT DISTINCT
	i.category AS Category, 
	a.field_2 AS Style,
	a.field_2 AS [Description]
FROM 
	dbo.inv_master_add a (NOLOCK)
INNER JOIN
	dbo.inv_master i (NOLOCK)
ON
	a.part_no = i.part_no
WHERE 
	ISNULL(a.field_2,'') <> ''
AND
	i.type_code IN('FRAME','SUN')
GO
GRANT SELECT ON  [dbo].[cvo_GroupStyles_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_GroupStyles_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_GroupStyles_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_GroupStyles_vw] TO [public]
GO
