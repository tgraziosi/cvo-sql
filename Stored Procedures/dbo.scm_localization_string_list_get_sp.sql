SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[scm_localization_string_list_get_sp] @lang_id int, @group int,
  @window_nm varchar(255) = '<ALL>', @obj_typ varchar(500) = '<ALL>',
  @attrib_typ varchar(255) = '<ALL>', @core_ind int = 1, @conv_ind int = 1
as
declare @show_ind int

set @show_ind = @core_ind
if @conv_ind = 1 set @show_ind = @show_ind + 10

if @window_nm in ('', '<ALL>') set @window_nm = '%'
if @obj_typ in ('', '<ALL>') set @obj_typ = '%'
if @attrib_typ in ('', '<ALL>') set @attrib_typ = '%'

if @group = 0 -- window list
begin
  select '<ALL>',''
  union
  select distinct l.window_nm, l.window_nm
  from adm_localization l  where l.lang_id = 0
  order by 1
end
if @group = 1 -- object type list
begin
  select '<ALL>',''
  union
  select distinct l.object_typ, l.object_typ
  from adm_localization l  where l.lang_id = 0
  order by 1
end
if @group = -1 -- object type list
begin
  select '<ALL>',''
  union
  select distinct l.attrib_typ, l.attrib_typ
  from adm_localization l  where l.lang_id = 0
  order by 1
end
if @group = 2 -- attrib type
begin

select distinct l0.attrib_typ, l0.orig_stringtext,
isnull(lx.stringtext,isnull(l99.stringtext,'<core string>')), 
l0.orig_stringid, isnull(lx.stringid,l99.stringid), 
isnull(lx.window_nm,''), isnull(lx.object_nm,''), isnull(lx.object_typ,''),
isnull(lx.attrib_nm,''), 
isnull(lx.attrib_typ,isnull(l99.attrib_typ,l0.attrib_typ)), isnull( lx.rcd_level,
isnull(l99.rcd_level,90)), @lang_id lang_id
from adm_localization_vw l0
left outer join adm_localization_vw l99 on l99.lang_id = @lang_id and l99.orig_stringid = l0.orig_stringid
and l99.rcd_level = 99
left outer join adm_localization_vw l90 on l90.lang_id = @lang_id and l90.orig_stringid = l0.orig_stringid
and l90.rcd_level = 90 and (l90.attrib_typ = l0.attrib_typ)
left outer join adm_localization_vw lx on lx.lang_id = @lang_id and lx.orig_stringid = l0.orig_stringid
and (lx.attrib_typ = l0.attrib_typ) and (lx.window_nm = l0.window_nm) and (lx.object_nm = l0.object_nm)
and (lx.object_typ = l0.object_typ) and (lx.attrib_nm = l0.attrib_nm) and lx.rcd_level = 10
where l0.lang_id = 0 and l0.window_nm like @window_nm
  and l0.object_typ like @obj_typ and l0.attrib_typ like @attrib_typ
and 
(@show_ind = 11
  or (@show_ind = 10 and isnull(lx.stringid,l99.stringid) is not null) 
  or (@show_ind = 1 and isnull(lx.stringid,l99.stringid) is null) 
  or (@show_ind = 0 and 1=0))
  order by l0.attrib_typ, l0.orig_stringtext

end
if @group = 3 -- string
begin

  select distinct l.attrib_nm, o.stringtext, s.stringtext, l.orig_stringid, l.stringid
  from adm_localization l
  join adm_strings_vw s (nolock)on s.languageid = l.lang_id and s.stringid = l.stringid
  join adm_strings_vw o (nolock) on o.languageid = 0 and o.stringid = l.orig_stringid
  where l.lang_id = 0
  order by l.attrib_nm, o.stringtext
end
GO
GRANT EXECUTE ON  [dbo].[scm_localization_string_list_get_sp] TO [public]
GO
