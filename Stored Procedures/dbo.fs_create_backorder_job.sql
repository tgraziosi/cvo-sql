SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



create procedure [dbo].[fs_create_backorder_job] @prod_no int, @prod_ext int, @qty_sch decimal(20,8), @new_prod int OUT as

DECLARE @new_ext int

if @qty_sch > 0
begin

SELECT @new_prod = @prod_no

select @new_ext = isnull((select max(prod_ext) from produce_all where prod_no = @prod_no),-1) + 1

update prod_list
set status = 'S'
where prod_no = @prod_no and prod_ext = @prod_ext and status != 'S'
update produce_all
set status = 'S'
where prod_no = @prod_no and prod_ext = @prod_ext and status != 'S'

insert produce_all 
(prod_no, prod_ext, prod_date, part_type, part_no,  
location, qty, prod_type, sch_no, down_time,       
shift, who_entered, qty_scheduled, build_to_bom,   
date_entered, status, project_key, sch_flag,       
staging_area, sch_date, conv_factor, uom, printed, 
void, void_who, void_date, note, end_sch_date,     
tot_avg_cost, tot_direct_dolrs, tot_ovhd_dolrs,    
tot_util_dolrs, tot_labor, est_avg_cost,           
est_direct_dolrs, est_ovhd_dolrs, est_util_dolrs,  
est_labor, tot_prod_avg_cost,                      
tot_prod_direct_dolrs, tot_prod_ovhd_dolrs,        
tot_prod_util_dolrs, tot_prod_labor, scrapped,     
cost_posted, qc_flag, order_no, est_no,            
description, hold_flag, hold_code,         
posting_code, fg_cost_ind, sub_com_cost_ind,       
resource_cost_ind, orig_prod_no, orig_prod_ext)
select
@new_prod, @new_ext, getdate(), part_type, part_no,  
location, 0, prod_type, sch_no, down_time,       
shift, who_entered, (qty_scheduled - qty), build_to_bom,   
getdate(), 'N', project_key, sch_flag,       
staging_area, sch_date, conv_factor, uom, 'N',
'N',NULL, NULL, 
'Backorder of production ' + convert(varchar(10),@prod_no) + '-' + convert(varchar(10),@prod_ext) + '
' + note, 
end_sch_date,     
0,0,0,

0,0,0,
0,0,0,
0,0,
0,0,
0,0,0,
cost_posted, qc_flag, order_no, est_no,            
description, hold_flag, hold_code,         
posting_code, 
0,0,0,0,0
from produce_all where prod_no = @prod_no and prod_ext = @prod_ext


insert prod_list
(prod_no, prod_ext, line_no, seq_no, part_no,       
location, description, plan_qty, used_qty, attrib, 
uom, conv_factor, who_entered, note, lb_tracking,  
bench_stock, status, constrain, plan_pcs, pieces,  
scrap_pcs, part_type, direction, cost_pct, p_qty,  
p_line, p_pcs, qc_no, oper_status,         
pool_qty)
select
@new_prod, @new_ext, line_no, seq_no, part_no,       
location, description, 
case p_qty when 0 
  then case when plan_qty > used_qty then plan_qty - used_qty else 0 end 
  else @qty_sch * p_qty 
end, 
0, attrib, 
uom, conv_factor, who_entered, note, lb_tracking,  
bench_stock, 'N', constrain, 
case p_pcs when 0 then 0 else @qty_sch * p_pcs end, 0,
0, part_type, direction, cost_pct, p_qty,  
p_line, p_pcs, qc_no, 'N',         
pool_qty                                           
from prod_list
where prod_no = @prod_no and prod_ext = @prod_ext

end

return 1

GO
GRANT EXECUTE ON  [dbo].[fs_create_backorder_job] TO [public]
GO
