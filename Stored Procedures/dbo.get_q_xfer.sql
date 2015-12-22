SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_xfer] @strsort varchar(30), @sort char(1), @stat char(1), @xno int, @mode int = 0 AS

declare @minstat char(1), @maxstat char(1), @table varchar(32), @sql varchar(1000)
declare @no varchar(10), @dt int
if @stat = 'A' begin
   select @minstat = 'A', @maxstat = 'T'
end
if @stat = 'O' begin
   select @minstat = 'A', @maxstat = 'R'
end
if @stat = 'S' begin
   select @minstat = 'S', @maxstat = 'T'
end

select @table = case @mode when 1 then 'xfers_from' when 2 then 'xfers_to' else 'xfers' end

select @sql = 'select x.xfer_no, x.from_loc, x.to_loc, x.req_ship_date, 
       x.sch_ship_date, x.date_shipped, x.rec_no, x.status, x.proc_po_no '
select @sql = @sql + ' from ' + @table + ' x (nolock)'
select @sql = @sql + ' where (x.status between ''' + @minstat + ''' and  ''' + @maxstat + ''')'

set rowcount 100
        
if @sort='N' 
begin
  select @no=convert(varchar(10),convert(int,@strsort))

  select @sql = @sql + ' and (x.xfer_no >= ' + @no + ')'
  select @sql = @sql + ' order by x.xfer_no'
end       

        
if @sort='P' 
begin

  select @sql = @sql + ' and (isnull(x.proc_po_no,'''') >= ''' + @strsort + ''')'
  select @sql = @sql + ' order by x.xfer_no'
end       
    
      
if @sort='F' 
begin
  select @sql = @sql + ' and ((x.from_loc > ''' + @strsort + ''') OR (x.from_loc = ''' + @strsort + ''''
  select @sql = @sql + ' and x.xfer_no >= ' + convert(varchar(10),@xno) + ') )'
  select @sql = @sql + ' order by x.from_loc, x.xfer_no'
end     
      
if @sort='T' 
begin
  select @sql = @sql + ' and ( (x.to_loc > ''' + @strsort + ''') OR (x.to_loc = ''' + @strsort + ''''
  select @sql = @sql + ' and x.xfer_no >= ' + convert(varchar(10),@xno) + ') )'
  select @sql = @sql + ' order by x.to_loc, x.xfer_no'
end     

if @sort='D' 
begin
  select @dt=datediff(day,'01/01/1900',convert(datetime,@strsort)) + 693596
  select @sql = @sql + ' and (datediff(day,''01/01/1900'', x.date_shipped ) + 693596 >= ' + convert(varchar(10),@dt) + ')'
  select @sql = @sql + ' and x.xfer_no >= ' + convert(varchar(10), @xno)
  select @sql = @sql + ' order by datediff(day,''01/01/1900'', x.date_shipped ), x.xfer_no'
end     

print @sql
exec (@sql)
GO
GRANT EXECUTE ON  [dbo].[get_q_xfer] TO [public]
GO
