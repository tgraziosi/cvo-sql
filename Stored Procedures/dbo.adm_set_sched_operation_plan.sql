SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





create procedure [dbo].[adm_set_sched_operation_plan]
@mode char(2),
@sched_operation_id int = 0,
@line_no int = NULL,
@line_id int = NULL,
@cell_id int = NULL,
@seq_no varchar(4) = NULL,
@part_no varchar(30) = NULL,
@usage_qty float = 0,
@ave_pool_qty float = 1,
@ave_flat_qty float = 0,
@ave_unit_qty float = 0,
@uom char(2) = NULL,
@status char(1) = NULL,
@active char(1) = NULL,
@eff_date datetime = NULL
as
begin
  if @mode = 'I'
  begin
     Insert sched_operation_plan
       (sched_operation_id,line_no,line_id,cell_id,seq_no,part_no,usage_qty,ave_pool_qty,ave_flat_qty,ave_unit_qty,uom,status,active,eff_date)
     values
       (@sched_operation_id,@line_no,@line_id,@cell_id,@seq_no,@part_no,@usage_qty,@ave_pool_qty,@ave_flat_qty,@ave_unit_qty,@uom,@status,@active,@eff_date)
  end
end

GO
GRANT EXECUTE ON  [dbo].[adm_set_sched_operation_plan] TO [public]
GO
