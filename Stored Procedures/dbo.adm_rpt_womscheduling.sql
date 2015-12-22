SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



create procedure [dbo].[adm_rpt_womscheduling] 
  @range varchar(8000),  @sched_name varchar(16), @planned_ind int, @group_ind int, 
  @wo_date_ind int = 1
AS
BEGIN
set nocount on

declare
  @sched_id	INT,
  @part_no	VARCHAR(30),
  @beg_date	DATETIME,
  @end_date	DATETIME
DECLARE	@sql_txt varchar(8000), @range1 varchar(8000),  @inv_master_ind int


select @sched_id = sched_id,
  @sched_name = sched_name
from sched_model 
where lower(sched_name) = lower(@sched_name)

IF @@rowcount = 0
BEGIN
  RaisError 69010 'Schedule model does not exist.'
  RETURN
END

CREATE TABLE #location  (location VARCHAR(10))
create index l1 on #location(location)

create table #part (part_no varchar(30))
create index p1 on #part(part_no)




select @range1 = replace(@range,'SL.location','Upper(SL.location)')
select @range1 = replace(@range1,'i.part_no','0=0 or ""')
select @range1 = replace(@range1,'i.vendor','0=0 or ""')
select @range1 = replace(@range1,'i.buyer','0=0 or ""')
select @range1 = replace(@range1,'i.status','0=0 or ""')
select @range1 = replace(@range1,'r.tdate','0=0 or ""')
select @range1 = replace(@range1,'"','''')

select @sql_txt = 'INSERT	#location(location)
  SELECT	SL.location
  FROM sched_location SL (nolock), locations l (nolock), region_vw r (nolock)
  WHERE	SL.sched_id = ' + convert(varchar(10),@sched_id) + ' and 
      l.location = SL.location and 
      l.organization_id = r.org_id and ' + @range1

exec (@sql_txt)

select @inv_master_ind = 0
if (charindex('i.part_no',@range) > 0 or  charindex('i.vendor',@range) > 0 or
  charindex('i.buyer',@range) > 0 or  charindex('i.status',@range) > 0 )
begin
  select @inv_master_ind = 1
  select @range1 = replace(@range,'i.part_no','Upper(i.part_no)')
  select @range1 = replace(@range1,'i.vendor','Upper(i.vendor)')
  select @range1 = replace(@range1,'i.buyer','Upper(i.buyer)')
  select @range1 = replace(@range1,'r.tdate','0=0 or ""')
  if (charindex('i.status',@range1) > 0 )
  begin
    select @range1 = replace(@range1,'Custom-Kit','C')
    select @range1 = replace(@range1,'Make/Routed','H')
    select @range1 = replace(@range1,'Auto-Kit','K')
    select @range1 = replace(@range1,'Make','M')
    select @range1 = replace(@range1,'Purchase/Outsource','Q')
    select @range1 = replace(@range1,'Purchase','P')
  end

  select @range1 = replace(@range1,'i.status','Upper(i.status)')
  select @range1 = replace(@range1,'SL.location','0=0 or ""')
  select @range1 = replace(@range1,'l.organization_id','0=0 or ""')
  select @range1 = replace(@range1,'r.region_id','0=0 or ""')
  select @range1 = replace(@range1,'"','''')

  select @sql_txt = 'INSERT	#part(part_no)
    SELECT i.part_no
    FROM inv_master i (nolock)
    WHERE ' + @range1

  exec (@sql_txt)
end


CREATE TABLE #result (
  tran_id int,
  part_no varchar(30),
  location varchar(10),
  dep_part_no varchar(30),
  dep_location varchar(10),
  supply_ind int,
  planned_ind int,
  tran_date datetime,
  tran_qty decimal(20,8),
  tran_no int NULL,
  tran_ext int NULL,
  tran_line int NULL,
  tran_type char(1),
  tran_table char(2),
  forecast_qty decimal(20,8) NULL,
  forecast_date datetime,
  row_id int identity)

create index r1 on #result(tran_type,planned_ind,row_id)
create index r2 on #result(row_id)
create index r3 on #result(tran_date,supply_ind desc)

CREATE TABLE #final_result (
  tran_id int,
  part_no varchar(30),
  location varchar(10),
  dep_part_no varchar(30),
  dep_location varchar(10),
  supply_ind int,
  planned_ind int,
  tran_date datetime,
  tran_qty decimal(20,8),
  tran_no int NULL,
  tran_ext int NULL,
  tran_line int NULL,
  tran_type char(1),
  tran_table char(2),
  forecast_qty decimal(20,8) NULL,
  forecast_date datetime,
  supply_qty decimal(20,8),
  demand_qty decimal(20,8),
  running_bal decimal(20,8),
  group1 varchar(50) NULL,
  group2 varchar(50) NULL,
  group3 varchar(50) NULL,
  group4 varchar(50) NULL,
  row_id int identity(1,1)
)
create index fr1 on #final_result(row_id)
create index fr2 on #final_result(part_no,location,row_id)
create index fr3 on #final_result(tran_type,part_no,location)


select @sql_txt = 'insert #result (tran_id,part_no,location,dep_part_no,dep_location,supply_ind,planned_ind,
  tran_date,tran_qty,tran_no,tran_ext,tran_line,tran_type,tran_table)
  select SP.sched_process_id, SI.part_no, SI.location, 
    SPI.part_no, SPI.location,0,  case when SP.source_flag = ''P'' then 1 else 0 end, 
    case when ' + convert(varchar,@wo_date_ind) + '=0 then SO.work_datetime else isnull(P.sch_date,SO.work_datetime) end, 
    SOI.uom_qty * -1, SP.prod_no, SP.prod_ext, 0,''U'',''PR''
  FROM	#location L'


  select @sql_txt = @sql_txt + '
  join sched_item SI on SI.location = L.location and SI.sched_id = ' + convert(varchar(10),@sched_id) + '
  join sched_operation_item SOI on SOI.sched_item_id = SI.sched_item_id
  join sched_operation SO on SO.sched_operation_id = SOI.sched_operation_id
  join sched_process SP on SP.sched_id = SI.sched_id AND SP.sched_process_id = SO.sched_process_id
  join sched_item SPI on SPI.sched_process_id = SP.sched_process_id
  left outer join produce_all P on P.prod_no = SP.prod_no and P.prod_ext = SP.prod_ext and SP.source_flag != ''P'''

if @inv_master_ind = 1
  select @sql_txt = @sql_txt + '
   join #part i on i.part_no = SI.part_no'

exec (@sql_txt)

declare @row int, @proc_id int
select @row = isnull((select min(row_id) from #result where tran_type = 'U' and planned_ind = 1),0)
while @row != 0
begin

  insert #result (tran_id,part_no,location,dep_part_no,dep_location,supply_ind,planned_ind,
    tran_date,tran_qty,tran_no,tran_ext,tran_line,tran_type,tran_table)
  select SP.sched_process_id, r.part_no, r.location, SI.part_no, SI.location,0, 
    case when SP.source_flag = 'P' then 1 else 0 end, 
    case when @wo_date_ind = 0 then SO.work_datetime else isnull(P.sch_date,SO.work_datetime) end, 
    r.tran_qty *(SOI.uom_qty / SI.uom_qty), SP.prod_no, SP.prod_ext, 0, 'U', 'PR'
  FROM  #result r 
  join	sched_item SI on SI.sched_process_id = r.tran_id and SI.sched_id = @sched_id
  join  sched_operation_item SOI on SOI.sched_item_id = SI.sched_item_id
  join  sched_operation SO on SO.sched_operation_id = SOI.sched_operation_id
  join  sched_process SP on SP.sched_process_id = SO.sched_process_id AND SP.sched_id = SI.sched_id
  left outer join produce_all P on P.prod_no = SP.prod_no and P.prod_ext = SP.prod_ext and SP.source_flag != 'P'
  where r.row_id = @row

  insert #result (tran_id,part_no,location,dep_part_no,dep_location,supply_ind,planned_ind,
    tran_date,tran_qty,tran_no,tran_ext,tran_line,tran_type,tran_table,forecast_qty, forecast_date)
  select SO.sched_order_id, r.part_no, r.location, SI.part_no, SI.location,0, 
    0, SO.done_datetime, r.tran_qty *(SOI.uom_qty / SI.uom_qty), SO.order_no, SO.order_ext, 0,
    case when SO.source_flag = 'M' then 'Z' else SO.source_flag end, 'OR',
    case when SO.source_flag in ('C','T') then
      isnull((select -r.tran_qty *(SOI.uom_qty / SI.uom_qty) * sum(SOI2.uom_qty) / SI.uom_qty 
        from sched_order_item SOI2, sched_order SO2
        where SOI2.sched_item_id = SI.sched_item_id and SO2.sched_order_id = SOI2.sched_order_id
          and SO2.source_flag = 'F'),0) else 0 end,
    case when SO.source_flag in ('C','T') then
     (select min(SO2.done_datetime) from sched_order_item SOI2, sched_order SO2
        where SOI2.sched_item_id = SI.sched_item_id and SO2.sched_order_id = SOI2.sched_order_id
          and SO2.source_flag = 'F') else NULL end
  FROM	#result r
  join  sched_item SI on SI.sched_process_id = r.tran_id and SI.sched_id = @sched_id
  join 	sched_order_item SOI on SOI.sched_item_id = SI.sched_item_id
  join 	sched_order SO on SO.sched_order_id = SOI.sched_order_id
  WHERE	r.row_id = @row
  
  delete from #result where row_id = @row

  select @row = isnull((select min(row_id) from #result where tran_type = 'U' and planned_ind = 1),0)
end

select @sql_txt = 'insert #result (tran_id,part_no,location,dep_part_no,dep_location,supply_ind,planned_ind,
  tran_date,tran_qty,tran_no,tran_ext,tran_line,tran_type,tran_table,forecast_qty,forecast_date)
  SELECT SO.sched_order_id,SO.part_no, SO.location, SO.part_no, SO.location,0, 0, 
    case when SO.source_flag in (''N'',''M'') then ''1/1/1900'' else done_datetime end, 
    uom_qty * -1 ,
    order_no,order_ext,order_line,case when SO.source_flag = ''M'' then ''Z'' else SO.source_flag end, ''OR'',
    case  
      when SO.source_flag in (''C'',''T'') then
      isnull((select sum(SOI.uom_qty *(SOI2.uom_qty / SI.uom_qty)) from sched_order_item SOI2, 
      sched_order SO2, sched_item SI, sched_order_item SOI
      where SOI.sched_order_id = SO.sched_order_id and SI.sched_item_id = SOI.sched_item_id and
        SOI2.sched_item_id = SI.sched_item_id and SO2.sched_order_id = SOI2.sched_order_id
        and SO2.source_flag = ''F''),0) 
--      when SO.source_flag = ''F'' then
--      SO.uom_qty - isnull((select sum(SOI2.uom_qty)
--      from sched_order_item SOI,sched_order_item SOI2
--      where SOI.sched_order_id = SO.sched_order_id and SOI.sched_item_id = SOI2.sched_item_id
--        and SOI2.sched_order_id != SO.sched_order_id),0)
      when SO.source_flag = ''M'' then uom_qty
      when SO.source_flag = ''N'' then uom_qty
      else 0 end,
    case when SO.source_flag in (''C'',''T'') then
      (select min(SO2.done_datetime) from sched_order_item SOI2, 
      sched_order SO2, sched_item SI, sched_order_item SOI
      where SOI.sched_order_id = SO.sched_order_id and SI.sched_item_id = SOI.sched_item_id and
        SOI2.sched_item_id = SI.sched_item_id and SO2.sched_order_id = SOI2.sched_order_id
        and SO2.source_flag = ''F'') else NULL end
  FROM sched_order SO,'

if @inv_master_ind = 1
  select @sql_txt = @sql_txt + '
    #part i,'

select @sql_txt = @sql_txt + '
  #location L
  WHERE	SO.sched_id = ' + convert(varchar(10),@sched_id) + '
    AND	SO.location = L.location '

if @inv_master_ind = 1
  select @sql_txt = @sql_txt + '
    AND	SO.part_no = i.part_no'

exec(@sql_txt)


select @sql_txt = 'insert #result (tran_id,part_no,location,dep_part_no,dep_location,supply_ind,planned_ind,
  tran_date,tran_qty,tran_no,tran_ext,tran_line,tran_type,tran_table)
  select SI.sched_item_id, SI.part_no, SI.location,SI.part_no, SI.location,1,
    case when SI.source_flag = ''P'' then 1 else 0 end, SI.done_datetime, SI.uom_qty,
    case when SI.source_flag = ''T'' then SP.xfer_no else SP.po_no end ,0,
    case when SI.source_flag = ''T'' then SP.xfer_line else 0 end,SI.source_flag,''PU''
  FROM sched_item SI, sched_purchase SP,'

if @inv_master_ind = 1
  select @sql_txt = @sql_txt + '
    #part i,'

select @sql_txt = @sql_txt + '
    #location L
  WHERE	SI.sched_id = ' + convert(varchar(10),@sched_id) + '
    AND	SI.source_flag between ''O'' and ''T''
    AND	SI.source_flag in ( ''O'', ''P'',''R'',''T'')
    AND	SI.location = L.location
    AND SI.sched_item_id = SP.sched_item_id'

if @inv_master_ind = 1
  select @sql_txt = @sql_txt + '
    AND	SI.part_no = i.part_no'

exec(@sql_txt)

	
select @sql_txt = 'insert #result (tran_id,part_no,location,dep_part_no,dep_location,supply_ind,planned_ind,
  tran_date,tran_qty,tran_no,tran_ext,tran_line,tran_type,tran_table)
  select SP.sched_process_id, SI.part_no, SI.location, SI.part_no, SI.location, 1, 
    case when SP.source_flag = ''P'' then 1 else 0 end, 
    case when ' + convert(varchar,@wo_date_ind) + '=0 then SI.done_datetime else isnull(P.sch_date,SI.done_datetime) end, 
    SI.uom_qty,SP.prod_no,0,0,''M'',''SP''
  FROM sched_item SI
  join #location L on SI.location = L.location
  join sched_process SP on SP.sched_process_id = SI.sched_process_id
  join produce_all P on P.prod_no = SP.prod_no and P.prod_ext = SP.prod_ext and SP.source_flag != ''P'''

if @inv_master_ind = 1
  select @sql_txt = @sql_txt + '
join #part i on i.part_no = SI.part_no'

  select @sql_txt = @sql_txt + '
  WHERE	SI.sched_id = ' + convert(varchar(10),@sched_id) + '
    AND	SI.source_flag = ''M'''

exec(@sql_txt)





























select @sql_txt = 'insert #result (tran_id,part_no,location,dep_part_no,dep_location,supply_ind,planned_ind,
  tran_date,tran_qty,tran_no,tran_ext,tran_line,tran_type,tran_table)
  select SI.sched_item_id,SI.part_no, SI.location, SI.part_no, SI.location, 
 1, 0, ''1/1/1900'',SI.uom_qty,NULL,0,0,''I'',''I''
  FROM	sched_item SI (INDEX=source)
  JOIN (select distinct part_no, location from #result) as r(part_no,location) on r.part_no = SI.part_no and r.location = SI.location
  WHERE	SI.sched_id = ' + convert(varchar(10),@sched_id) + '
    AND	SI.source_flag = ''I'''

exec(@sql_txt)

insert #final_result (tran_id, part_no,location,dep_part_no,dep_location,supply_ind,planned_ind,
  tran_date,tran_qty,tran_no,tran_ext,tran_line,tran_type,tran_table,forecast_qty,forecast_date,
  supply_qty,demand_qty,running_bal,group1,group2,group3,group4)
select tran_id, i.part_no,location,dep_part_no,dep_location,supply_ind,planned_ind,
  tran_date,sum(tran_qty),tran_no,tran_ext,tran_line,tran_type,tran_table,sum(isnull(forecast_qty,0)),max(forecast_date),
  case when supply_ind = 1 then sum(tran_qty) else sum(isnull(forecast_qty,0)) end,
  case when supply_ind = 0 then sum(tran_qty) * -1 else 0 end, 0,
  case @group_ind when 1 then isnull(i.buyer,'') when 2 then isnull(i.vendor,'') else r.location end,
  case @group_ind when 1 then isnull(i.vendor,'') else i.part_no end,
  case @group_ind when 1 then i.part_no when 2 then r.location else '' end, 
  case @group_ind when 1 then r.location else '' end
from #result r
left outer join inv_master i on lower(i.part_no) = lower(r.part_no)
where planned_ind <= @planned_ind
group by tran_id, i.part_no,location,dep_part_no,dep_location,supply_ind,planned_ind,
  tran_date,tran_no,tran_ext,tran_line,tran_type,tran_table, i.buyer, i.vendor
order by 
  case @group_ind when 1 then isnull(i.buyer,'') when 2 then isnull(i.vendor,'') else r.location end,
  case @group_ind when 1 then isnull(i.vendor,'') else i.part_no end,
  case @group_ind when 1 then i.part_no when 2 then r.location else '' end, 
  case @group_ind when 1 then r.location else '' end,
  datepart(year,tran_date), datepart(month,tran_date), datepart(day,tran_date) ,
  supply_ind desc,
  tran_type, tran_no, tran_ext

declare @running_bal decimal(20,8), @part varchar(30), @location varchar(10)
select @running_bal = 0, @part = '', @location = ''
select @row = isnull((select min(row_id) from #final_result),NULL)
while @row is not NULL
begin
  select @running_bal = case when @part != part_no or @location != location then 0 else @running_bal end + 
    supply_qty - demand_qty,
    @part = part_no, @location = location
  from #final_result where row_id = @row
 
  update #final_result
  set running_bal = @running_bal
  where row_id = @row

  select @row = isnull((select min(row_id) from #final_result where row_id > @row),NULL)
end

if charindex('r.tdate',@range) > 0
begin
  select @range1 = replace(@range,'SL.location','0=0 or ""')
  select @range1 = replace(@range1,'l.organization_id','0=0 or ""')
  select @range1 = replace(@range1,'r.region_id','0=0 or ""')
  select @range1 = replace(@range1,'i.part_no','0=0 or ""')
  select @range1 = replace(@range1,'i.vendor','0=0 or ""')
  select @range1 = replace(@range1,'i.buyer','0=0 or ""')
  select @range1 = replace(@range1,'i.status','0=0 or ""')
  select @range1 = replace(@range1,'r.tdate',' datediff(day,"01/01/1900",r.tran_date) + 693596 ')
  select @range1 = replace(@range1,'"','''')

  select @sql_txt =
  'delete r from #final_result r
  where not (r.tran_type = ''I'' or (' + @range1 + '))'
  exec (@sql_txt)


  delete r 
  from #final_result r
  where part_no + '!@#' + location not in
  (select part_no + '!@#' + location from #final_result r2 where tran_type != 'I')


  update r
  set running_bal = 
  isnull((select running_bal + (- supply_qty + demand_qty)
  from #final_result r1 where r1.part_no = r.part_no and r1.location = r.location
  and r1.row_id =
  isnull((select min(row_id) from #final_result r2 where r2.part_no = r.part_no and r2.location = r.location
  and r2.row_id > r.row_id),0)),0)
  from #final_result r
  where r.tran_type = 'I'

  update #final_result
  set tran_qty = running_bal
  where tran_type = 'I'
end 



select @sql_txt = 
'
SELECT ''' + 
@sched_name + ''',	--vc16
i.part_no, 	--vc30
r.location,	--vc10
i.description,	--vc255
isnull(l.min_stock,0),	--dec
i.vendor,	--vc30
v.vendor_name,	--vc255
i.buyer,	--vc30
b.description,	--vc255
r.planned_ind,	--int
r.supply_ind,	--int
i.status,	--c1
r.tran_date,	--dt
r.tran_qty,	--dec
r.tran_qty + isnull(r.forecast_qty,0),
r.tran_no,	--int
r.tran_ext,	--int
r.tran_line,	--int
r.tran_type,	--c1
( case r.planned_ind when 1 then ''Planned '' else '''' end) +
case cast(r.tran_type as varchar)
when ''F'' then ''Forecast''
when ''M'' then ''Production''
when ''P'' then ''Purchase Order''
when ''O'' then ''Purchase Order''
when ''R'' then ''Released PO''
when ''I'' then ''Beginning Balance''
when ''C'' then ''Sales Order''
when ''N'' then ''Negative Stk''
when ''Z'' then ''Minimum Stk''
when ''U'' then ''Production''
when ''T'' then ''Transfer''
else cast(r.tran_type  as varchar)
end +

case when r.tran_no is not null then '' '' +
isnull(convert(varchar(10),r.tran_no),'''') +
case when r.tran_type in (''T'',''P'',''O'',''R'') then '''' else  ''-'' + isnull(convert(varchar(10),r.tran_ext),'''') end +
case when r.tran_type in (''P'',''O'',''R'') then '''' else  ''.'' + isnull(convert(varchar(10),tran_line),'''') end 
else '''' end +

cast( case when r.dep_part_no <> i.part_no then '' ('' + r.dep_part_no + '')'' else '''' end as varchar),		--vc255
r.dep_part_no,	--vc30
r.dep_location,	--vc10
r.tran_table,	--c2
case when r.tran_type in (''Z'',''N'') then 0 else isnull(r.forecast_qty,0) end,  --dec
r.forecast_date,
r.supply_qty,
r.demand_qty,
r.running_bal,
r.group1,r.group2,r.group3,r.group4, r.row_id
 FROM #final_result r
left outer join inv_master i on lower(i.part_no) = lower(r.part_no)
left outer join inv_list l on lower(l.part_no) = lower(r.part_no)
  and lower(l.location) = lower(r.location)
left outer join adm_vend_all v on i.vendor = v.vendor_code
left outer join buyers b on b.kys = i.buyer
order by r.row_id'

exec (@sql_txt)

DROP TABLE #result
drop table #location

RETURN
END


GO
GRANT EXECUTE ON  [dbo].[adm_rpt_womscheduling] TO [public]
GO
