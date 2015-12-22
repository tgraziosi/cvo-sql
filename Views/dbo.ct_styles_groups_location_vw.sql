SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*    
Name:   ct_styles_groups_location_vw.sql    
Type:   View    
Called From: Enterprise    
Description: Returns list of Styles from inv_master_add   
    excluding groups only linked to obsolete parts with no stock    
Developer:  Chris Tyler    
Date:   4th July 2012  
    
Revision History    
v1.0 CT 04/07/12 Original version    
*/    
    
CREATE VIEW [dbo].[ct_styles_groups_location_vw]    
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
ON  
 a.part_no = c.part_no  
WHERE     
 ISNULL(a.field_2,'') <> ''    
AND b.type_code IN('FRAME','SUN')    
AND NOT (b.obsolete = 1 AND c.in_stock <= 0)  
  
GO
