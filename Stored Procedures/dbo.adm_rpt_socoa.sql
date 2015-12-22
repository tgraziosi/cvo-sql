SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_socoa] @process_ctrl_num varchar(16) = '', 
  @range varchar(8000) = '0=0'
as
begin

create table #t (
	order_no int,
	ext int,
	cust_code varchar(20) NULL,
	part_no varchar(30) NULL, 
	lot_ser varchar(30) NULL,
	line_no int NULL,
	i_lb_tracking char(1) NULL,
	row_id int identity(1,1)
)
CREATE table #coa (
   order_no        int null,
   order_ext       int null,
   cust_code       varchar(20) NULL,
   line_no         int null,
   qc_no           int, 
   part_no         varchar(30), 
   lot_ser         varchar(25) NULL, 
   status          char(1) NULL, 
   qc_qty          decimal(20,8), 
   reject_qty      decimal(20,8), 
   appearance      varchar(255) NULL, 
   composition     varchar(255) NULL, 
   inspector       varchar(50) NULL, 
   date_complete   datetime NULL, 
   hdrnote         varchar(255) NULL, 
   test_key        varchar(10) NULL, 
   value           varchar(50) NULL, 
   print_note      char(1) NULL, 
   coa             char(1) NULL,
   testnote        varchar(255) NULL, 
   min_val         varchar(50) NULL, 
   max_val         varchar(50) NULL,
   target          varchar(50) NULL
)

declare @pos int, @order varchar(10), @ext varchar(10)

if @process_ctrl_num != ''
begin
  select @pos = charindex('-',@process_ctrl_num,1)
  select @order = left(@process_ctrl_num,(@pos-1))
  select @ext = substring(@process_ctrl_num,(@pos+1),16)

  exec('insert #t (order_no, ext, cust_code, part_no, lot_ser, line_no, i_lb_tracking)
  select o.order_no, o.ext, o.cust_code, l.part_no, b.lot_ser, l.line_no, i.lb_tracking
  from ord_list l (nolock), lot_bin_ship b (nolock), inv_master i (nolock), orders_all o (nolock)
  where o.order_no = l.order_no and o.ext = l.order_ext and b.line_no = l.line_no 
  and l.lb_tracking = ''Y'' and i.part_no = l.part_no and o.order_no = ' + 
  @order + ' and o.ext = ' + @ext)
end
else
begin
  select @range = replace(@range,'"','''')
  exec('insert #t (order_no, ext, cust_code, part_no, lot_ser, line_no, i_lb_tracking)
  select distinct o.order_no, o.ext, o.cust_code, lo.part_no, b.lot_ser, lo.line_no, i.lb_tracking
  from ord_list lo (nolock), lot_bin_ship b (nolock), inv_master i (nolock), orders_all o (nolock), 
    locations l (nolock), region_vw r (nolock)
  where o.order_no = lo.order_no and o.ext = lo.order_ext and b.line_no = lo.line_no and
      l.location = o.location and 
      l.organization_id = r.org_id 
  and lo.lb_tracking = ''Y'' and i.part_no = lo.part_no and ' + @range)
end


----------------------------------------------------------------------
declare @part varchar(30), @lot varchar(25),
                                @cust varchar(10), @row int, @line int
declare @qc int, @lb char(1), @owner varchar(80)
select @owner=isnull( (select min(name) from registration), 'Unauthorized' )


select @row = isnull((select min(row_id) from #t),NULL)

while @row is not null
begin
  select @lb = i_lb_tracking,
    @part = part_no,
    @lot = lot_ser,
    @line = line_no
  from #t
  where row_id = @row

  if @lb = 'Y' 
  begin
    select @qc=isnull( (select max(qc_no) from qc_results (nolock)
      where part_no=@part and status='S' and lot_ser=@lot), 0 )
  end
  else 
  begin
    select @qc=isnull( (select max(qc_no) from qc_results (nolock)
      where part_no=@part and status='S'), 0 )
  end

  if @qc > 0 
  begin
    insert #coa ( order_no, order_ext, cust_code, line_no,
         qc_no          , part_no        , lot_ser        , 
         status         , qc_qty         , reject_qty     , 
         appearance     , composition    , inspector      , 
         date_complete  , hdrnote        , test_key       , 
         value          , print_note     , coa            ,
         testnote       , min_val        , max_val        ,
         target )
    select t.order_no, t.ext, t.cust_code, t.line_no,
         r.qc_no          , r.part_no        , r.lot_ser        , 
         r.status         , r.qc_qty         , r.reject_qty     , 
         r.appearance     , r.composition    , r.inspector      , 
         r.date_complete  , r.note           , d.test_key       , 
         d.value          , d.print_note     , d.coa            ,
         d.note           , ''               , ''               ,
         ''
    from qc_results r (nolock)
    join qc_detail d on d.qc_no = r.qc_no
    join #t t on t.row_id = @row
    where  r.qc_no=@qc

  update c 
  set min_val= isnull(p.min_val,''),
    max_val = isnull(p.max_val,''),
    target = isnull(p.target,'')
  from #coa c
  join qc_test p (nolock) on p.kys = c.test_key
  where c.line_no = @line and c.lot_ser = @lot and c.qc_no = @qc

  update c 
  set min_val = isnull(p.min_val,c.min_val),
    max_val = isnull(p.max_val,c.max_val),
    target = isnull(p.target,c.target)
  from #coa c
  join qc_part p (nolock) on p.part_no = c.part_no and p.test_key = c.test_key
  where c.line_no = @line and c.lot_ser = @lot and c.qc_no = @qc

  update c
  set print_note = isnull(p.print_note,c.print_note),
    coa = isnull(p.coa,c.coa),
    min_val = isnull(p.min_val,c.min_val),
    max_val = isnull(p.max_val,c.max_val),
    target = isnull(p.target,c.target)
  from #coa c
  join qc_cust p (nolock) on p.customer_key = @cust and p.part_no = c.part_no and p.test_key = c.test_key
  where c.line_no = @line and c.lot_ser = @lot and c.qc_no = @qc
end

  select @row = isnull((select min(row_id) from #t where row_id > @row),NULL)
end

  update #coa 
  set testnote=null 
  where print_note='N'

select order_no, order_ext, cust_code, line_no,
qc_no          , q.part_no      , q.lot_ser        , 
       q.status       , qc_qty         , reject_qty     , 
       date_complete  , test_key       , value          , 
       min_val        , max_val        , target         ,
       print_note     , coa            , inspector      , 
       @owner         , hdrnote        , testnote       ,
       i.description  , appearance     , composition    ,
  replicate (' ',11 - datalength(convert(varchar(11),order_no))) + convert(varchar(11),order_no) + '.' +
  replicate (' ',5 - datalength(convert(varchar(5),order_ext))) + convert(varchar(5),order_ext),
  q.part_no,
  q.lot_ser

from #coa q, inv_master i (nolock)
where q.part_no=i.part_no and q.coa='Y'
order by order_no, order_ext, q.part_no, q.lot_ser, q.test_key
end 
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_socoa] TO [public]
GO
