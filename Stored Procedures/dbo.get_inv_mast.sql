SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
-- v1.0 CB 02/05/2012 - If @type is FRAME then treat as FRAME OR SUN

CREATE PROCEDURE [dbo].[get_inv_mast] @strsort varchar(50), @sort char(1), @loc char(1),   
                              @void char(1), @stat char(1), @type varchar(10),   
                              @lastkey varchar(30), @iobs int, @org_id varchar(30) = '', @module varchar(10) = '',  
   @sec_level int = 99  AS  

-- v1.0 Create table to hold type
CREATE TABLE #types (type_code varchar(10))

-- v1.0 if a type is specified insert it into the working table
IF @type <> '%'
BEGIN
	INSERT	#types
	SELECT	@type

	-- if the type is frame then add SUN to the working table 
	IF @type = 'FRAME'
	BEGIN
		INSERT	#types
		SELECT	'SUN'
	END
END
  
set rowcount 100  
declare @minstat char(1)  
declare @maxstat char(1), @sql varchar(1000)  
SELECT @minstat = 'A'   
SELECT @maxstat = 'R'  
if @stat = 'A' begin  
  SELECT @maxstat = 'Q'  
end  
if @stat = 'M' begin  
  SELECT @maxstat = 'M'  
end  
if @stat = 'P' begin  
  SELECT @minstat = 'N'  
  SELECT @maxstat = 'Q'  
end  
if @stat = 'R' begin  
  SELECT @minstat = 'R'  
  SELECT @maxstat = 'R'  
end  
if @stat = 'V' begin  
  SELECT @minstat = 'V'  
  SELECT @maxstat = 'V'  
end  
if @stat = 'K' begin  
  SELECT @minstat = 'K'  
  SELECT @maxstat = 'K'  
end  
  
   
select @sql = 'select part_no, description, category, sku_no, type_code, status'  
select @sql = @sql + ' from inv_master m ( NOLOCK )'  
select @sql = @sql + ' where (isnull(m.void,''' + @void + ''') like ''' + @void + ''')'  
select @sql = @sql + ' and (m.status between ''' + @minstat + ''' AND ''' + @maxstat + ''')'  
select @sql = @sql + ' and obsolete <= ' + convert(varchar,@iobs)  
--select @sql = @sql + ' and (m.type_code like ''' + @type + ''')' v1.0

select @sql = @sql + ' AND (''' + @type + ''' = ''%'' OR m.type_code IN (SELECT type_code FROM #types)) ' -- v1.0
  
if isnull(@org_id,'') != ''  
begin  
set @module = isnull(@module,'')  
select @sql = @sql + ' and exists (select 1 from inv_list l (nolock) where l.part_no = m.part_no and l.location in (select location from dbo.adm_get_related_locs_fn(''' + @module + ''',''' + @org_id + ''', ' + convert(varchar,@sec_level) + ')))'  
end  
  
if @sort='N'   
begin  
  if @strsort is not null    
    select @sql = @sql + ' and (m.part_no >= ''' + @strsort + ''')'  
  select @sql = @sql + ' order by m.part_no'  
end           
      
if @sort='D'   
begin  
  if @strsort is not null    
    select @sql = @sql + ' and ((m.description > ''' + @strsort + ''') OR (m.description = ''' + @strsort + ''' and part_no >= ''' + @lastkey + ''') )'  
  select @sql = @sql + ' order by m.description,m.part_no'  
end       
      
if @sort='K'   
begin  
  if @strsort is not null  
    select @sql = @sql + ' and (m.description like ''%' + @strsort + '%'' ) and (m.part_no >= ''' + @lastkey + ''')'  
  select @sql = @sql + ' order by m.part_no'  
end       
      
if @sort='S'   
begin  
  if @strsort is not null  
    select @sql = @sql + ' and ((m.sku_no > ''' + @strsort + ''') OR (m.sku_no = ''' + @strsort + ''' and part_no >= ''' + @lastkey + '''))'  
  select @sql = @sql + ' order by m.sku_no,m.part_no'  
end           
  
if @sort='U'   
begin  
  if @strsort is not null  
    select @sql = @sql + ' and ((m.upc_code > ''' + @strsort + ''') OR (m.upc_code = ''' + @strsort + ''' and part_no >= ''' + @lastkey + '''))'  
  select @sql = @sql + ' order by m.upc_code,m.part_no'  
end           
  
if @sort='C'   
begin  
  if @strsort is not null  
    select @sql = @sql + ' and ((m.category > ''' + @strsort + ''') OR (m.category = ''' + @strsort + ''' and part_no >= ''' + @lastkey + '''))'  
  select @sql = @sql + ' order by m.category,m.part_no'  
end       
  
  
print @sql  
exec (@sql)  
GO
GRANT EXECUTE ON  [dbo].[get_inv_mast] TO [public]
GO
