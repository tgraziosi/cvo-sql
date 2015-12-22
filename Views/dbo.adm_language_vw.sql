SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[adm_language_vw] as

select 
languageid,
languagenm
from CVO_Control..adm_language
GO
GRANT REFERENCES ON  [dbo].[adm_language_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_language_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_language_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_language_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_language_vw] TO [public]
GO
