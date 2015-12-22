SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_set_sched_transfer]
@mode char(2),
@sched_id int = NULL,
@sched_transfer_id int = NULL,
@location varchar(10) = NULL,
@move_datetime datetime = NULL,
@source_flag char(1) = NULL,
@xfer_no int = NULL,
@xfer_line int = NULL
as
begin
declare @identity int

  if @mode = 'D'
  begin
    if (@@version like '%7.0%')
    begin
      delete STI
      from sched_transfer_item STI where sched_transfer_id = @sched_transfer_id
    end
    Delete sched_transfer where sched_transfer_id = @sched_transfer_id
    return @@rowcount 
  end
  if @mode = 'DL'
  begin
    if (@@version like '%7.0%')
    begin
      delete STI
      from sched_transfer_item STI, sched_transfer ST
      where STI.sched_transfer_id = ST.sched_transfer_id
      and ST.sched_id = @sched_id and ST.location = @location
    end
   
    Delete sched_transfer where sched_id = @sched_id and location = @location
    return @@rowcount 
  end
  if @mode = 'DM'
  begin
    if (@@version like '%7.0%')
    begin
      delete STI
      from sched_transfer_item STI, sched_transfer ST
      where STI.sched_transfer_id = ST.sched_transfer_id 
      and ST.sched_id = @sched_id and ST.location not in
      (SELECT L.location FROM locations_all L WHERE L.void != 'V')
    end

    Delete sched_transfer where sched_id = @sched_id and location not in
      (SELECT L.location FROM locations_all L WHERE L.void != 'V')
    return @@rowcount 
  end
  if @mode = 'DA'
  begin
    if (@@version like '%7.0%')
    begin
      delete STI
      from sched_transfer_item STI, sched_transfer ST
      where STI.sched_transfer_id = ST.sched_transfer_id
      and ST.sched_id = @sched_id 
    end
    Delete sched_transfer where sched_id = @sched_id
    return @@rowcount 
  end
end

GO
GRANT EXECUTE ON  [dbo].[adm_set_sched_transfer] TO [public]
GO
