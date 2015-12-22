SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[scm_localization_get_sp]  @lang_id int AS

select l.lang_id, l.rcd_level, l.window_nm, l.object_nm, l.object_typ,
l.attrib_typ, l.attrib_nm, o.stringtext, s.stringtext
from adm_localization l
join adm_strings_vw s (nolock) on s.languageid = l.lang_id and s.stringid = l.stringid
join adm_strings_vw o (nolock) on o.languageid = 0 and o.stringid = l.orig_stringid
where l.lang_id = @lang_id

GO
GRANT EXECUTE ON  [dbo].[scm_localization_get_sp] TO [public]
GO
