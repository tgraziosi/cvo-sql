SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




create procedure [dbo].[adm_set_sched_item_all]
@mode char(2),
@sched_id int = NULL,
@sched_item_id int = 0,
@location varchar(10) = NULL,
@part_no varchar(30) = NULL,
@done_datetime datetime = NULL,
@uom_qty float = NULL,
@uom char(2) = NULL,
@source_flag char(1) = NULL,
@sched_process_id int = NULL,
@sched_transfer_id int = NULL,
@lead_datetime datetime = NULL,
@status_flag char(1) = NULL,
@sched_order_id INT = NULL,
@link_type char(10) = NULL,

@link_id1 int = 0, 
@link_uom_qty1 float = NULL,
@demand_datetime1 datetime = NULL,

@link_id2 int = 0,
@link_uom_qty2 float = NULL,
@demand_datetime2 datetime = NULL,

@link_id3 int = 0,
@link_uom_qty3 float = NULL,
@demand_datetime3 datetime = NULL,

@link_id4 int = 0,
@link_uom_qty4 float = NULL,
@demand_datetime4 datetime = NULL,

@link_id5 int = 0,
@link_uom_qty5 float = NULL,
@demand_datetime5 datetime = NULL

as
begin
  Declare @SIidentity int, @link_mode char(1)
  if isnull(@sched_item_id,0) != 0
    select @SIidentity = @sched_item_id

  if @mode like 'I%' and isnull(@sched_item_id,0) = 0
  begin
    Insert sched_item
      (sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag,sched_process_id,sched_transfer_id)
    values
      (@sched_id,@location,@part_no,@done_datetime,@uom_qty,@uom,@source_flag,@sched_process_id,@sched_transfer_id)

    select @SIidentity = @@identity
  end
  if @mode = 'IP' and isnull(@sched_item_id,0) = 0
  begin
    INSERT sched_purchase (sched_item_id,lead_datetime,status_flag,sched_order_id)
    values (@SIidentity, @lead_datetime,@status_flag,@sched_order_id)
  end

  if @mode = 'UP'
  begin
    update sched_purchase
    set status_flag = @status_flag, sched_order_id = @sched_order_id
    where sched_item_id = @sched_item_id
  end

  if isnull(@link_id1,0) != 0
  begin
    select @link_mode = substring(@link_type,1,1)
    exec adm_set_sched_item_link @link_mode, @link_id1, @SIidentity, @link_uom_qty1, @uom, @demand_datetime1
  end
  if isnull(@link_id2,0) != 0
  begin
    select @link_mode = substring(@link_type,2,1)
    exec adm_set_sched_item_link @link_mode, @link_id2, @SIidentity, @link_uom_qty2, @uom, @demand_datetime2
  end
  if isnull(@link_id3,0) != 0
  begin
    select @link_mode = substring(@link_type,3,1)
    exec adm_set_sched_item_link @link_mode, @link_id3, @SIidentity, @link_uom_qty3, @uom, @demand_datetime3
  end
  if isnull(@link_id4,0) != 0
  begin
    select @link_mode = substring(@link_type,4,1)
    exec adm_set_sched_item_link @link_mode, @link_id4, @SIidentity, @link_uom_qty4, @uom, @demand_datetime4
  end
  if isnull(@link_id5,0) != 0
  begin
    select @link_mode = substring(@link_type,5,1)
    exec adm_set_sched_item_link @link_mode, @link_id5, @SIidentity, @link_uom_qty5, @uom, @demand_datetime5
  end

  return @SIidentity
end
GO
GRANT EXECUTE ON  [dbo].[adm_set_sched_item_all] TO [public]
GO
