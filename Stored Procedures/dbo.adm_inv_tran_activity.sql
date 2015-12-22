SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create proc [dbo].[adm_inv_tran_activity] 
@range varchar(8000),
@type char(1)
as
declare @range1 varchar(8000)

create table #activity
(tran_type varchar(20) null, tran_no varchar(20) null, location varchar(10) null, part_no varchar(30) null,
description varchar(255) null, qty decimal(20,8) null, tran_date datetime null, in_stock decimal(20,8) null,
update_typ char(1) NULL, tran_typ char(1) NULL, hold_qty decimal(20,8) NULL, status char(1) NULL, tran_id int)

create index a1 on #activity(location,part_no,description,tran_date)
create index a2 on #activity(location,part_no,tran_typ,status,qty)

create table #summary
(location varchar(10) null, part_no varchar(30) null,
description varchar(255) null, 
max_date datetime,
begin_stock decimal(20,8) null,
in_stock decimal(20,8) null,
hold_qty decimal(20,8) NULL,
rec_qty decimal(20,8) null,
ship_qty decimal(20,8) null,
sales_qty decimal(20,8) null,
xfer_to decimal(20,8) null,
xfer_from decimal(20,8) null,
iss_qty decimal(20,8) null,
mfg_qty decimal(20,8) null,
used_qty decimal(20,8) null,
begin_hold decimal(20,8) NULL)

select @range1 = replace(@range,'t.adate',' datediff(day,"01/01/1900",t.curr_date) + 693596 ')
select @range1 = replace(@range1,'i.part_no','t.part_no')
select @range1 = replace(@range1,'i.location','t.location')
select @range1 = replace(@range1,'"','''')

exec ('insert #activity
select distinct
case t.tran_type
when ''I'' then ''Issue''
when ''R'' then ''Receipt''
when ''S'' then ''Sales Order''
when ''X'' then ''Transfer''
when ''N'' then ''New Cost''
when ''C'' then ''Cst Layer Adj''
when ''A'' then ''Rcpt Adjust''
when ''P'' then ''Production''
when ''U'' then ''Usage''
when ''K'' then ''SO Kit''
when ''H'' then ''Release QC Adj''
else ''Unknown ('' + t.tran_type + '')''
end ,
convert(varchar(10), tran_no) + ''-'' + convert(varchar(10), tran_ext),
t.location,
t.part_no, 
i.description,
t.inv_qty,
t.curr_date,
t.in_stock,
t.update_typ,
t.tran_type,
t.hold_qty,
t.tran_status,
t.tran_id
from inv_tran t (nolock), inv_master i (nolock), locations l (nolock), region_vw r (nolock)
where t.part_no = i.part_no and t.tran_type != '''' and update_typ in (''I'',''H'')
and t.location = l.location and l.organization_id = r.org_id
and ' + @range1)

declare @range2 varchar(8000)
select @range2 = replace(@range, 't.adate >=','t.adate <')
select @range2 = replace(@range2, 't.adate <=','t.adate <')
select @range2 = replace(@range2,'t.adate',' datediff(day,"01/01/1900",d.curr_date) + 693596 ')
select @range2 = replace(@range2,'i.part_no','d.part_no')
select @range2 = replace(@range2,'i.location','d.location')
select @range2 = replace(@range2,'"','''')

if @range2 like '%d.curr_date%'
begin

select @range1 = replace(@range,'t.adate',' 0=0 or 0 ')
select @range1 = replace(@range1,'i.part_no','t.part_no')
select @range1 = replace(@range1,'i.location','t.location')
select @range1 = replace(@range1,'l.organization_id',' 0=0 or "a"')
select @range1 = replace(@range1,'r.region_id',' 0=0 or "a"')
select @range1 = replace(@range1,'"','''')

exec ('insert #activity
select
''Begin'',
'''',
t.location,
t.part_no, 
i.description,
t.in_stock,
t.curr_date,
t.in_stock,
''I'',
''B'',
t.hold_qty,
'''', 0
from inv_tran t (nolock), inv_master i (nolock),
(select d.part_no, d.location, max(it.tran_id)
from inv_tran it,
(select d.part_no, d.location, max(curr_date)
from inv_tran d (nolock), locations l (nolock), region_vw r (nolock)
where d.location = l.location and l.organization_id = r.org_id and ' + @range2 + '
group by d.part_no, d.location) as d(part_no, location, curr_date)
where d.part_no = it.part_no and d.location = it.location and d.curr_date = it.curr_date
group by d.part_no, d.location)
as d(part_no, location, tran_id)
where t.part_no = i.part_no and t.part_no = d.part_no and t.location = d.location
and t.tran_id = d.tran_id
and exists (select 1 from #activity a where a.part_no = t.part_no and a.location = t.location)
and ' + @range1)						-- mls 3/10/06 SCR 36283
end

if not exists (select 1 from #activity where tran_type = 'Begin')
and exists (select 1 from inv_tran where tran_type = '')
begin
exec ('insert #activity
select
''Begin'',
'''',
t.location,
t.part_no, 
i.description,
t.in_stock,
t.curr_date,
t.in_stock,
''I'',
''B'',
t.hold_qty,
'''', 0
from inv_tran t, inv_master i,
(select d.part_no, d.location, max(it.tran_id)
from inv_tran it,
(select part_no, location, max(curr_date)
from inv_tran d 
where tran_type = ''''
group by part_no, location) as d(part_no, location, curr_date)
where it.part_no = d.part_no and it.location = d.location and it.curr_date = d.curr_date
group by d.part_no, d.location)
as d(part_no, location, tran_id)
where t.part_no = i.part_no and t.part_no = d.part_no and t.location = d.location
and t.tran_id = d.tran_id
and exists (select 1 from #activity a where a.part_no = t.part_no and a.location = t.location)
and ' + @range1)						-- mls 3/10/06 SCR 36283
end

if @type = '0' -- detail report
begin
  select tran_type, tran_no, location, part_no, description,
    qty, tran_date, in_stock, update_typ, tran_typ, hold_qty, status
  from #activity
  order by location,part_no,tran_date, tran_no
end 
else
begin

insert #summary (location, part_no, description, max_date,begin_stock,begin_hold,
in_stock, hold_qty, rec_qty, ship_qty, xfer_to, xfer_from, mfg_qty, used_qty, iss_qty)
select distinct a.location, a.part_no, a.description, max(a.tran_date), 
sum(case when tran_typ = 'B' then qty else 0 end),
sum(case when tran_typ = 'B' then hold_qty else 0 end),
sum(case when a.tran_date = t.tran_date then in_stock else 0 end),
sum(case when a.tran_date = t.tran_date then hold_qty else 0 end),
sum(case when tran_typ in ('R','A') then qty else 0 end),
sum(case when tran_typ in ('S','K') and status = 'S' then qty else 0 end),
sum(case when tran_typ = 'X' and qty > 0 then qty else 0 end),
sum(case when tran_typ = 'X' and qty < 0 and status = 'R' then qty else 0 end),
sum(case when tran_typ = 'P' then qty else 0 end),
sum(case when tran_typ = 'U' then qty else 0 end),
sum(case when tran_typ in ('I','H') then qty else 0 end)
from #activity a,
(select part_no, location, max(tran_date)
from #activity
group by part_no, location) as t(part_no, location, tran_date)
where a.part_no = t.part_no and a.location = t.location
group by a.location, a.part_no, a.description


select location, part_no, description, begin_stock, in_stock, rec_qty, ship_qty, sales_qty,
xfer_to, xfer_from, iss_qty, mfg_qty, used_qty, hold_qty, begin_hold
from #summary
order by location, part_no
end

drop table #activity

GO
GRANT EXECUTE ON  [dbo].[adm_inv_tran_activity] TO [public]
GO
