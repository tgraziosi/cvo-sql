SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




create procedure [dbo].[adm_set_sched_order_item]
@mode char(2),
@sched_order_id int = NULL,
@sched_item_id int = NULL,
@uom_qty float = NULL,
@uom char(2) = NULL,
@demand_datetime datetime = NULL
as
begin
  if @mode = 'I'
  begin
    Insert sched_order_item
      (sched_order_id,sched_item_id,uom_qty,uom,demand_datetime)
    values
      (@sched_order_id,@sched_item_id,@uom_qty,@uom,@demand_datetime)
  end
end


GO
GRANT EXECUTE ON  [dbo].[adm_set_sched_order_item] TO [public]
GO
