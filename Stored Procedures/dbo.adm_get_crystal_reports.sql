SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[adm_get_crystal_reports] @user_name varchar(30)
as

select distinct a.app_title,
o.Name,
ra.ReportID1,
ra.ReportID2
from CVO_Control..smmenus m
join CVO_Control..smperm p on p.app_id = m.app_id and m.form_id = p.form_id and m.app_id = 18000
join CVO_Control..smcom c on c.App_ID = m.app_id and m.form_id = c.Form_ID
join CVO_Control..ReportActions ra on ra.ClassId = c.ClassID and ra.ReportID1 <> 0
join CVO_Control..smapp a on a.app_id = m.app_id
join CVO_Control..ObjectClasses o on o.ClassId = ra.ClassId
join CVO_Control..smusers u on u.user_name = @user_name and u.user_id = p.user_id
GO
GRANT EXECUTE ON  [dbo].[adm_get_crystal_reports] TO [public]
GO
