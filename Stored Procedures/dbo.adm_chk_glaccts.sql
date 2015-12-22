SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_chk_glaccts] @window_name varchar(255), @acct_col varchar(255) = ''
AS	
create table #t1 (acct_code varchar(32), not_valid_for_user int, not_valid int, org_id varchar(30) NULL)
create index t1i on #t1(acct_code, not_valid_for_user)

--declare @org varchar(30)

if @acct_col = '**CLEARING ALL**'
begin
  select wname, dwindex, dwname, colname, row, o.acct_code , 0, 0
  from #online_glinfo o
  where wname = @window_name 
  return
end

if isnull(@acct_col,'') = ''
begin
  insert #t1
  select distinct acct_code, case when isnull(acct_code,'') = '' then 0 else 1 end,0, isnull(org_id,'')
  from #online_glinfo
  where wname = @window_name 
end
else
begin
  insert #t1
  select distinct acct_code, 1,0, isnull(org_id,'')
  from #online_glinfo
  where wname = @window_name and colname = @acct_col
end

update #t1
set not_valid_for_user = 0
from #t1, adm_glchart a (nolock)
where a.account_code = #t1.acct_code and ((a.org_id= #t1.org_id  AND ib_flag=1) OR ib_flag=0) 


update #t1
set not_valid = 1
from #t1, adm_glchart_all a
where a.account_code = #t1.acct_code 
and not_valid_for_user = 1

if isnull(@acct_col,'') = ''
begin
  select wname, dwindex, dwname, colname, row, o.acct_code , not_valid_for_user, not_valid
  from #online_glinfo o
  join #t1 on #t1.acct_code = o.acct_code
  where wname = @window_name
  order by row_id
end
else
begin
  select wname, dwindex, dwname, colname, row, o.acct_code , not_valid_for_user, not_valid
  from #online_glinfo o
  join #t1 on #t1.acct_code = o.acct_code
  where wname = @window_name and colname = @acct_col
  order by row_id
end
                                             
GO
GRANT EXECUTE ON  [dbo].[adm_chk_glaccts] TO [public]
GO
