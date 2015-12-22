SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[adm_smperm_vw] AS
select user_id, company_id, app_id, form_id, object_type, read_perm, write, user_copy
from CVO_Control..smperm

GO
GRANT REFERENCES ON  [dbo].[adm_smperm_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_smperm_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_smperm_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_smperm_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_smperm_vw] TO [public]
GO
