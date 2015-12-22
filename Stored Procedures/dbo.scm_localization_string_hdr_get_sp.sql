SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[scm_localization_string_hdr_get_sp] @lang_id int, @stringid uniqueidentifier
as
SET NOCOUNT ON

select o.stringtext, s.stringtext, o.stringid, l.stringid, isnull(l.lang_id,@lang_id) 
from adm_strings_vw o (nolock)
left outer join adm_localization l on l.orig_stringid = o.stringid and l.rcd_level = 99
left outer join adm_strings_vw s (nolock)on s.languageid = l.lang_id and s.stringid = l.stringid
where o.languageid = 0 
and o.stringid = @stringid and isnull(l.lang_id,@lang_id) = @lang_id

GO
GRANT EXECUTE ON  [dbo].[scm_localization_string_hdr_get_sp] TO [public]
GO
