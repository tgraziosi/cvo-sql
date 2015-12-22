SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




create procedure [dbo].[adm_get_solver_data] @sched_id int, @data_type varchar(50)
as
begin
if @data_type = ''	
  select @data_type = NULL

if isnull(@data_type,'RetrieveSchedItem') = 'RetrieveSchedItem'
begin
  SELECT SI.location, 
   SI.part_no,  
   isnull(M.description,'N/A'),  
   isnull(M.uom,'EA'),  
   isnull(L.status,'MISC'),  
   isnull(M.yield_pct,100),  
   isnull(L.min_order,0), isnull(L.min_stock,0),  
   isnull(L.lead_time,0), isnull(L.dock_to_stock,0),  
   isnull(SI.sched_item_id,-1), 
   SI.done_datetime,  
   SI.uom_qty, 
   SI.uom, 
   SI.source_flag  ,
   isnull(SP.status_flag,'?'),
   isnull(SP.sched_order_id,0),
   isnull(SP.lead_datetime,'1/1/1970')
  FROM dbo.sched_item SI (nolock)
  left outer join dbo.sched_purchase SP (nolock) on SP.sched_item_id = SI.sched_item_id
  left outer join dbo.inv_master M (nolock) on  M.part_no = SI.part_no  and M.status != 'R'
  left outer join dbo.inv_list L (nolock) on L.part_no = M.part_no and L.location = SI.location
     WHERE SI.sched_id = @sched_id
  order by SI.location, SI.part_no

  update sched_model
  set solver_mode = lower(solver_mode)
  where sched_id = @sched_id
end
if isnull(@data_type, 'RetrieveResources' ) = 'RetrieveResources'
begin
  SELECT SR.sched_resource_id, 
    SR.location, 
    SR.resource_type_id, 
    R.resource_id, 
    R.resource_code, 
    IsNull(SR.calendar_id,R.calendar_id),
    R.pool_qty
  FROM dbo.sched_resource SR (nolock), 
     dbo.resource R  (nolock)
  WHERE SR.sched_id = @sched_id
    AND R.resource_id = SR.resource_id
end

if isnull(@data_type, 'RetrieveProcessesAll' ) = 'RetrieveProcessesAll'
begin
  SELECT 
    SP.sched_process_id,
    SP.process_unit, 
    SP.process_unit_orig, 
    SP.source_flag, 
    isnull(SP.prod_no, 0),							-- mls 12/2/03 SCR 32189
    isnull(SP.prod_ext, 0),							-- mls 12/2/03 SCR 32189
    isnull(SP.status_flag,'') ,
    SO.sched_process_id,
    isnull(SO.sched_operation_id,-1),
    isnull(SO.operation_step,1),
    isnull(SO.location,''),
    isnull(SO.ave_flat_qty,0),
    isnull(SO.ave_unit_qty,0),
    isnull(SO.ave_wait_qty,0),
    isnull(SO.ave_flat_time,0),
    isnull(SO.ave_unit_time,0),
    isnull(SO.operation_type,0),
    isnull(SO.complete_qty,0),
    isnull(SO.discard_qty,0),
    isnull(SO.operation_status,'@'),
    isnull(SO.work_datetime,getdate()),
    isnull(SO.done_datetime,getdate()),
    isnull(SO.scheduled_duration,0),
    isnull(SO.work_datetime,'1/1/2038'),
    isnull(SO.done_datetime,'1/1/2038'),
    isnull(SPP.sched_process_id,-1),
    isnull(SPP.location,''),
    isnull(SPP.part_no,''),
    isnull(SPP.uom_qty,''),
    isnull(SPP.uom,''),
    isnull(SPP.bom_rev,''),
    isnull(SOP.sched_operation_id,-1),
    isnull(SOP.line_id,-1),
    isnull(SOP.seq_no,''),
    isnull(SOP.part_no,''),
    isnull(SOP.ave_pool_qty,0),
    isnull(SOP.ave_flat_qty,0),
    isnull(SOP.ave_unit_qty,0),
    isnull(SOP.usage_qty * (SOP.ave_flat_qty + SOP.ave_unit_qty),0),
    isnull(SOP.uom,''), 
    isnull(SOP.status,''),
    isnull(SOP.active,''),
    isnull(SOP.eff_date,getdate()),
  SOR.setup_datetime,
  SOR.pool_qty,
  isnull(SP.status_flag,'?'),
  isnull(SP.sched_order_id,0)
  FROM dbo.sched_process SP  
  join dbo.sched_operation SO (nolock) on SO.sched_process_id = SP.sched_process_id
  left outer join dbo.sched_process_product SPP (nolock) on SPP.sched_process_id = SP.sched_process_id
  left outer join dbo.sched_operation_plan SOP (nolock) on SOP.sched_operation_id = SO.sched_operation_id
  left outer join
    (select SOR.setup_datetime, SOR.pool_qty, SOR.sched_operation_id, R.resource_code 
      from sched_operation_resource SOR (nolock)
      join dbo.sched_resource SR (nolock) on SOR.sched_resource_id = SR.sched_resource_id
      join dbo.resource R (nolock) on R.resource_id = SR.resource_id and R.location = SR.location) 
    as SOR(setup_datetime, pool_qty, sched_operation_id, part_no) ON SOR.sched_operation_id = SO.sched_operation_id 
      and SOR.part_no = SOP.part_no and SOP.status = 'R'
  WHERE SP.sched_id = @sched_id 
  order by SP.sched_process_id, SO.operation_step, SOP.line_id, SPP.sched_process_product_id
end
end 

GO
GRANT EXECUTE ON  [dbo].[adm_get_solver_data] TO [public]
GO
