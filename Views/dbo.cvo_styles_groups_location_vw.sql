SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*  
Name:   cvo_styles_groups_location_vw.sql  
Type:   View  
Called From: Enterprise  
Description: Returns list of Styles from inv_master_add 
			 excluding styles only linked to obsolete parts with no stock  
Developer:  Chris Tyler  
Date:   4th July 2012
  
Revision History  
v1.0 CT 04/07/12 Original version 
v1.1 CT 10/07/12 Changed to use inventory instead on inv_list 
v1.2 CB 15/01/13 Exclude stock in quarantine bins	
v1.3 CB 15/01/13 Exclude allocated stock	
*/  
  
CREATE VIEW [dbo].[cvo_styles_groups_location_vw]  
AS  
  
SELECT DISTINCT   
 a.field_2 AS Style,  
 a.field_2 AS [Description],  
 b.category AS Groups,
 c.location AS Location 
FROM   
 dbo.inv_master_add a(NOLOCK)  
INNER JOIN  
 dbo.inv_master b (NOLOCK)  
ON  
 a.part_no = b.part_no  
INNER JOIN
dbo.inventory c (NOLOCK)
 --dbo.inv_list c (NOLOCK)
ON
 a.part_no = c.part_no
LEFT JOIN 
dbo.f_get_excluded_bins(5) z on c.part_no = z.part_no and c.location = z.location -- v1.2
LEFT JOIN 
dbo.f_get_excluded_bins(6) x on c.part_no = x.part_no and c.location = x.location -- v1.2
WHERE   
 ISNULL(a.field_2,'') <> ''  
AND b.type_code IN('FRAME','SUN')  
AND NOT (b.obsolete = 1 AND (c.in_stock - ISNULL(z.qty,0) - ISNULL(x.qty,0)) <= 0) -- v1.2

GO
GRANT SELECT ON  [dbo].[cvo_styles_groups_location_vw] TO [public]
GO
