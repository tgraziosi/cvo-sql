SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_produce60]  @info varchar(30), @sort char(1), @prodno int, @status char(1), @loc varchar(10),
  @org_id varchar(30) = '', @prod_type char(1) = '', @module char(10) = '' , @sec_level int = 99 AS

set rowcount 100
declare @minstat char(1)
declare @maxstat char(1), @sql varchar(1000)
declare @x int
if @status = 'A' begin
select @minstat='A'
select @maxstat='Z'
end
if @status = 'N' begin
select @minstat='N'
select @maxstat='O'
end
if @status = 'P' begin
select @minstat='P'
select @maxstat='Q'
end
if @status = 'Q' begin
select @minstat='R'
select @maxstat='R'
end
if @status = 'S' begin
select @minstat='R'
select @maxstat='U'
end

set @sql = 'select prod_no, prod_ext, part_no, location, shift, prod_type, prod_date, qty, status'
set @sql = @sql + ' from produce ( NOLOCK )'
set @sql = @sql + ' where status between ''' + @minstat + ''' and ''' + @maxstat + ''''
if @loc != '%' 
  set @sql = @sql + ' and location like ''' + @loc + ''''
if isnull(@org_id,'') != '' 
  set @sql = @sql + ' and (location in (select location from dbo.adm_get_related_locs_fn(''' + @module + ''',''' +@org_id + ''',' + convert(varchar,@sec_level) + ')))'
if isnull(@prod_type,'') != ''
  set @sql = @sql + ' and prod_type = ''' + @prod_type + ''''

if @sort='D'
begin
  if @info != ''
    set @sql = @sql + ' and prod_date >= ''' + @info + ''''
  set @sql = @sql + ' order by prod_date, part_no, prod_no'
end
if @sort='P'
begin
  if @info > ''
    set @sql = @sql + ' and ((part_no > ''' + @info + ''') OR (part_no = ''' + @info + ''' and prod_no >= ' + convert(varchar,@prodno) + '))'
  set @sql = @sql + ' order by part_no,prod_date'
end
if @sort='N'
begin
  if @info != ''
  begin
    set @x = convert(int,@info)
    set @sql = @sql + ' and prod_no >= ' + convert(varchar,@x)
  end
  set @sql = @sql + ' order by prod_no'
end

print @sql
execute (@sql)
GO
GRANT EXECUTE ON  [dbo].[get_q_produce60] TO [public]
GO
