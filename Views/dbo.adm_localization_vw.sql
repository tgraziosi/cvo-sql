SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[adm_localization_vw] as

select 
l.lang_id,
l.rcd_level,
l.window_nm,
l.object_nm,
l.object_typ,
l.attrib_typ,
l.attrib_nm,
l.orig_stringid,
l.stringid,
o.stringtext orig_stringtext,
s.stringtext stringtext
from adm_localization l
join adm_strings_vw s (nolock)on s.languageid = l.lang_id and s.stringid = l.stringid
join adm_strings_vw o (nolock) on o.languageid = 0 and o.stringid = l.orig_stringid

GO
GRANT REFERENCES ON  [dbo].[adm_localization_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_localization_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_localization_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_localization_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_localization_vw] TO [public]
GO
