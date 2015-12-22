SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





create procedure [dbo].[adm_set_sched_process]
@mode char(2),
@sched_process_id int = NULL,
@sched_id int = NULL,
@process_unit decimal(20,8) = NULL,
@process_unit_orig decimal(20,8) = NULL,
@source_flag char(1) = 'P',
@prod_no int = NULL,
@prod_ext int = NULL,
@status_flag char(1) = NULL,
@sched_order_id int = NULL
as
begin
  if @mode = 'I'
  begin
    INSERT INTO dbo.sched_process(sched_id,process_unit,process_unit_orig,source_flag,
      prod_no, prod_ext, status_flag, sched_order_id) 
    VALUES (@sched_id,@process_unit, @process_unit_orig, @source_flag,
      @prod_no, @prod_ext, @status_flag, @sched_order_id) 
    return @@identity
  end
  if @mode = 'D'
  begin 
    if (@@version like '%7.0%')
    begin
      delete sched_process_product where sched_process_id = @sched_process_id
       EXEC adm_set_sched_operation 'D1',NULL,@sched_process_id  
    end
     EXEC adm_set_sched_item 'D1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@sched_process_id  
    delete sched_process where sched_process_id = @sched_process_id   
  end
  if @mode = 'DA'
  begin
    if (@@version like '%7.0%')
    begin
      delete SPP
      from sched_process_product SPP, sched_process SP where SPP.sched_process_id = SP.sched_process_id
      and SP.sched_id = @sched_id

       EXEC adm_set_sched_operation 'DA',NULL,@sched_id  
    end
     EXEC adm_set_sched_item 'DA',@sched_id  
    delete sched_process where sched_id = @sched_id   
  end
  if @mode = 'DC'
  begin
    if (@@version like '%7.0%')
    begin
      delete SPP
      from sched_process_product SPP, sched_process SP where SPP.sched_process_id = SP.sched_process_id
      and SP.sched_id = @sched_id and SP.source_flag = 'P'

       EXEC adm_set_sched_operation 'DC',NULL,@sched_id  
    end
    delete sched_process where sched_id = @sched_id and source_flag = 'P'  
  end
end

GO
GRANT EXECUTE ON  [dbo].[adm_set_sched_process] TO [public]
GO
