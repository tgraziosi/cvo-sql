SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[scm_localization_string_dtl_get_sp] @lang_id int, @stringid uniqueidentifier
as

select distinct l0.window_nm, l0.object_nm, l0.object_typ,
l0.attrib_typ, l0.attrib_nm, l0.stringtext, 
isnull(lx.stringtext,isnull(l90.stringtext,l99.stringtext)),
l0.orig_stringid, l0.stringid,
isnull(lx.rcd_level, isnull(l90.rcd_level, l99.rcd_level)),
10 rcd_lvl, @lang_id lang_id
from adm_localization_vw l0
left outer join adm_localization_vw l99 on l99.lang_id = @lang_id and l99.orig_stringid = l0.orig_stringid
and l99.rcd_level = 99
left outer join adm_localization_vw l90 on l90.lang_id = @lang_id and l90.orig_stringid = l0.orig_stringid
and (l90.attrib_typ = l0.attrib_typ) and l90.rcd_level = 90
left outer join adm_localization_vw lx on lx.lang_id = @lang_id and lx.orig_stringid = l0.orig_stringid
and (lx.attrib_typ = l0.attrib_typ) and (lx.window_nm = l0.window_nm) and (lx.object_nm = l0.object_nm)
and (lx.object_typ = l0.object_typ) and (lx.attrib_nm = l0.attrib_nm) and lx.rcd_level = 10
where l0.lang_id = 0 and l0.orig_stringid = @stringid 
  order by l0.window_nm, l0.object_nm, l0.object_typ,
l0.attrib_typ, l0.attrib_nm
GO
GRANT EXECUTE ON  [dbo].[scm_localization_string_dtl_get_sp] TO [public]
GO
