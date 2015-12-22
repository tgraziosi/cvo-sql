SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[adm_lc_alloc_dist_rpt] 
@range varchar(8000),
@sort char(1)
as

declare @range1 varchar(8000)

select @range1 = replace(@range,'h.apply_dt',' datediff(day,"01/01/1900",h.apply_dt) + 693596 ')
select @range1 = replace(@range1,'"','''')

create table #dist (
  alloc_no int NULL,
  voucher_no varchar(16) NULL,
  receipt_no int NULL,
  cost_to_cd char(3) NULL,
  part_no varchar(30) NULL,
  account_code varchar(32) NULL,
  reference_code varchar(32) NULL,
  cost_to_amt decimal(20,8) NULL,
  location varchar(10) NULL,
  apply_date datetime NULL
)


exec('insert #dist
  select l.allocation_no,
         l.voucher_no,   
         l.receipt_no,   
         l.cost_to_cd,   
         l.item,   
         l.account_code,   
         l.reference_code,   
         l.cost_to_amt,   
         r.location,   
         h.apply_dt  
    FROM lc_alloc_cost_to l (nolock),   
         receipts_all r (nolock),   
         lc_history h (nolock) 
   WHERE ( l.receipt_no = r.receipt_no ) and  
         ( l.allocation_no = h.allocation_no ) and l.cost_to_amt != 0 and ' + @range1)

if @sort = '0' -- allocation
begin
  select *,replicate (' ', 12 - datalength(convert(varchar(10),alloc_no))) + convert(varchar(10),alloc_no)
  from #dist
  order by alloc_no,receipt_no
end
if @sort = '1' -- item number
begin
  select * , part_no
  from #dist
  order by part_no, alloc_no,receipt_no
end
if @sort = '2' -- apply date
begin
  select * , convert(varchar(10),apply_date,102)
  from #dist
  order by apply_date,alloc_no,receipt_no
end

drop table #dist
GO
GRANT EXECUTE ON  [dbo].[adm_lc_alloc_dist_rpt] TO [public]
GO
