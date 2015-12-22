SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_rpt_coa] @part varchar(30), @lot varchar(25),
                                @cust varchar(10) AS

SET NOCOUNT ON

declare @qc int, @lb char(1), @owner varchar(80)
select @owner=isnull( (select min(name) from registration), 'Unauthorized' )

CREATE table #coa (
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

select @lb = isnull( (select lb_tracking from inv_master (nolock) where part_no=@part), 'N' )

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
  insert #coa (
         qc_no          , part_no        , lot_ser        , 
         status         , qc_qty         , reject_qty     , 
         appearance     , composition    , inspector      , 
         date_complete  , hdrnote        , test_key       , 
         value          , print_note     , coa            ,
         testnote       , min_val        , max_val        ,
         target )
  select r.qc_no          , r.part_no        , r.lot_ser        , 
         r.status         , r.qc_qty         , r.reject_qty     , 
         r.appearance     , r.composition    , r.inspector      , 
         r.date_complete  , r.note           , d.test_key       , 
         d.value          , d.print_note     , d.coa            ,
         d.note           , ''               , ''               ,
         ''
  from qc_results r
  join qc_detail d on d.qc_no = r.qc_no
  where  r.qc_no=@qc

  update c 
  set min_val= isnull(p.min_val,''),
    max_val = isnull(p.max_val,''),
    target = isnull(p.target,'')
  from #coa c
  join qc_test p on p.kys = c.test_key

  update c 
  set min_val = isnull(p.min_val,c.min_val),
    max_val = isnull(p.max_val,c.max_val),
    target = isnull(p.target,c.target)
  from #coa c
  join qc_part p on p.part_no = c.part_no and p.test_key = c.test_key

  update c
  set print_note = isnull(p.print_note,c.print_note),
    coa = isnull(p.coa,c.coa),
    min_val = isnull(p.min_val,c.min_val),
    max_val = isnull(p.max_val,c.max_val),
    target = isnull(p.target,c.target)
  from #coa c
  join qc_cust p on p.customer_key = @cust and p.part_no = c.part_no and p.test_key = c.test_key
  
  update #coa 
  set testnote=null 
  where print_note='N'
end

select qc_no          , q.part_no      , lot_ser        , 
       q.status       , qc_qty         , reject_qty     , 
       date_complete  , test_key       , value          , 
       min_val        , max_val        , target         ,
       print_note     , coa            , inspector      , 
       @owner         , hdrnote        , testnote       ,
       i.description  , appearance     , composition    
from #coa q, inv_master i
where q.part_no=i.part_no and q.coa='Y'
order by q.test_key

GO
GRANT EXECUTE ON  [dbo].[fs_rpt_coa] TO [public]
GO
