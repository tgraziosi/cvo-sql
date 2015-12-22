SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_generic_find1] @sqltext varchar(2000),
@sort_by varchar(255), @sort_type char(1), @last_result varchar(255),
@key_col varchar(255), @key_type char(1), @last_key varchar(255), @rowcount int, @void_col varchar(255),
@filter_col varchar(255), @filter_value varchar(255)
AS
declare @where_ind int, @select_ind int, @order_ind int

select @select_ind = charindex('SELECT',UPPER(@sqltext)) 
select @where_ind = charindex('WHERE',UPPER(@sqltext))
select @order_ind = 0
select @sort_by = isnull(@sort_by,''), @last_result = isnull(@last_result,''),
  @sort_type = isnull(@sort_type,''), @key_col = isnull(@key_col,''), @key_type = isnull(@key_type,''),
  @last_key = isnull(@last_key,'')

if isnull(@sqltext,'') = ''
  return

select @sqltext = replace(@sqltext,'"','''')


if @select_ind > 0 
begin
  if @last_result != ''
    select @sqltext = @sqltext + 
      case when @where_ind = 0 then ' WHERE ' else ' AND' end + ' ((' +
      @sort_by + ' = ' +
      case @sort_type
      when 'T' then '''' + substring(@last_result,1,23) + ''''
      when 'N' then @last_result
      when 'D' then @last_result
      else '''' + @last_result + ''''
      end,
      @where_ind = 1

  if @last_key != ''
    select @sqltext = @sqltext + 
      case when @where_ind = 0 then ' WHERE ' else ' AND' end + ' ' +
      @key_col + ' >= ' +
      case @key_type
      when 'T' then '''' + substring(@last_key,1,23) + ''''
      when 'N' then @last_key
      when 'D' then @last_key
      else '''' + @last_key + ''''
      end
      + case when @last_result != '' then ') ' else '' end,
      @where_ind = 1
  else
    select @sqltext = @sqltext +
      + case when @last_result != '' then ') ' else '' end

  if @last_result != ''
    select @sqltext = @sqltext + 
      ' or '  +
      @sort_by + ' > ' +
      case @sort_type
      when 'T' then '''' + substring(@last_result,1,23) + ''''
      when 'N' then @last_result
      when 'D' then @last_result
      else '''' + @last_result + ''''
      end + ') ',
      @where_ind = 1

  if isnull(@void_col,'') != ''
    select @sqltext = @sqltext + 
      case when @where_ind = 0 then ' WHERE ' else ' AND' end + ' ' +
      'lower(isnull(' + @void_col + ',''n'')) != ''v''',
      @where_ind = 1
  
 if isnull(@filter_col,'') != '' and isnull(@filter_value,'') != ''
    select @sqltext = @sqltext + 
      case when @where_ind = 0 then ' WHERE ' else ' AND' end + ' ' +
      'upper(convert(varchar(255),' + @filter_col  + ')) = ' +
      '''' + upper(@filter_value) + '''',
      @where_ind = 1

  if isnull(@sort_by,'') != ''
    select @sqltext = @sqltext + ' order by ' + @sort_by,
    @order_ind = 1

  if isnull(@sort_by,'') != @key_col
    select @sqltext = @sqltext + 
      case @order_ind when 0 then ' order by ' else ' , ' end +
      @key_col

end
else
begin
  if isnull(@sort_by,'') != ''
    select @sqltext = @sqltext + ' , "' + @sort_by + '","' + @last_key + '"'
end 

--select @sqltext
set rowcount @rowcount
exec( @sqltext )
set rowcount 0

GO
GRANT EXECUTE ON  [dbo].[fs_generic_find1] TO [public]
GO
