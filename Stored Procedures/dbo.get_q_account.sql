SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_account] @search varchar(50), @type char(1), @secured_mode int = 0 , @org_id varchar(30) = '' AS


set @secured_mode =  isnull(@secured_mode,0)
set rowcount 100
declare @acct varchar(50), @acctdesc varchar(100)
declare @cmd varchar(1000), @glchart_table varchar(30)

if @secured_mode = 0 
  select @glchart_table = 'adm_glchart_all'
else if @secured_mode = 2
  select @glchart_table = 'adm_glchart_root'
else
  select @glchart_table = 'adm_glchart'





if @type='1'
BEGIN
   select @cmd = 'SELECT account_code,account_description ' + 
	'FROM ' + @glchart_table + ' (nolock) ' +
	'WHERE inactive_flag = 0 ' +
	' and substring(account_code,1,datalength(''' + @search + ''')) >= ''' + @search + ''' ' 

    if @secured_mode = 1 and isnull(@org_id,'') != ''
        select @cmd = @cmd + ' and ((org_id = ''' + @org_id + ''' and ib_flag = 1) or ib_flag = 0)'

    select @cmd = @cmd + ' order by account_code'

    exec (@cmd)
END

if @type='2'
BEGIN
    select @cmd = 'SELECT account_code,account_description ' + 
	'FROM ' + @glchart_table + ' (nolock) ' +
	'WHERE inactive_flag = 0 ' +
	' and account_description >= ''' + @search + ''' ' 

    if @secured_mode = 1 and isnull(@org_id,'') != ''
        select @cmd = @cmd + ' and ((org_id = ''' + @org_id + ''' and ib_flag = 1) or ib_flag = 0)'

    select @cmd = @cmd + ' order by account_description'
    exec (@cmd)
END


if @type='F' or @type='N' or @type='P' or @type='L' begin
   create table #tacct ( account_code varchar(50) )
   if @type='F' begin
      select @cmd = 'SELECT min(account_code) '
      select @cmd = @cmd + 'FROM ' + @glchart_table + ' (nolock) ' 
      select @cmd = @cmd + 'WHERE inactive_flag = 0'
   end
   if @type='N' begin
      select @cmd = 'SELECT min(account_code)'
      select @cmd = @cmd + 'FROM ' + @glchart_table + ' (nolock) ' 
      select @cmd = @cmd + 'WHERE inactive_flag = 0 ' 
      select @cmd = @cmd + '  and substring(account_code,1,datalength(''' + @search + ''')) > ''' + @search + ''''
   end
   if @type='P' begin
      select @cmd = 'SELECT max(account_code)'
      select @cmd = @cmd + 'FROM ' + @glchart_table + ' (nolock) ' 
      select @cmd = @cmd + 'WHERE inactive_flag = 0 ' 
      select @cmd = @cmd + '  and substring(account_code,1,datalength(''' + @search + ''')) < ''' + @search + ''''
   end
   if @type='L' begin
      select @cmd = 'SELECT max(account_code)'
      select @cmd = @cmd + 'FROM ' + @glchart_table + ' (nolock) ' 
      select @cmd = @cmd + 'WHERE inactive_flag = 0 '
   end

   if @secured_mode = 1 and isnull(@org_id,'') != ''
     select @cmd = @cmd + ' and ((org_id = ''' + @org_id + ''' and ib_flag = 1) or ib_flag = 0)'

   insert #tacct exec( @cmd )
   select @search = account_code, @type='O' from #tacct
   drop table #tacct
end
if @type='O'
BEGIN
   select @cmd = 'SELECT account_code, account_description '
   select @cmd = @cmd + 'FROM ' + @glchart_table + ' (nolock) ' 
   select @cmd = @cmd + 'WHERE inactive_flag = 0 ' 
   select @cmd = @cmd + ' and account_code = '''  + @search  + ''''

   if @secured_mode = 1 and isnull(@org_id,'') != ''
     select @cmd = @cmd + ' and ((org_id = ''' + @org_id + ''' and ib_flag = 1) or ib_flag = 0)'

   exec( @cmd )
END

GO
GRANT EXECUTE ON  [dbo].[get_q_account] TO [public]
GO
