SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_set_sched_process_all]
@mode char(2),
@sched_process_id int = NULL,
@sched_id int = NULL,
@process_unit decimal(20,8) = NULL,
@process_unit_orig decimal(20,8) = NULL,
@source_flag char(1) = 'P',
@prod_no int = NULL,
@prod_ext int = NULL,
@status_flag char(1) = NULL,
@sched_order_id INT = NULL,
@product_ind int = 0,
@sched_process_product_id int = NULL OUT,
@location varchar(10) = NULL,
@part_no varchar(30) = NULL,
@uom_qty float = NULL,
@uom char(2) = NULL,
@usage_flag char(1) = NULL,
@cost_pct float = 100.0,
@bom_rev varchar(10) = NULL
as
begin

  if @mode = 'I' and isnull(@sched_process_id,0) = 0
  begin
    INSERT INTO dbo.sched_process(sched_id,process_unit,process_unit_orig,source_flag,
      prod_no, prod_ext, status_flag, sched_order_id) 
    VALUES (@sched_id,@process_unit, @process_unit_orig, @source_flag,
      @prod_no, @prod_ext, @status_flag, @sched_order_id) 

    select @sched_process_id = @@identity
  end

  if @mode = 'UP' 
  begin
    update sched_process
    set status_flag = @status_flag, sched_order_id = @sched_order_id
    where sched_process_id = @sched_process_id
  end

  if @mode = 'I' and @product_ind = 1
  begin  
    INSERT INTO sched_process_product 
      (sched_process_id,location,part_no,uom_qty,uom,usage_flag,cost_pct,bom_rev)
    Values
      (@sched_process_id,@location,@part_no,@uom_qty,@uom,@usage_flag,@cost_pct,@bom_rev)

    select @sched_process_product_id = @@identity
  end

  return @sched_process_id
end
GO
GRANT EXECUTE ON  [dbo].[adm_set_sched_process_all] TO [public]
GO
