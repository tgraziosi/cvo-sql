SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[scm_localization_set_sp]  @lang_id int, @rcd_lvl int = 0,
  @window_nm varchar(255) = '',  @object_nm varchar(500) = '',  @object_typ varchar(20) = '',
  @attrib_typ varchar(20) = '',  @attrib_nm varchar(255) = '', 
  @attrib_value varchar(850) = '', @orig_value varchar(850) = ''
AS
declare @stringid uniqueidentifier, @orig_stringid uniqueidentifier
declare @del_ind int, @pos int

set @attrib_value = replace(@attrib_value,'~"','"')
set @attrib_value = replace(@attrib_value,'~''','''')
set @window_nm = ltrim(isnull(@window_nm,''))
set @object_nm = ltrim(isnull(@object_nm,''))
set @object_typ = ltrim(isnull(@object_typ,''))
set @attrib_typ = ltrim(isnull(@attrib_typ,''))
set @attrib_nm = ltrim(isnull(@attrib_nm,''))
set @del_ind = 0

if @attrib_value = '' and @rcd_lvl > 0 
  set @rcd_lvl = @rcd_lvl * -1

if @rcd_lvl < 0 
  select @del_ind = 1 , @rcd_lvl = abs(@rcd_lvl)
else
  select @stringid = stringid
  from adm_strings_vw (nolock)
  where languageid = @lang_id and stringtext = @attrib_value


if @rcd_lvl > 0  -- not core language
begin
  select @orig_stringid = stringid
  from adm_strings_vw (nolock)
  where languageid = 0 and stringtext = @orig_value

  if @orig_stringid is not null and @stringid is NULL and @del_ind = 0
  begin
    delete localized_strings
    from adm_localization l
    join adm_strings_vw localized_strings on localized_strings.languageid = l.lang_id 
      and localized_strings.stringid = l.stringid
    where l.lang_id = @lang_id and l.rcd_level = @rcd_lvl and 
      window_nm = @window_nm and object_nm = @object_nm and object_typ = @object_typ and
      attrib_typ = @attrib_typ and attrib_nm = @attrib_nm and l.orig_stringid = @orig_stringid
  end
end

if @stringid is null and @del_ind = 0
begin
  set @stringid = newid()
  insert adm_strings_vw (languageid, stringid, stringtext)
  values (@lang_id, @stringid, @attrib_value)

end

if @rcd_lvl = 0
begin
  if @window_nm not in ( 'w_find_generic', 'w_core', 'w_note')
    delete adm_localization
    where (lang_id = @lang_id and rcd_level = 0 and window_nm = @window_nm 
    and object_nm = @object_nm and object_typ = @object_typ and attrib_typ = @attrib_typ
    and attrib_nm = @attrib_nm)
  else
    delete adm_localization
    where (lang_id = @lang_id and rcd_level = 0 and window_nm = @window_nm 
    and object_nm = @object_nm and object_typ = @object_typ and attrib_typ = @attrib_typ
    and attrib_nm = @attrib_nm and orig_stringid = @stringid)
  
  insert adm_localization (lang_id, rcd_level, window_nm, object_nm, object_typ, attrib_typ, attrib_nm, 
  stringid, orig_stringid )
  values (@lang_id, 0, @window_nm, @object_nm, @object_typ, @attrib_typ, @attrib_nm, @stringid, @stringid)
end
else
begin
  if @orig_stringid is null and @del_ind = 0
  begin
    set @orig_stringid = newid()
    insert adm_strings_vw (languageid, stringid, stringtext)
    values (0, @orig_stringid, @orig_value)
  end

  if @orig_stringid is not null
    delete adm_localization
    where lang_id = @lang_id and rcd_level = @rcd_lvl and 
      window_nm = @window_nm and object_nm = @object_nm and object_typ = @object_typ and
      attrib_typ = @attrib_typ and attrib_nm = @attrib_nm and orig_stringid = @orig_stringid
    
  if @del_ind = 0
  begin
    if @rcd_lvl in ( 90,99)
    begin
      if not exists (select 1 from adm_localization where lang_id = @lang_id and
        rcd_level = 99 and orig_stringid = @orig_stringid)
      begin
        set @rcd_lvl = 99
        insert adm_localization (lang_id, rcd_level, window_nm, object_nm, object_typ, attrib_typ, attrib_nm, 
        stringid, orig_stringid )
        values (@lang_id, 99, '', '', '', '', '', @stringid, @orig_stringid)
      end       
    end

    if @rcd_lvl < 99
    begin
      insert adm_localization (lang_id, rcd_level, window_nm, object_nm, object_typ, attrib_typ, attrib_nm, 
      stringid, orig_stringid )
      values (@lang_id, @rcd_lvl, @window_nm, @object_nm, @object_typ, @attrib_typ, @attrib_nm, @stringid, @orig_stringid)
    end
  end
end

select @stringid
GO
GRANT EXECUTE ON  [dbo].[scm_localization_set_sp] TO [public]
GO
