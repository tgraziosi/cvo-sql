SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




create procedure [dbo].[adm_set_sched_operation_all]
@mode char(2),
@sched_operation_id int = 0,
@sched_process_id int = NULL,
@operation_step int = NULL,
@location varchar(10) = NULL,
@ave_flat_qty float = 0,
@ave_unit_qty float = 0,
@ave_wait_qty float = 0,
@ave_flat_time float = 0,
@ave_unit_time float = 0,
@operation_type char(1) = 'M',
@complete_qty float = 0,
@discard_qty float = 0,
@operation_status char(1) = 'U',
@work_datetime datetime = NULL,
@done_datetime datetime = NULL,
@scheduled_duration float = NULL,
@link_ind int = 0,
@line_no int = NULL,
@line_id int = NULL,
@cell_id int = NULL,
@seq_no varchar(4) = NULL,
@part_no varchar(30) = NULL,
@usage_qty float = 0,
@link_ave_pool_qty float = 1,
@link_ave_flat_qty float = 0,
@link_ave_unit_qty float = 0,
@uom char(2) = NULL,
@status char(1) = NULL,
@active char(1) = NULL,
@eff_date datetime = NULL
as
begin

  if @mode = 'I' and @sched_operation_id = 0
  begin
    Insert sched_operation 
      (sched_process_id,operation_step,location,ave_flat_qty,ave_unit_qty,ave_wait_qty,ave_flat_time,ave_unit_time,operation_type,complete_qty,discard_qty,operation_status,work_datetime,done_datetime,scheduled_duration)
    values
      (@sched_process_id,@operation_step,@location,@ave_flat_qty,@ave_unit_qty,@ave_wait_qty,@ave_flat_time,@ave_unit_time,@operation_type,@complete_qty,@discard_qty,@operation_status,@work_datetime,@done_datetime,@scheduled_duration)

    select @sched_operation_id = @@identity 
  end

  if @mode = 'I' and @link_ind = 1
  begin
     Insert sched_operation_plan
       (sched_operation_id,line_no,line_id,cell_id,seq_no,part_no,usage_qty,ave_pool_qty,ave_flat_qty,ave_unit_qty,uom,status,active,eff_date)
     values
       (@sched_operation_id,@line_no,@line_id,@cell_id,@seq_no,@part_no,@usage_qty,@link_ave_pool_qty,@link_ave_flat_qty,@link_ave_unit_qty,@uom,@status,@active,@eff_date)
  end

  return @sched_operation_id

end

GO
GRANT EXECUTE ON  [dbo].[adm_set_sched_operation_all] TO [public]
GO
