SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_zoom_get] @sqltext varchar(1000), @key_col varchar(255), 
@key_type char(1), @last_key varchar(255), @void_col varchar(255)
AS
declare @where_ind int, @select_ind int

select @select_ind = charindex('SELECT',UPPER(@sqltext)) 
select @where_ind = charindex('WHERE',UPPER(@sqltext))
select @key_col = isnull(@key_col,''), @key_type = isnull(@key_type,''),
  @last_key = isnull(@last_key,'')

if isnull(@sqltext,'') = ''
  return

select @sqltext = replace(@sqltext,'"','''')


if @select_ind > 0 
begin
    select @sqltext = @sqltext + 
      case when @where_ind = 0 then ' WHERE ' else ' AND' end + ' ' +
      @key_col + ' = ' +
      case @key_type
      when 'T' then '''' + substring(@last_key,1,10) + ''''
      when 'N' then @last_key
      when 'D' then @last_key
      else '''' + @last_key + ''''
      end,
      @where_ind = 1

  if isnull(@void_col,'') != ''
    select @sqltext = @sqltext + 
      case when @where_ind = 0 then ' WHERE ' else ' AND' end + ' ' +
      'lower(isnull(' + @void_col + ',''n'')) != ''v''',
      @where_ind = 1

end
else
begin
  select @sqltext = @sqltext + ' , "get","' + @key_col + '","' + @last_key + '"'
end 
exec( @sqltext )

GO
GRANT EXECUTE ON  [dbo].[fs_zoom_get] TO [public]
GO
