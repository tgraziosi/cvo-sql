SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





create procedure [dbo].[adm_set_sched_process_product]
@mode char(1),
@sched_process_product_id int = NULL,
@sched_process_id int = NULL,
@location varchar(10) = NULL,
@part_no varchar(30) = NULL,
@uom_qty float = NULL,
@uom char(2) = NULL,
@usage_flag char(1) = NULL,
@cost_pct float = 100.0,
@bom_rev varchar(10) = NULL
as
begin
  if @mode = 'I'
  begin
    INSERT INTO sched_process_product 
      (sched_process_id,location,part_no,uom_qty,uom,usage_flag,cost_pct,bom_rev)
    Values
      (@sched_process_id,@location,@part_no,@uom_qty,@uom,@usage_flag,@cost_pct,@bom_rev)
    return @@identity
  end
end

GO
GRANT EXECUTE ON  [dbo].[adm_set_sched_process_product] TO [public]
GO
