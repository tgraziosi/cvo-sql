SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--select * from cvo_security_lookup_vw

CREATE view [dbo].[CVO_Security_Lookup_vw] as 

/* 
Author - Tine Graziosi
Date - 8/27/2012
Purpose - To easily find user and group information for application objects, EVs, etc.

For testing:

declare @form_desc varchar (50)
set @form_desc = '%customer%'

--'SALES/TERRITORY OVERRIDE'
*/

SELECT distinct 'USER' as SecType, a.write, a.app_id, app.app_title, c.user_id, c.user_name, 
-1 as group_id, 'User-specific' as group_name, b.form_id, b.form_desc 
FROM CVO_Control.dbo.smuserperm a ( NOLOCK ) 
JOIN CVO_Control.dbo.smmenus b ( NOLOCK ) ON a.app_id =b.app_id AND a.form_id =b.form_id 
JOIN CVO_Control.dbo.smusers c ( NOLOCK ) ON a.user_id=c.user_id 
join cvo_control.dbo.smapp app (nolock) on a.app_id = app.app_id
/*
WHERE b.form_desc like @form_desc
*/
union
SELECT distinct 'GROUP' as SecType, a.write, a.app_id, app.app_title, c.user_id, d.user_name, 
e.group_id, e.group_name, b.form_id, b.form_desc
FROM CVO_Control.dbo.smgrpperm a ( NOLOCK ) 
JOIN CVO_Control.dbo.smmenus b ( NOLOCK ) ON a.app_id =b.app_id AND a.form_id =b.form_id 
JOIN CVO_Control.dbo.smgrpdet c ( NOLOCK ) ON a.group_id =c.group_id 
join cvo_control.dbo.smgrphdr e (nolock) on a.group_id = e.group_id
join cvo_control.dbo.smapp app (nolock) on a.app_id = app.app_id
JOIN CVO_Control.dbo.smusers d ( NOLOCK ) ON c.user_id =d.user_id 
/*
WHERE b.form_desc like @form_desc
*/

GO
GRANT SELECT ON  [dbo].[CVO_Security_Lookup_vw] TO [public]
GO
