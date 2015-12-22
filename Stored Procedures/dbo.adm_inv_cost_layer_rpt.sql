SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[adm_inv_cost_layer_rpt] 
@range varchar(8000) = '0=0',
@type char(1) = '0'
as
set nocount on

declare @posting_range varchar(8000), @range1 varchar(8000)
select @posting_range = replace(@range,'i.part_no',' 0=0 or "a"')
select @posting_range = replace(@posting_range,'i.location',' 0=0 or "a"')
select @posting_range = replace(@posting_range,'l.organization_id',' 0=0 or "a"')
select @posting_range = replace(@posting_range,'r.region_id',' 0=0 or "a"')
select @posting_range = replace(@posting_range,'i.acct_code','acct_code')
select @posting_range = replace(@posting_range,'"','''')

create table #posting_accts (acct_code varchar(8), account_code varchar(32))
create index #pa1 on #posting_accts (acct_code)
create index #pa2 on #posting_accts (account_code)

exec ('insert #posting_accts select acct_code,inv_acct_code from in_account (nolock) where ' + @posting_range)
exec ('insert #posting_accts select acct_code,inv_direct_acct_code from in_account (nolock) where ' + @posting_range)
exec ('insert #posting_accts select acct_code,inv_ovhd_acct_code from in_account (nolock) where ' + @posting_range)
exec ('insert #posting_accts select acct_code,inv_util_acct_code from in_account (nolock) where ' + @posting_range)

create table #layers (part_no varchar(30), location varchar(10), in_stock decimal(20,8), description varchar(255) NULL,
hold_qty decimal(20,8),inv_cost_method char(1), acct_code varchar(8),
sequence int NULL, tran_date datetime NULL, tran_type char(1) NULL, tran_no int NULL, tran_ext int NULL, tran_line int NULL,
quantity decimal(20,8), balance decimal(20,8),
m_account_code varchar(32) NULL, m_cost decimal(20,8) NULL, d_account_code varchar(32) NULL, d_cost decimal(20,8) NULL, 
o_account_code varchar(32) NULL, o_cost decimal(20,8) NULL, u_account_code varchar(32) NULL, u_cost decimal(20,8) NULL, 
m_ti_cost decimal(20,8) NULL,d_ti_cost decimal(20,8) NULL,o_ti_cost decimal(20,8) NULL,u_ti_cost decimal(20,8) NULL,
m_tot_cost decimal(20,8) NULL,d_tot_cost decimal(20,8) NULL,o_tot_cost decimal(20,8) NULL,u_tot_cost decimal(20,8) NULL,
min_row_id int NULL,
row_id int identity, layer_ind int,
mtrl_cost decimal(20,8), dir_cost decimal(20,8), ovhd_cost decimal(20,8),
util_cost decimal(20,8))

select @range1 = replace(@range,'"','''')

exec ('insert #layers (
part_no, location, in_stock, description, hold_qty, inv_cost_method, acct_code, sequence, tran_date,
tran_type, tran_no, tran_ext, tran_line, quantity, balance,
m_account_code, m_cost, d_account_code, d_cost, o_account_code, o_cost, u_account_code, u_cost,
m_ti_cost, d_ti_cost, o_ti_cost, u_ti_cost,
m_tot_cost, d_tot_cost, o_tot_cost, u_tot_cost, layer_ind,
mtrl_cost, dir_cost, ovhd_cost, util_cost)
select distinct
i.part_no, i.location, i.in_stock, i.description, (i.hold_ord + i.hold_xfr),i.inv_cost_method, i.acct_code,
0, NULL, NULL,NULL,NULL,NULL,
(i.in_stock + i.hold_ord + i.hold_xfr), (i.in_stock + i.hold_ord + i.hold_xfr),
a.inv_acct_code, i.std_cost, 
a.inv_direct_acct_code, i.std_direct_dolrs, 
a.inv_ovhd_acct_code, i.std_ovhd_dolrs, 
a.inv_util_acct_code, i.std_util_dolrs,
0,0,0,0,
NULL,NULL,NULL,NULL, 0,
i.std_cost, i.std_direct_dolrs, i.std_ovhd_dolrs, i.std_util_dolrs
from inventory i
left outer join in_account a (nolock) on i.acct_code = a.acct_code 
join locations l (nolock) on l.location = i.location
join region_vw r (nolock) on l.organization_id = r.org_id
where i.status < ''R'' and i.inv_cost_method = ''S''  and (in_stock + hold_ord + hold_xfr) != 0
and ' + @range1)

exec ('insert #layers (
part_no, location, in_stock, description, hold_qty, inv_cost_method, acct_code, sequence, tran_date,
tran_type, tran_no, tran_ext, tran_line, quantity, balance,
m_account_code, m_cost, d_account_code, d_cost, o_account_code, o_cost, u_account_code, u_cost,
m_ti_cost, d_ti_cost, o_ti_cost, u_ti_cost,
m_tot_cost, d_tot_cost, o_tot_cost, u_tot_cost, layer_ind,
mtrl_cost, dir_cost, ovhd_cost, util_cost)
select distinct
i.part_no, i.location, i.in_stock, i.description, (i.hold_ord + i.hold_xfr),i.inv_cost_method, i.acct_code,
c.sequence, c.tran_date, c.tran_code, c.tran_no, c.tran_ext, c.tran_line,
isnull(c.quantity,0), isnull(c.balance,0), 
a.inv_acct_code, isnull(c.unit_cost,i.avg_cost), 
a.inv_direct_acct_code, isnull(c.direct_dolrs,i.avg_direct_dolrs), 
a.inv_ovhd_acct_code, isnull(c.ovhd_dolrs,i.avg_ovhd_dolrs), 
a.inv_util_acct_code, isnull(c.util_dolrs,i.avg_util_dolrs),
0,0,0,0,
c.tot_mtrl_cost, 
c.tot_dir_cost, 
c.tot_ovhd_cost,
c.tot_util_cost,
case when c.part_no is null then 0 else 1 end,
i.avg_cost, i.avg_direct_dolrs, i.avg_ovhd_dolrs, i.avg_util_dolrs
from inventory i
left outer join inv_costing c (nolock) on i.part_no = c.part_no and i.location = c.location and c.account = ''STOCK''
left outer join in_account a (nolock) on i.acct_code = a.acct_code 
join locations l (nolock) on l.location = i.location
join region_vw r (nolock) on l.organization_id = r.org_id
where i.status != ''R'' and i.inv_cost_method != ''S'' and '  + @range1)

update #layers
set m_tot_cost = case when charindex(inv_cost_method,'123456789') > 0 then 0 else isnull(m_tot_cost, balance * isnull(m_cost,0)) end,
 d_tot_cost = case when charindex(inv_cost_method,'123456789') > 0 then 0 else isnull(d_tot_cost, balance * isnull(d_cost,0)) end,
 o_tot_cost = case when charindex(inv_cost_method,'123456789') > 0 then 0 else isnull(o_tot_cost, balance * isnull(o_cost,0)) end,
 u_tot_cost = case when charindex(inv_cost_method,'123456789') > 0 then 0 else isnull(u_tot_cost, balance * isnull(u_cost,0)) end,
 m_ti_cost = round(mtrl_cost * (in_stock + hold_qty),8),
 d_ti_cost = round(dir_cost * (in_stock + hold_qty),8),
 o_ti_cost = round(ovhd_cost * (in_stock + hold_qty),8),
 u_ti_cost = round(util_cost * (in_stock + hold_qty),8)
 

update l
set min_row_id = t.row_id
from #layers l, 
(select part_no, location, min(row_id)
from #layers l1
group by part_no, location) as t(part_no, location, row_id)
where l.part_no = t.part_no and l.location = t.location

update #layers
set m_tot_cost = mtrl_cost * (in_stock + hold_qty), 
d_tot_cost = dir_cost * (in_stock + hold_qty), 
o_tot_cost = ovhd_cost * (in_stock + hold_qty), 
u_tot_cost = util_cost * (in_stock + hold_qty)
where min_row_id = row_id and charindex(inv_cost_method,'123456789') > 0

if @type = '1' -- only return out of balance cost layers
begin
  delete l
  from #layers l,
    (select part_no, location, (in_stock + hold_qty), 
    m_ti_cost, d_ti_cost, o_ti_cost, u_ti_cost,
    sum(balance), sum(m_tot_cost), sum(d_tot_cost), sum(o_tot_cost), sum(u_tot_cost), charindex(inv_cost_method,'123456789')
    from #layers
    group by part_no, location, in_stock , hold_qty, m_ti_cost, d_ti_cost, o_ti_cost, u_ti_cost,charindex(inv_cost_method,'123456789')
    having ((in_stock + hold_qty) = sum(balance) and
     round(m_ti_cost,4) = round(sum(m_tot_cost),4) and
     round(d_ti_cost,4) = round(sum(d_tot_cost),4) and
     round(o_ti_cost,4) = round(sum(o_tot_cost),4) and
     round(u_ti_cost,4) = round(sum(u_tot_cost),4)) or charindex(inv_cost_method,'123456789') > 0) 
     as t(part_no, location, in_stock, 
     mtrl_cost, dir_cost, ovhd_cost, util_cost, balance,
     m_tot_cost, d_tot_cost, o_tot_cost, u_tot_cost, inv_cost_method)
  where t.part_no = l.part_no and t.location = l.location
end

select 
l.part_no, l.location, l.description, l.in_stock, l.hold_qty, l.inv_cost_method, l.acct_code, sequence, tran_date,
tran_type, tran_no, tran_ext, tran_line, quantity, l.balance,
m_account_code, m_cost, d_account_code, d_cost, o_account_code, o_cost, u_account_code, u_cost,
m_tot_cost, d_tot_cost, o_tot_cost, u_tot_cost,
case when l.row_id = l.min_row_id then mtrl_cost else 0 end,
case when l.row_id = l.min_row_id then dir_cost  else 0 end,
case when l.row_id = l.min_row_id then ovhd_cost else 0 end,
case when l.row_id = l.min_row_id then util_cost else 0 end,
layer_ind
from #layers l


drop table #layers
GO
GRANT EXECUTE ON  [dbo].[adm_inv_cost_layer_rpt] TO [public]
GO
