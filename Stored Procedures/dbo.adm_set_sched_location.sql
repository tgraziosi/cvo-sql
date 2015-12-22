SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_set_sched_location]
@mode char(2),
@sched_id int = NULL,
@location varchar(10) = NULL
as
begin
  Declare @SIidentity int
  create table #t (sched_process_id int)


  if @mode = 'D'
  begin
    exec adm_set_sched_item 'DL',@sched_id,NULL,@location

    if (@@version like '%7.0%')
    begin
      exec adm_set_sched_order 'DL',@sched_id,NULL,@location
      exec adm_set_sched_transfer 'DL',@sched_id,NULL,@location
      exec adm_set_sched_resource 'DL',@sched_id,NULL,@location
    end

    insert #t
    select distinct SP.sched_process_id
    from sched_operation SO, sched_process SP
    where SO.sched_process_id = SP.sched_process_id and SO.location = @location
    and SP.sched_id = @sched_id

    insert #t
    select distinct SP.sched_process_id
    from sched_process_product SPP, sched_process SP
    where SPP.sched_process_id = SP.sched_process_id and SPP.location = @location
    and SP.sched_id = @sched_id

    exec adm_set_sched_operation 'DL',NULL,@sched_id,NULL,@location

    delete SPP
    from sched_process_product SPP, #t
    where SPP.sched_process_id = #t.sched_process_id

    delete SP
    from sched_process SP, #t
    where SP.sched_process_id = #t.sched_process_id
		
    delete SL
    from sched_location SL
    WHERE SL.sched_id =  @sched_id and SL.location = @location 
  end
  if @mode = 'D1'
  begin
    exec adm_set_sched_item 'DM',@sched_id

    if (@@version like '%7.0%')
    begin
      exec adm_set_sched_order 'DM',@sched_id
      exec adm_set_sched_transfer 'DM',@sched_id
      exec adm_set_sched_resource 'DM',@sched_id
    end
						
    delete SL
    from sched_location SL
    WHERE SL.sched_id =  @sched_id
    AND NOT EXISTS(SELECT 1 FROM locations_all L WHERE L.location = SL.location AND L.void != 'V')
  end
  if @mode = 'DA'
  begin
    exec adm_set_sched_item 'DA',@sched_id

    if (@@version like '%7.0%')
    begin
      exec adm_set_sched_order 'DA',@sched_id
      exec adm_set_sched_transfer 'DA',@sched_id
      exec adm_set_sched_resource 'DA',@sched_id
    end
						
    delete SL
    from sched_location SL
    WHERE SL.sched_id =  @sched_id
  end
end


GO
GRANT EXECUTE ON  [dbo].[adm_set_sched_location] TO [public]
GO
