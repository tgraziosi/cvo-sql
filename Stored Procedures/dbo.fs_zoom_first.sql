SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_zoom_first] @sqltext varchar(1000), @key_col varchar(255), @void_col varchar(255)
AS
declare @where_ind int, @select_ind int, @from_pos int

select @select_ind = charindex('SELECT',UPPER(@sqltext)) 
select @where_ind = charindex('WHERE',UPPER(@sqltext))
select @key_col = isnull(@key_col,'')

if isnull(@sqltext,'') = ''
  return

select @from_pos = 0
if @select_ind > 0 
begin
  if @key_col != ''
  begin
    select @from_pos = charindex('from',@sqltext)

    if @from_pos > 0
      select @sqltext = 'select min(' + @key_col + ') ' + substring(@sqltext,charindex('from',@sqltext),1000)

  if isnull(@void_col,'') != ''
    select @sqltext = @sqltext + 
      case when @where_ind = 0 then ' WHERE ' else ' AND' end + ' ' +
      'lower(isnull(' + @void_col + ',''n'')) != ''v''',
      @where_ind = 1

    if @from_pos = 0
      select @sqltext = @sqltext + ' order by ' + @key_col
  end
end
else
begin
  if @key_col != ''
    select @sqltext = @sqltext + ' , "first","' + @key_col + '",""'
end 

if @from_pos = 0
  set rowcount 1

exec( @sqltext )
set rowcount 0

GO
GRANT EXECUTE ON  [dbo].[fs_zoom_first] TO [public]
GO
