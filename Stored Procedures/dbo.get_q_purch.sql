SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[get_q_purch] @strsort varchar(50), @sort char(1), @status char(1), @po varchar(30), @loc varchar(10), 
  @pn varchar(30), @secured_mode int = 0 AS

declare @npo int							-- mls 2/21/03 SCR 29211
DECLARE @current_po varchar(16), @next_key int
declare @next_po varchar(50)
	
declare @sql varchar(4000)

select @npo = isnull((select po_key from purchase_all where po_no = @po),0)	-- mls 2/21/03 SCR 29211

select @secured_mode =  isnull(@secured_mode,0), @strsort = isnull(@strsort,'')

select @sql = 
  'select l.po_no, v.vendor_name, l.part_no, l.vend_sku, l.qty_ordered, l.status, l.location, l.unit_cost,
   p.status,p.vendor_no,p.printed, g.currency_mask,  p.proc_po_no'
select @sql = @sql + 
  case @secured_mode 
  when '1'
    then ' from pur_list l ( NOLOCK ), purchase_entry_vw p ( NOLOCK ), adm_vend v ( NOLOCK ), glcurr_vw g ( NOLOCK )'
  when '2'
    then ' from pur_list_rcvg_vw l ( NOLOCK ), purchase_rcvg_vw p ( NOLOCK ), adm_vend v ( NOLOCK ), glcurr_vw g ( NOLOCK )'
  else
    ' from pur_list l ( NOLOCK ), purchase p ( NOLOCK ), adm_vend_all v ( NOLOCK ), glcurr_vw g( NOLOCK )'
  end

select @sql = @sql + 
  ' where (p.po_no = l.po_no) and (p.vendor_no=v.vendor_code) and (p.curr_key = g.currency_code)'

if @status != '%'
begin
  if @status = 'H'
    select @sql = @sql + ' and p.status = ''H'''
  else
    select @sql = @sql + ' and l.status like ''' + @status + ''''
end
if @loc != '%'
begin
  if @secured_mode = 1 
    select @sql = @sql + 'and (p.location like  ''' + @loc + ''')'
  else
   select @sql = @sql + 'and (l.location like  ''' + @loc + ''')'
end
set rowcount 100


if @sort='P' 
begin
  if @strsort > ''
    select @sql = @sql + ' and ((l.part_no > ''' + @strsort + ''') OR (l.part_no = ''' + @strsort + ''' and l.po_key >= ' + convert(varchar,@npo) + ' ))'
  select @sql = @sql + ' order by l.part_no, l.po_key'
end

if @sort='V' 
begin
  if @strsort > ''
    select @sql = @sql + ' and ((p.vendor_no > ''' + @strsort + ''') OR (p.vendor_no = ''' + @strsort + ''' and l.po_key = ' + convert(varchar,@npo) + ' and l.part_no >= ''' + @pn + ''' )' +
     ' OR (p.vendor_no = ''' + @strsort + ''' and l.po_key > ' + convert(varchar,@npo) + '))'
  select @sql = @sql + ' order by p.vendor_no, l.po_key, l.part_no'
end

if @sort='L' 
begin
  if @strsort > ''
    select @sql = @sql + ' and ((l.location > ''' +  @strsort + ''') OR (l.location = ''' + @strsort + ''' and l.po_key >= ' + convert(varchar,@npo) + ' and l.part_no >= ''' + @pn + ''' ))'
  select @sql = @sql + ' order by l.location, l.po_key, l.part_no'
end

if @sort='N' 
begin
  SELECT @next_key = MAX(po_key) FROM	purchase_all WHERE	po_no	= @strsort
	
  IF @next_key IS NULL
    SELECT @next_key = 0 

  if @next_key > 0
    select @sql = @sql + 'and ((p.po_key > ' + convert(varchar, @next_key) + ' ) or (l.po_key = ' + convert(varchar,@next_key) + ' and l.part_no >= ''' + @pn + ''')) '
  select @sql = @sql + ' order by p.po_key, l.part_no'
end

if @sort='E' 
begin
  SELECT @next_po = MAX(proc_po_no) FROM	purchase_all WHERE	proc_po_no	= @strsort
	
  IF @next_po IS NULL
    SELECT @next_po = ''

  select @sql = @sql + 'and isnull(p.proc_po_no,'''') != '''''
  if @next_po > ''
  begin
    select @next_po = replicate('0',50 - len(@next_po)) + @next_po

    select @sql = @sql + 'and ((replicate(''0'',50 - len(p.proc_po_no)) + p.proc_po_no > ''' + @next_po + ''' ) or (replicate(''0'',50 - len(p.proc_po_no)) + p.proc_po_no = ''' + @next_po + ''' and l.part_no >= ''' + @pn + ''')) '
  end

  select @sql = @sql + ' order by replicate(''0'',50 - len(p.proc_po_no)) + p.proc_po_no, l.part_no'
end


if @sort='S' 
begin
  if @strsort > ''
    select @sql = @sql + ' and ((l.vend_sku > ''' + @strsort + ''') OR (l.vend_sku = ''' + @strsort + ''' and l.po_key >= ' + convert(varchar,@npo) + ' and l.part_no >= ''' + @pn + '''))'
  select @sql = @sql + ' order by l.vend_sku, l.po_key'
end

print @sql
execute (@sql)
set rowcount 0
GO
GRANT EXECUTE ON  [dbo].[get_q_purch] TO [public]
GO
