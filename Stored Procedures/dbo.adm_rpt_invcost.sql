SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_invcost] @range varchar(8000) = '0=0',
@costs varchar(8000) = ' NULL',
@order varchar(1000) = ' i.part_no',
@enddate int = 0

 as


BEGIN
select @range = replace(@range,'"','''')
select @costs = replace(@costs,'"','''')
select @order = replace(@order,'"','''')

declare @sql varchar(8000)

if @enddate = 0
select @sql = ' SELECT distinct
 i.part_no, 
 i.description,   
 i.type_code,  
 i.in_stock,   
 i.po_on_order,   
 i.qty_alloc, 
 i.min_stock,  
 i.recv_mtd,  
 i.issued_mtd,  
 i.usage_mtd,   
 i.sales_qty_mtd,  
 i.recv_ytd,  
 i.issued_ytd, 
 i.usage_ytd,   
 i.sales_qty_ytd,  
 i.vendor,  
 i.cost,  
 i.avg_cost, 
 i.avg_direct_dolrs, 
 i.avg_ovhd_dolrs, 
 i.avg_util_dolrs,   
 i.std_cost,   
 i.std_direct_dolrs,  
 i.std_ovhd_dolrs,   
 i.std_util_dolrs,   
 i.last_cost,   
 i.sales_amt_mtd,   
 i.sales_amt_ytd,   
 i.oe_on_order,   
 i.location,   
 i.labor,   
 i.std_labor,   
 i.hold_qty,   
 i.hold_mfg,   
 i.hold_ord,   
 i.hold_rcv,   
 i.hold_xfr, 
 i.hold_ord + i.hold_xfr, 
 i.hold_ord + i.hold_xfr  + i.in_stock, '
else
select @sql = ' SELECT distinct
 i.part_no, 
 i.description,   
 i.type_code,  
 t.in_stock,   
 null,
 null,
 null,
 null,
 null,
 null,
 null,
 null,
 null,
 null,
 null,
 i.vendor,  
 null,
 t.avg_mtrl_cost, 
 t.avg_dir_cost, 
 t.avg_ovhd_cost, 
 t.avg_util_cost,   
 t.std_mtrl_cost,   
 t.std_dir_cost,  
 t.std_ovhd_cost,   
 t.std_util_cost,   
 null,
 null,
 null,
 null,
 i.location,   
 null,
 null,
 null,
 null,
 null,
 null,
 null,
 t.hold_qty,
 t.hold_qty  + t.in_stock, '


select @sql = @sql  + @costs + '
FROM inventory i (nolock)
join locations l (nolock) on l.location = i.location
join region_vw r (nolock) on l.organization_id = r.org_id'

if @enddate > 0 
  select @sql = @sql + '
join (select part_no, location, max(tran_id) from inv_tran 
where curr_date <= ''' + convert(varchar(20),dbo.adm_format_pltdate_f((@enddate + 1)),110) + ''' group by part_no, location) as tr(part_no, location,tran_id)
on tr.part_no = i.part_no and tr.location = i.location
join inv_tran t on t.tran_id = tr.tran_id'

select @sql = @sql + '
 WHERE (i.status < ''R'') and ' + @range + '
  order by ' + @order

print @sql
exec (@sql)
end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_invcost] TO [public]
GO
