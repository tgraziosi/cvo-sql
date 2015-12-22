SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create proc [dbo].[adm_inv_reconciliation] 
@range varchar(8000),
@type char(1),
@group char(1)
as
set nocount on
declare @range1 varchar(8000), @group_clause varchar(1000), @sql varchar(8000)
declare @root_org varchar(30)


Select @root_org = organization_id from Organization_all where outline_num = '1'

select @range1 = replace(@range,'g.adate','h.date_applied')
select @range1 = replace(@range1,'g.acode','d.account_code')
select @range1 = replace(@range1,'i.part',' 0=0 or "a"')
select @range1 = replace(@range1,'i.loc',' 0=0 or "a"')
select @range1 = replace(@range1,'a.pcode',' 0=0 or "a"')
select @range1 = replace(@range1,'"','''')

declare @posting_range varchar(8000)
select @posting_range = replace(@range,'g.adate','0=0 or 0')
select @posting_range = replace(@posting_range,'g.acode','0=0 or "a"')
select @posting_range = replace(@posting_range,'i.part',' 0=0 or "a"')
select @posting_range = replace(@posting_range,'i.loc',' 0=0 or "a"')
select @posting_range = replace(@posting_range,'a.pcode','acct_code')
select @posting_range = replace(@posting_range,'"','''')

create table #posting_accts (acct_code varchar(8), account_code varchar(32))
create index #pa1 on #posting_accts (acct_code)
create index #pa2 on #posting_accts (account_code)

if charindex ('acct_code',@posting_range) > 0 
begin
  exec ('insert #posting_accts select acct_code,dbo.adm_mask_acct_fn(a.inv_acct_code,''' + @root_org + ''') from in_account (nolock) where ' + @posting_range)
  exec ('insert #posting_accts select acct_code,dbo.adm_mask_acct_fn(a.inv_direct_acct_code,''' + @root_org + ''') from in_account (nolock) where ' + @posting_range)
  exec ('insert #posting_accts select acct_code,dbo.adm_mask_acct_fn(a.inv_ovhd_acct_code,''' + @root_org + ''') from in_account (nolock) where ' + @posting_range)
  exec ('insert #posting_accts select acct_code,dbo.adm_mask_acct_fn(a.inv_util_acct_code,''' + @root_org + ''') from in_account (nolock) where ' + @posting_range)
end
else
begin
  exec ('insert #posting_accts select acct_code,dbo.adm_mask_acct_fn(inv_acct_code,''' + @root_org + ''') from in_account (nolock)')
  exec ('insert #posting_accts select acct_code,dbo.adm_mask_acct_fn(inv_direct_acct_code,''' + @root_org + ''') from in_account (nolock)')
  exec ('insert #posting_accts select acct_code,dbo.adm_mask_acct_fn(inv_ovhd_acct_code,''' + @root_org + ''') from in_account (nolock)')
  exec ('insert #posting_accts select acct_code,dbo.adm_mask_acct_fn(inv_util_acct_code,''' + @root_org + ''') from in_account (nolock)')
end

declare @tran_dtl_range varchar(8000)
select @tran_dtl_range = replace(@range,'g.adate','0=0 or 0')
select @tran_dtl_range = replace(@tran_dtl_range,'i.part','0=0 or "a"')
select @tran_dtl_range = replace(@tran_dtl_range,'i.loc','0=0 or "a"')
select @tran_dtl_range = replace(@tran_dtl_range,'a.pcode','0=0 or "a"')
select @tran_dtl_range = replace(@tran_dtl_range,'"','''')

create table #tran (type char(1), part_no varchar(30), location varchar(10), in_stock decimal(20,8), tran_id int,
curr_date datetime, apply_date datetime, tran_type char(1), tran_no int, tran_ext int, tran_line int,
m_account_code varchar(32), m_cost decimal(20,8), d_account_code varchar(32), d_cost decimal(20,8), 
o_account_code varchar(32), o_cost decimal(20,8), u_account_code varchar(32), u_cost decimal(20,8), 
m_tot_cost decimal(20,8),d_tot_cost decimal(20,8),o_tot_cost decimal(20,8),u_tot_cost decimal(20,8),
inv_qty decimal(20,8), d_row_id int null, row_id int identity(1,1))

create table #tran_dtl (cost_type char(1), part_no varchar(30) NULL, location varchar(10) NULL, tran_id int NULL,
curr_date datetime, apply_date datetime, tran_type char(1) NULL, tran_no int NULL, tran_ext int NULL, tran_line int NULL,
inv_qty decimal(20,8), cost  decimal(20,8), account_code varchar(32), d_row_id int NULL, t_row_id int NULL, 
row_id int identity (1,1))

create index #t1 on #tran(m_account_code)
create index #t2 on #tran(d_account_code)
create index #t3 on #tran(o_account_code)
create index #t4 on #tran(u_account_code)
create index #t5 on #tran(curr_date)

create index #td2 on #tran_dtl (row_id)
create index #td1 on #tran_dtl (d_row_id, part_no, location, tran_type, tran_no, tran_ext, tran_line, account_code)

create table #gl (journal_ctrl_num varchar(16), journal_description varchar(30) null, date_entered int, date_applied int, 
app_id int, sequence_id int, account_code varchar(32), description varchar(40) null, date_posted int, trx_type int , 
balance decimal(20,8), nat_balance decimal(20,8), balance_oper decimal(20,8), nat_cur_code varchar(8), 
reference_code varchar(32) null, document_1 varchar(16), document_2 varchar(16), d_row_id int NULL, row_id int identity(1,1),
part_no varchar(30) NULL, location varchar(10) NULL)

create index #gl2 on #gl(row_id)
create index #gl1 on #gl(d_row_id, account_code, nat_cur_code, description, date_applied)

create table #in_gl (gl_row_id int, tran_id int null, tran_date datetime null, apply_date datetime, 
account_code varchar(32), line_descr varchar(50) null, trx_type char(1) null, tran_no int null, tran_ext int null, 
tran_line int  null, part_no varchar(30) null, location varchar(10) null, posted_flag char(1) NULL, date_posted datetime null,
balance decimal(20,8) null, nat_balance decimal(20,8) null, balance_oper decimal(20,8) null, nat_cur_code varchar(8),
reference_code varchar(32), tran_qty decimal(20,8) null, tran_cost decimal(20,8) null, 
g_description varchar(40) null, g_date_applied int null, g_row_id int NULL, t_row_id int NULL, row_id int identity(1,1),
g_document_1 varchar(16) null, g_document_2 varchar(16) null, inv_type char(1) NULL)

create index #igl1 on #in_gl(row_id)
create index #igl2 on #in_gl(posted_flag)
create index #igl3 on #in_gl(g_row_id)
create index #igl4 on #in_gl(t_row_id)

create table #links (lnk_type int,g_row_id int, d_row_id int, t_row_id int,
account_code varchar(32), reference_code varchar(32),
balance decimal(20,8), nat_balance decimal(20,8), balance_oper decimal(20,8),
nat_cur_code varchar(8), apply_date int, document_1 varchar(16), description varchar(40),
part_no varchar(30), location varchar(10), tran_type char(1), tran_no int,
tran_ext int, tran_line int, tran_id int, cost_type char(1))

create index l1 on #links(lnk_type,g_row_id,d_row_id)
create index l2 on #links(lnk_type,t_row_id,d_row_id)

--create index l1 on #links(account_code, reference_code, nat_cur_code, apply_date)
--create index l2 on #links(d_row_id,g_row_id)

declare @d_row_id int, @d_tran_id int , @d_tran_date datetime , @d_apply_date datetime, 
@d_account_code varchar(32), @d_line_descr varchar(50) ,@d_trx_type char(1), @d_tran_no int, @d_tran_ext int,@d_tran_line int ,
@d_part_no varchar(30), @d_location varchar(10), @d_posted_flag char(1), @d_date_posted datetime,
@d_balance decimal(20,8), @d_nat_balance decimal(20,8), @d_balance_oper decimal(20,8),@d_nat_cur_code varchar(8),
@d_reference_code varchar(32), @d_tran_qty decimal(20,8) , @d_tran_cost decimal(20,8),
@g_apply_date int, @g_row_id int, @g_description varchar(40), @g_balance decimal(20,8), @g_balance_oper decimal(20,8), 
@g_nat_balance decimal(20,8), @g_document_1 varchar(16), @g_document_2 varchar(16),
@t_row_id int, @t_diff decimal(20,8), @gl_where varchar(255)

select @sql = 'insert #gl (journal_ctrl_num, journal_description, date_entered, date_applied, app_id,
sequence_id, account_code, description, date_posted, trx_type, balance, nat_balance,
balance_oper, nat_cur_code, reference_code, document_1, document_2,part_no, location)
select d.journal_ctrl_num, h.journal_description, h.date_entered, h.date_applied, h.app_id,
d.sequence_id, d.account_code, d.description, d.date_posted, d.trx_type, d.balance, d.nat_balance,
d.balance_oper, d.nat_cur_code, d.reference_code, d.document_1, d.document_2,
ltrim(convert(varchar(30),case when  charindex('' / '',description) > 0 then substring(description,1,charindex(''/'',description)-2) else ''<unknown>'' end)),
ltrim(convert(varchar(10),case when charindex('' / '',description) > 0 then substring(description,charindex(''/'',description)+1,10) else ''<unknown>'' end))
from gltrx h (nolock)
join gltrxdet d (nolock) on d.journal_ctrl_num = h.journal_ctrl_num 
join (select distinct p.account_code from  #posting_accts p) as post_acct(a_code) on post_acct.a_code = dbo.adm_mask_acct_fn(d.account_code,''' + @root_org + ''')'

if charindex('date_applied',@range1) > 0 or charindex('account_code',@range1) > 0
  select @sql = @sql + ' and ' + @range1

exec (@sql)

if @range like '%i.part%' or @range like '%i.loc%'
begin
  select @range1 = replace(@range,'g.adate',' 0=0 or 0 ')
  select @range1 = replace(@range1,'g.acode','0=0 or 0 ')
  select @range1 = replace(@range1,'i.part',
    '  ltrim(convert(varchar(30),case when  charindex('' / '',description) > 0 then substring(description,1,charindex(''/'',description)-2) else '''' end)) ')
  select @range1 = replace(@range1,'i.loc',
    ' ltrim(convert(varchar(10),case when charindex('' / '',description) > 0 then substring(description,charindex(''/'',description)+1,10) else '''' end)) ')
  select @range1 = replace(@range1,'a.pcode','0=0 or "a" ')
  select @range1 = replace(@range1,'"','''')

  exec ('delete from #gl where not (' + @range1 + ')')
end

select @range1 = replace(@range,'g.adate',' datediff(day,"01/01/1900",apply_date) + 693596 ')
select @range1 = replace(@range1,'g.acode','account_code')
select @range1 = replace(@range1,'i.part',' t.part_no')
select @range1 = replace(@range1,'i.loc',' location')
select @range1 = replace(@range1,'a.pcode','0=0 or "a"')
select @range1 = replace(@range1,'"','''')

--ESC001 Trimmed g_description to 40 characters and g_document_ and g_document2 to 16 characters.
exec ('insert #in_gl (
gl_row_id, tran_id, tran_date, apply_date, account_code, line_descr,
trx_type, tran_no, tran_ext, tran_line, 
part_no, location, posted_flag, date_posted,
balance, nat_balance, balance_oper, nat_cur_code, reference_code, 
tran_qty, tran_cost, g_description, g_date_applied,g_document_1, g_document_2, inv_type)
select 
row_id, tran_id, tran_date, apply_date, account_code, line_descr,
trx_type, tran_no, tran_ext, tran_line, 
t.part_no, location, posted_flag, date_posted,
balance, nat_balance, balance_oper, nat_cur_code, isnull(reference_code,''''), 
tran_qty, tran_cost,
CASE trx_type
	    WHEN ''I'' THEN left(''GL Inv. Adjustment:'' + convert(varchar(11),tran_no),40) 
 	    WHEN ''X'' THEN left(''GL Inv. Transfer:'' + convert(varchar(11),tran_no) + ''-'' + convert(varchar(6),tran_line),40)	-- mls 1/24/01 SCR 20787
 	    WHEN ''R'' THEN left(''GL Inv. Receipt:'' + convert(varchar(11),tran_no) ,40)
 	    WHEN ''S'' THEN left(''GL Inv. Shipment:'' + convert(varchar(11),tran_no) + ''/'' + convert(varchar(3),tran_ext) + ''-'' + convert(varchar(6),tran_line),40)	-- mls 1/24/01 SCR 20787
 	    WHEN ''P'' THEN left(''GL Inv. Production:'' + convert(varchar(11),tran_no) + ''/'' + convert(varchar(3),tran_ext) + ''-'' + convert(varchar(6),tran_line),40)	-- mls 1/24/01 SCR 20787
	    WHEN ''C'' THEN left(''GL Inv. Manual Cost Adj.:'' + convert(varchar(11), tran_no) + ''/'' + convert(varchar(3),tran_ext),40) --RLT #2
	    WHEN ''L'' THEN left(''GL Inv. Landed Cost Adj.:'' + convert(varchar(11), tran_no) + ''/'' + convert(varchar(3), tran_ext),40) --RLT #2
            WHEN ''N'' THEN left(''GL Inv. Std Cost Adj.:'' + convert(varchar(11), tran_no),40)					-- mls 1/26/01 SCR 20430
	    ELSE left(''GL Cost transactions for Tran:'' + convert(varchar(11),tran_no) + ''/'' + convert(varchar(3),tran_ext) + ''-'' + convert(varchar(6),tran_line),40)	-- mls 1/24/01 SCR 20787
end,
datediff(day,''01/01/1900'',apply_date) + 693596,
left(trx_type + ''-'' + convert(char(8), tran_no) + ''-'' + convert(varchar(5), tran_ext) + ''.'' + convert(varchar(8),tran_line),16),
left(convert(char(10), tran_no) + ''-'' + convert(varchar(5), tran_ext) + ''.'' + convert(varchar(8),tran_line),16),
i.status
from in_gltrxdet t (nolock)
left outer join inv_master i (nolock) on i.part_no = t.part_no
join (select distinct account_code from #posting_accts) as post_acct (a_code) on post_acct.a_code = dbo.adm_mask_acct_fn(t.account_code,''' + @root_org + ''')
where balance != 0 and ' + @range1 )

select @range1 = replace(@range,'g.adate',' datediff(day,"01/01/1900",t.curr_date) + 693596 ')
select @range1 = replace(@range1,'g.acode','0=0 or "a"')
select @range1 = replace(@range1,'i.part',' t.part_no')
select @range1 = replace(@range1,'i.loc',' t.location')
select @range1 = replace(@range1,'a.pcode','t.acct_code')
select @range1 = replace(@range1,'"','''')

exec ('insert #tran (type, part_no, location, in_stock, 
tran_id, curr_date, apply_date, tran_type, tran_no, tran_ext, tran_line,
m_account_code , m_cost , 
d_account_code , d_cost , 
o_account_code , o_cost , 
u_account_code , u_cost ,
m_tot_cost, d_tot_cost, o_tot_cost, u_tot_cost, inv_qty)
select ''M'', t.part_no, t.location, (t.in_stock + t.hold_qty), 
t.tran_id, t.curr_date, t.apply_date, t.tran_type,
 t.tran_no, t.tran_ext, t.tran_line,
dbo.adm_mask_acct_fn(a.inv_acct_code,l.organization_id), case when inv_cost_method = ''S'' then std_mtrl_cost else avg_mtrl_cost end,
dbo.adm_mask_acct_fn(a.inv_direct_acct_code,l.organization_id), case when inv_cost_method = ''S'' then std_dir_cost else avg_dir_cost end,
dbo.adm_mask_acct_fn(a.inv_ovhd_acct_code,l.organization_id), case when inv_cost_method = ''S'' then std_ovhd_cost else avg_ovhd_cost end,
dbo.adm_mask_acct_fn(a.inv_util_acct_code,l.organization_id), case when inv_cost_method = ''S'' then std_util_cost else avg_util_cost end,
 inv_mtrl_cost, inv_dir_cost, inv_ovhd_cost, inv_util_cost, inv_qty
from inv_tran t (nolock), in_account a (nolock), locations l (nolock)
where t.location = l.location and t.update_ind = 0 and t.acct_code = a.acct_code and t.tran_type != ''''
and ' + @range1)

select @tran_dtl_range = replace(@tran_dtl_range,'g.acode','m_account_code')
exec ('insert #tran_dtl (cost_type, part_no, location, 
tran_id, curr_date, apply_date, tran_type, tran_no, tran_ext, tran_line, inv_qty, cost, account_code, t_row_id)
select case when type between ''B'' and ''Y'' then ''M'' else type end, part_no, location, 
tran_id, curr_date, apply_date, tran_type, tran_no, tran_ext, tran_line, inv_qty, m_tot_cost, m_account_code , row_id
from #tran t
where t.m_tot_cost != 0 and ' + @tran_dtl_range)

select @tran_dtl_range = replace(@tran_dtl_range,'m_account_code','d_account_code')
exec ('insert #tran_dtl (cost_type, part_no, location, 
tran_id, curr_date, apply_date, tran_type, tran_no, tran_ext, tran_line, inv_qty, cost, account_code, t_row_id)
select case when type between ''B'' and ''Y'' then ''D'' else type end, part_no, location, 
tran_id, curr_date, apply_date, tran_type, tran_no, tran_ext, tran_line, inv_qty, d_tot_cost, d_account_code , row_id
from #tran t
where t.d_tot_cost != 0 and ' + @tran_dtl_range)

select @tran_dtl_range = replace(@tran_dtl_range,'d_account_code','o_account_code')
exec ('insert #tran_dtl (cost_type, part_no, location, 
tran_id, curr_date, apply_date, tran_type, tran_no, tran_ext, tran_line, inv_qty, cost, account_code, t_row_id)
select case when type between ''B'' and ''Y'' then ''O'' else type end, part_no, location, 
tran_id, curr_date, apply_date, tran_type, tran_no, tran_ext, tran_line, inv_qty, o_tot_cost, o_account_code , row_id
from #tran t
where t.o_tot_cost != 0 and ' + @tran_dtl_range)

select @tran_dtl_range = replace(@tran_dtl_range,'o_account_code','u_account_code')
exec ('insert #tran_dtl (cost_type, part_no, location, 
tran_id, curr_date, apply_date, tran_type, tran_no, tran_ext, tran_line, inv_qty, cost, account_code, t_row_id)
select case when type between ''B'' and ''Y'' then ''U'' else type end, part_no, location, 
tran_id, curr_date, apply_date, tran_type, tran_no, tran_ext, tran_line, inv_qty, u_tot_cost, u_account_code , row_id
from #tran t
where t.u_tot_cost != 0 and ' + @tran_dtl_range)

declare @date1 int, @adate1 varchar(10)
select @date1 = isnull((select datediff(day,'01/01/1900',min(curr_date)) + 693596 from #tran),0)
select @adate1 = convert(varchar(10), @date1)

select @range1 = replace(@range,'g.adate',' 0=0 or 0 ')
select @range1 = replace(@range1,'g.acode','0=0 or "a"')
select @range1 = replace(@range1,'i.part',' t.part_no')
select @range1 = replace(@range1,'i.loc',' t.location')
select @range1 = replace(@range1,'a.pcode','t.acct_code')
select @range1 = replace(@range1,'"','''')

exec ('insert #tran (type, part_no, location, in_stock, 
tran_id, curr_date, apply_date, tran_type, tran_no, tran_ext, tran_line,
m_account_code , m_cost , 
d_account_code , d_cost , 
o_account_code , o_cost , 
u_account_code , u_cost ,
m_tot_cost, d_tot_cost, o_tot_cost, u_tot_cost, inv_qty)
select ''A'', t.part_no, t.location, (t.in_stock + t.hold_qty), 
t.tran_id, t.curr_date, t.apply_date, t.tran_type, t.tran_no, t.tran_ext, t.tran_line,
isnull(dbo.adm_mask_acct_fn(a.inv_acct_code,l.organization_id),''<UNKNOWN>''), case when inv_cost_method = ''S'' then std_mtrl_cost else avg_mtrl_cost end,
isnull(dbo.adm_mask_acct_fn(a.inv_direct_acct_code,l.organization_id),''<UNKNOWN>''), case when inv_cost_method = ''S'' then std_dir_cost else avg_dir_cost end,
isnull(dbo.adm_mask_acct_fn(a.inv_ovhd_acct_code,l.organization_id),''<UNKNOWN>''), case when inv_cost_method = ''S'' then std_ovhd_cost else avg_ovhd_cost end,
isnull(dbo.adm_mask_acct_fn(a.inv_util_acct_code,l.organization_id),''<UNKNOWN>''), case when inv_cost_method = ''S'' then std_util_cost else avg_util_cost end,
0,0,0,0,0
from inv_tran t (nolock)
join (select t3.part_no, t3.location, max(tran_id) from inv_tran t3 (nolock)
join (select part_no, location, max(curr_date) from inv_tran t2 (nolock)
 where  datediff(day,''01/01/1900'',curr_date) + 693596 < ' + @adate1 + '
 and t2.update_ind = 0
group by part_no, location)
as t2(part_no, location, curr_date) on t3.part_no = t2.part_no and t3.location = t2.location and t3.curr_date = t2.curr_date 
group by t3.part_no, t3.location)
as t2(part_no, location, tran_id) on t.part_no = t2.part_no and t.location = t2.location and t.tran_id = t2.tran_id
join locations l (nolock) on l.location = t.location
left outer join in_account a (nolock) on t.acct_code = a.acct_code 
where t.update_ind = 0 and ' + @range1 )

select @tran_dtl_range = replace(@tran_dtl_range,'u_account_code','m_account_code')
exec ('insert #tran_dtl (cost_type, part_no, location, tran_type,curr_date, apply_date, inv_qty, cost, account_code)
select ''B'', part_no, location, ''1'',max(curr_date),max(curr_date),sum(in_stock), sum(m_cost * in_stock), m_account_code
from #tran
where type = ''A'' and ' + @tran_dtl_range + '
group by part_no,location,m_account_code')

select @tran_dtl_range = replace(@tran_dtl_range,'m_account_code','d_account_code')
exec ('insert #tran_dtl (cost_type, part_no, location,tran_type,curr_date, apply_date, inv_qty, cost, account_code)
select ''B'', part_no, location,''1'',max(curr_date),max(curr_date),sum(in_stock), sum(d_cost * in_stock), d_account_code
from #tran
where type = ''A'' and ' + @tran_dtl_range + '
group by part_no,location,d_account_code')

select @tran_dtl_range = replace(@tran_dtl_range,'d_account_code','o_account_code')
exec ('insert #tran_dtl (cost_type, part_no, location,tran_type,curr_date, apply_date, inv_qty, cost, account_code)
select ''B'', part_no, location,''1'',max(curr_date),max(curr_date),sum(in_stock), sum(o_cost * in_stock), o_account_code
from #tran
where type = ''A'' and ' + @tran_dtl_range + '
group by part_no,location,o_account_code')

select @tran_dtl_range = replace(@tran_dtl_range,'o_account_code','u_account_code')
exec ('insert #tran_dtl (cost_type, part_no, location,tran_type,curr_date, apply_date, inv_qty, cost, account_code)
select ''B'', part_no, location,''1'',max(curr_date),max(curr_date),sum(in_stock), sum(u_cost * in_stock), u_account_code
from #tran
where type = ''A'' and ' + @tran_dtl_range + '
group by part_no,location,u_account_code')

if @type = 0 -- detail
begin
  insert #tran_dtl (cost_type, tran_type,curr_date, apply_date, inv_qty, cost, account_code)
  select 'A', '1',max(curr_date),max(curr_date),sum(inv_qty), sum(cost), account_code
  from #tran_dtl
  where cost_type = 'B'
  group by account_code

  delete from #tran_dtl
  where cost_type = 'B'
end
else
begin
  update #tran_dtl
  set cost_type = 'A'
  where cost_type = 'B'
end

insert #tran (type, part_no, location, in_stock, 
tran_id, curr_date, apply_date, tran_type, tran_no, tran_ext, tran_line,
m_account_code , m_cost , 
d_account_code , d_cost , 
o_account_code , o_cost , 
u_account_code , u_cost ,
m_tot_cost, d_tot_cost, o_tot_cost, u_tot_cost, inv_qty)
select 'Z', t.part_no, t.location, (t.in_stock ), 
t.tran_id, t.curr_date, t.apply_date, t.tran_type, t.tran_no, t.tran_ext, t.tran_line,
m_account_code , m_cost , 
d_account_code , d_cost , 
o_account_code , o_cost , 
u_account_code , u_cost ,
0,0,0,0,0
from #tran t
join (select t3.part_no, t3.location, max(tran_id) from #tran t3 (nolock)
join (select part_no, location, max(curr_date) from #tran t2 (nolock)
group by part_no, location)
as t2(part_no, location, curr_date) on t3.part_no = t2.part_no and t3.location = t2.location and t3.curr_date = t2.curr_date 
group by t3.part_no, t3.location)
as t2(part_no, location, tran_id) on t.part_no = t2.part_no and t.location = t2.location and t.tran_id = t2.tran_id


select @tran_dtl_range = replace(@tran_dtl_range,'u_account_code','m_account_code')
exec ('insert #tran_dtl (cost_type, part_no, location,tran_type,curr_date, apply_date, inv_qty, cost, account_code)
select ''B'', part_no, location,''2'',max(curr_date),max(curr_date),sum(in_stock), sum(m_cost * in_stock), m_account_code
from #tran
where type = ''Z'' and ' + @tran_dtl_range + '
group by part_no, location,m_account_code')

select @tran_dtl_range = replace(@tran_dtl_range,'m_account_code','d_account_code')
exec ('insert #tran_dtl (cost_type,part_no, location,tran_type,curr_date, apply_date, inv_qty, cost, account_code)
select ''B'', part_no, location,''2'',max(curr_date),max(curr_date),sum(in_stock), sum(d_cost * in_stock), d_account_code
from #tran
where type = ''Z'' and ' + @tran_dtl_range + '
group by part_no, location,d_account_code')

select @tran_dtl_range = replace(@tran_dtl_range,'d_account_code','o_account_code')
exec ('insert #tran_dtl (cost_type,part_no, location, tran_type,curr_date, apply_date, inv_qty, cost, account_code)
select ''B'', part_no, location,''2'',max(curr_date),max(curr_date),sum(in_stock), sum(o_cost * in_stock), o_account_code
from #tran
where type = ''Z'' and ' + @tran_dtl_range + '
group by part_no, location,o_account_code')

select @tran_dtl_range = replace(@tran_dtl_range,'o_account_code','u_account_code')
exec ('insert #tran_dtl (cost_type,part_no, location, tran_type,curr_date, apply_date, inv_qty, cost, account_code)
select ''B'', part_no, location,''2'',max(curr_date),max(curr_date),sum(in_stock), sum(u_cost * in_stock), u_account_code
from #tran
where type = ''Z'' and ' + @tran_dtl_range + '
group by part_no, location,u_account_code')


if @type = 0 -- detail
begin
  insert #tran_dtl (cost_type, tran_type,curr_date, apply_date, inv_qty, cost, account_code)
  select 'Z', '1',max(curr_date),max(curr_date),sum(inv_qty), sum(cost), account_code
  from #tran_dtl
  where cost_type = 'B'
  group by account_code

  delete from #tran_dtl
  where cost_type = 'B'
end
else
begin
  update #tran_dtl
  set cost_type = 'Z'
  where cost_type = 'B'
end

if @type = 0 -- detail
begin
insert #links
select 1,0,row_id, 0,
account_code, isnull(reference_code,''), 
balance,nat_balance,balance_oper,
nat_cur_code, g_date_applied, g_document_1, g_description,
part_no, location, trx_type, tran_no,
tran_ext, tran_line, tran_id, ''
from #in_gl
union
--insert #links
select 0,row_id, 0,0,
account_code, isnull(reference_code,''), 
balance,nat_balance,balance_oper,
nat_cur_code, date_applied, document_1, description,
'','','',0,0,0,0,''
from #gl
union
--insert #links
select 0,0, 0, row_id,
account_code, '', 
cost,0,0,
'', datediff(day,'01/01/1900',apply_date) + 693596, '','',
part_no, location,case tran_type when 'U' then 'P' when 'A' then 'R' 
when 'K' then 'S' else tran_type end,
case when tran_type = 'N' then tran_line else tran_no end, tran_ext, case when tran_type = 'N' then 0 else tran_line end,
tran_id,cost_type
from #tran_dtl

--insert #links
update l
set g_row_id = g.g_row_id
from #in_gl l,
(select max(g_row_id), max(d_row_id)
from #links l
group by account_code, reference_code, nat_cur_code, apply_date, balance, nat_balance, balance_oper,document_1)
as g(g_row_id, d_row_id)
where l.row_id = g.d_row_id
and g.g_row_id != 0

update l
set g_row_id = g.g_row_id
from #in_gl l,
(select max(g_row_id), max(d_row_id)
from #links l
group by account_code, reference_code, nat_cur_code, apply_date, balance, nat_balance, balance_oper, description)
as g(g_row_id, d_row_id)
where l.row_id = g.d_row_id and l.g_row_id is null
and g.g_row_id != 0

update l
set g_row_id = g.g_row_id
from #in_gl l,
(select max(g_row_id), max(d_row_id)
from #links l
group by account_code, reference_code, nat_cur_code, apply_date,  round(balance,4), round(nat_balance,4), round(balance_oper,4),document_1)
as g(g_row_id, d_row_id)
where l.row_id = g.d_row_id and l.g_row_id is null
and g.g_row_id != 0


update l
set g_row_id = g.g_row_id
from #in_gl l,
(select max(g_row_id), max(d_row_id)
from #links l
group by account_code, reference_code, nat_cur_code, apply_date, round(balance,2), round(nat_balance,2), round(balance_oper,2), document_1)
as g(g_row_id, d_row_id)
where l.row_id = g.d_row_id and l.g_row_id is null
and g.g_row_id != 0

update l
set g_row_id = g.g_row_id
from #in_gl l,
(select max(g_row_id), max(d_row_id)
from #links l
group by account_code, reference_code, nat_cur_code, apply_date, round(balance,2), round(nat_balance,2), round(balance_oper,2), description)
as g(g_row_id, d_row_id)
where l.row_id = g.d_row_id and l.g_row_id is null
and g.g_row_id != 0

update l
set t_row_id = t.t_row_id
from #in_gl l,
(select max(t_row_id), max(d_row_id)
from #links l where cost_type = '' or cost_type between 'B' and 'Y'
group by part_no, location, tran_type, tran_no, tran_ext, tran_line, tran_id, balance, account_code)
as t(t_row_id, d_row_id)
where l.row_id = t.d_row_id 
and t.t_row_id != 0

insert #in_gl (g_row_id, gl_row_id, t_row_id, balance, nat_balance, balance_oper,
  account_code, reference_code, nat_cur_code, apply_date, g_description, g_date_applied, g_document_1, g_document_2, trx_type)
select row_id, 0, 0, 0, 0, 0,
  account_code, isnull(reference_code,''), nat_cur_code, 
  dateadd(day,date_applied - 693596,'1/1/1900'), description, date_applied,
  document_1, document_2, '?'
from #gl
where row_id not in (select g_row_id from #in_gl)


insert #in_gl (g_row_id, gl_row_id, t_row_id,
  account_code, reference_code, nat_cur_code, apply_date, g_description, part_no, location, tran_id, g_document_1, g_document_2,
  trx_type, tran_no, tran_ext, tran_line, inv_type)
select 0,0,t.row_id, 
  t.account_code, '', '', 
  t.apply_date, 
case t.cost_type 
  when 'A' then 'Beginning Inventory Balance:'
  when 'Z' then 'Ending Inventory Balance:'
else
CASE t.tran_type  		--ESC limited all results to 40 characters
	    WHEN 'I' THEN left('GL Inv. Adjustment:' + convert(varchar(11),tran_no) ,40)
 	    WHEN 'X' THEN left('GL Inv. Transfer:' + convert(varchar(11),tran_no) + '-' + convert(varchar(6),tran_line),40)	-- mls 1/24/01 SCR 20787
 	    WHEN 'R' THEN left('GL Inv. Receipt:' + convert(varchar(11),tran_no) ,40)
 	    WHEN 'S' THEN left('GL Inv. Shipment:' + convert(varchar(11),tran_no) + '/' + convert(varchar(3),tran_ext) + '-' + convert(varchar(6),tran_line),40)	-- mls 1/24/01 SCR 20787
 	    WHEN 'K' THEN left('GL Inv. Shipment:' + convert(varchar(11),tran_no) + '/' + convert(varchar(3),tran_ext) + '-' + convert(varchar(6),tran_line),40)	-- mls 1/24/01 SCR 20787
 	    WHEN 'P' THEN left('GL Inv. Production:' + convert(varchar(11),tran_no) + '/' + convert(varchar(3),tran_ext) + '-' + convert(varchar(6),tran_line),40)	-- mls 1/24/01 SCR 20787
	    WHEN 'C' THEN left('GL Inv. Manual Cost Adj.:' + convert(varchar(11), tran_no) + '/' + convert(varchar(3),tran_ext),40) --RLT #2
	    WHEN 'L' THEN left('GL Inv. Landed Cost Adj.:' + convert(varchar(11), tran_no) + '/' + convert(varchar(3), tran_ext),40) --RLT #2
            WHEN 'N' THEN left('GL Inv. Std Cost Adj.:' + convert(varchar(11), tran_no),40)					-- mls 1/26/01 SCR 20430
	    ELSE left('GL Cost transactions for Tran:' + convert(varchar(11),tran_no) + '/' + convert(varchar(3),tran_ext) + '-' + convert(varchar(6),tran_line),40)	-- mls 1/24/01 SCR 20787
end
end, t.part_no, t.location, t.tran_id,
left(t.tran_type + '-' + convert(char(8), tran_no) + '-' + convert(varchar(5), tran_ext) + '.' + convert(varchar(8),tran_line),16), -- mls 10/4/04 SCR 33296
left(convert(char(10), tran_no) + '-' + convert(varchar(5), tran_ext) + '.' + convert(varchar(8),tran_line),16), -- mls 10/4/04 SCR 33296
case when cost_type = 'A' then '1' when cost_type = 'Z' then '2' else tran_type end, tran_no, tran_ext, tran_line,
i.status
from #tran_dtl t
left outer join inv_master i (nolock) on i.part_no = t.part_no
where (row_id not in (select t_row_id from #in_gl) or cost_type in ('A','Z'))	-- mls 5/7/09
end

if @type = '0' -- detail report
begin
select d.account_code, 
CASE isnull(t.tran_type,d.trx_type)
  when '1' then 'Beginning Inventory Balance:'
  when '2' then 'Ending Inventory Balance:'
  WHEN 'I' THEN 'Inv. Adjustment:' + convert(varchar(11),d.tran_no) 
  WHEN 'X' THEN 'Transfer:' + convert(varchar(11),d.tran_no) + '-' + convert(varchar(6),d.tran_line)	-- mls 1/24/01 SCR 20787
  WHEN 'A' THEN 'Rcpt Adjustment:' + convert(varchar(11),d.tran_no) 
  WHEN 'R' THEN 'Receipt:' + convert(varchar(11),d.tran_no) 
  WHEN 'S' THEN 'Shipment:' + convert(varchar(11),d.tran_no) + '/' + convert(varchar(3),d.tran_ext) + '-' + convert(varchar(6),d.tran_line)	-- mls 1/24/01 SCR 20787
  WHEN 'K' THEN 'Shipment:' + convert(varchar(11),d.tran_no) + '/' + convert(varchar(3),d.tran_ext) + '-' + convert(varchar(6),d.tran_line)	-- mls 1/24/01 SCR 20787
  WHEN 'U' THEN 
    case when isnull(inv_type,'') = 'R' then    
      'Res Usage:' else 'Prod Usage:' end + convert(varchar(11),d.tran_no) + '/' + convert(varchar(3),d.tran_ext) + '-' + convert(varchar(6),d.tran_line)	-- mls 1/24/01 SCR 20787
  WHEN 'P' THEN 
    case when isnull(inv_type,'') = 'R' then    
      'Res Usage:' else 'Production:' end  + convert(varchar(11),d.tran_no) + '/' + convert(varchar(3),d.tran_ext) + '-' + convert(varchar(6),d.tran_line)
  WHEN 'C' THEN 'Manual Cost Adj.:' + convert(varchar(11), d.tran_no) + '/' + convert(varchar(3),d.tran_ext) --RLT #2
  WHEN 'L' THEN 'Landed Cost Adj.:' + convert(varchar(11), d.tran_no) + '/' + convert(varchar(3), d.tran_ext) --RLT #2
  WHEN 'N' THEN 'Std Cost Adj.:' + convert(varchar(11), d.tran_no)					-- mls 1/26/01 SCR 20430
  ELSE 'GL Cost transactions for Tran:' + convert(varchar(11),d.tran_no) + '/' + convert(varchar(3),d.tran_ext) + '-' + convert(varchar(6),d.tran_line)	-- mls 1/24/01 SCR 20787
end,
d.apply_date, isnull(d.reference_code,''),d.nat_cur_code, 
d.part_no, d.location, d.tran_id,
g.journal_ctrl_num,  g.sequence_id,
dateadd(day,g.date_entered - 693596,'1/1/1900') 'gl date entered',
case when g.date_posted = 0 then NULL else dateadd(day,g.date_posted - 693596,'1/1/1900') end 'gl date posted', 
isnull(g.balance,0), isnull(g.nat_balance,0), isnull(g.balance_oper,0),
g.journal_description, isnull(g.row_id,0),
d.tran_date 'distr tran date', d.line_descr, case when d.posted_flag != 'S' then NULL else d.date_posted end 'distr date posted',
isnull(d.balance,0), isnull(d.nat_balance,0), isnull(d.balance_oper,0), isnull(d.gl_row_id,0),
t.curr_date, case when isnull(t.cost_type,'Z') != 'Z' then t.cost else 0 end,
isnull(t.cost_type,'M'), t.inv_qty,
case when isnull(t.cost_type,'') in ('A','Z') then isnull(t.cost,0) else 0 end,
isnull(t.row_id,0)
from #in_gl d
left outer join #gl g on  g.row_id = d.g_row_id 
left outer join #tran_dtl t on t.row_id = d.t_row_id
order by d.account_code, t.cost_type
end
else -- summary report
begin
  if @group = 1   -- by account
  begin
    select t.account_code, '','',sum(g_balance), sum(g_nat_balance), sum(g_balance_oper),
    sum(d_balance),sum(d_nat_balance), sum(d_balance_oper),
    sum(t_beg), sum(t_tot), sum(t_end),1
    from
      (select g.account_code,
        sum(isnull(g.balance,0)), sum(isnull(g.nat_balance,0)), sum(isnull(g.balance_oper,0)),
        0,0,0,0,0,0
      from #gl g
      group by account_code
      union
      select d.account_code, 0,0,0,
        sum(isnull(d.balance,0)), sum(isnull(d.nat_balance,0)), sum(isnull(d.balance_oper,0)), 
        0,0,0
      from #in_gl d
      group by account_code
      union
      select t.account_code, 0,0,0,0,0,0,
        sum(case when isnull(t.cost_type,'') = 'A' then isnull(t.cost,0) else 0 end),    -- tot beginning balance
        sum(case when isnull(t.cost_type,'Z') not in ('A','Z') then isnull(t.cost,0) else 0 end), -- tot transactions
        sum(case when isnull(t.cost_type,'Z') = 'Z' then isnull(t.cost,0) else 0 end) -- tot ending balance
      from #tran_dtl t
      group by account_code
      ) as t(account_code, g_balance, g_nat_balance, g_balance_oper, d_balance,d_nat_balance, d_balance_oper, t_beg, t_tot, t_end)
    group by account_code
    order by account_code
  end
  else if @group = 2   -- by account, location
  begin
    select t.account_code, '',t.location,sum(g_balance), sum(g_nat_balance), sum(g_balance_oper),
    sum(d_balance),sum(d_nat_balance), sum(d_balance_oper),
    sum(t_beg), sum(t_tot), sum(t_end),2
    from
      (select g.account_code,location,
        sum(isnull(g.balance,0)), sum(isnull(g.nat_balance,0)), sum(isnull(g.balance_oper,0)),
        0,0,0,0,0,0
      from #gl g
      group by account_code, location
      union
      select d.account_code, d.location,0,0,0,
        sum(isnull(d.balance,0)), sum(isnull(d.nat_balance,0)), sum(isnull(d.balance_oper,0)), 
        0,0,0
      from #in_gl d
      group by account_code, location
      union
      select t.account_code, t.location, 0,0,0,0,0,0,
        sum(case when isnull(t.cost_type,'') = 'A' then isnull(t.cost,0) else 0 end),    -- tot beginning balance
        sum(case when isnull(t.cost_type,'Z') not in ('A','Z') then isnull(t.cost,0) else 0 end), -- tot transactions
        sum(case when isnull(t.cost_type,'Z') = 'Z' then isnull(t.cost,0) else 0 end) -- tot ending balance
      from #tran_dtl t
      group by account_code, location
      ) as t(account_code, location,g_balance, g_nat_balance, g_balance_oper,
        d_balance,d_nat_balance, d_balance_oper, t_beg, t_tot, t_end)
    group by account_code,location
    order by account_code, location
  end
  else    -- by account, location, part_no
  begin
    select t.account_code, t.part_no,t.location,sum(g_balance), sum(g_nat_balance), sum(g_balance_oper),
    sum(d_balance),sum(d_nat_balance), sum(d_balance_oper),
    sum(t_beg), sum(t_tot), sum(t_end),3
    from
      (select g.account_code,part_no, location,
        sum(isnull(g.balance,0)), sum(isnull(g.nat_balance,0)), sum(isnull(g.balance_oper,0)),
        0,0,0,0,0,0
      from #gl g
      group by account_code, part_no,location
      union
      select d.account_code, d.part_no,d.location,0,0,0,
        sum(isnull(d.balance,0)), sum(isnull(d.nat_balance,0)), sum(isnull(d.balance_oper,0)), 
        0,0,0
      from #in_gl d
      group by account_code, part_no,location
      union
      select t.account_code, t.part_no,t.location, 0,0,0,0,0,0,
        sum(case when isnull(t.cost_type,'') = 'A' then isnull(t.cost,0) else 0 end),    -- tot beginning balance
        sum(case when isnull(t.cost_type,'Z') not in ('A','Z') then isnull(t.cost,0) else 0 end), -- tot transactions
        sum(case when isnull(t.cost_type,'Z') = 'Z' then isnull(t.cost,0) else 0 end) -- tot ending balance
      from #tran_dtl t
      group by account_code, part_no, location
      ) as t(account_code, part_no,location,g_balance, g_nat_balance, g_balance_oper,
        d_balance,d_nat_balance, d_balance_oper, t_beg, t_tot, t_end)
    group by account_code,part_no,location
    order by account_code, location, part_no
  end
end

drop table #gl
drop table #in_gl
drop table #tran
drop table #tran_dtl
GO
GRANT EXECUTE ON  [dbo].[adm_inv_reconciliation] TO [public]
GO
