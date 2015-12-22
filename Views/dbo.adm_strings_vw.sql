SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[adm_strings_vw] as

select 
languageid,
stringid,
stringname,
stringtext 
from CVO_Control..adm_strings
GO
GRANT REFERENCES ON  [dbo].[adm_strings_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_strings_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_strings_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_strings_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_strings_vw] TO [public]
GO
