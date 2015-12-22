SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




-- Copyright (c) 1998 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_clear_schedule]
	(
	@sched_id	int,
	@solver_mode    char(1) = 'F'				-- mls 7/29/04
	)
AS
BEGIN

-- @solver_mode = 'F' - full evaluation  'I' - Incremental

DECLARE	@sched_item_id INT, @sched_process_id INT

if @solver_mode = 'F'
begin
DELETE	sched_operation_item
FROM	sched_operation_item SOI,
	sched_item SI
WHERE	SOI.sched_item_id = SI.sched_item_id and SI.sched_id = @sched_id

DELETE	sched_transfer_item
FROM	sched_transfer_item STI,
	sched_item SI,
	sched_transfer ST
WHERE	STI.sched_item_id = SI.sched_item_id and SI.sched_id = @sched_id
  and   STI.sched_transfer_id = ST.sched_transfer_id and ST.sched_id = @sched_id

delete 	sched_order_item
from 	sched_order_item SOI,
	sched_item SI,
	sched_order SO
where 	SI.sched_item_id = SOI.sched_item_id and SI.sched_id = @sched_id
and 	SOI.sched_order_id = SO.sched_order_id and SO.sched_id = @sched_id

DELETE	dbo.sched_operation_resource
FROM	dbo.sched_operation_resource SOR,
	dbo.sched_resource SR
WHERE	SOR.sched_resource_id = SR.sched_resource_id 
AND	SR.sched_id = @sched_id
end

 EXEC adm_set_sched_order 'DC',@sched_id  

if @solver_mode = 'F'
begin
 EXEC adm_set_sched_item 'DE',@sched_id  

 DELETE	sched_transfer
 WHERE	sched_id = @sched_id AND source_flag = 'P'

 EXEC adm_set_sched_process 'DC',NULL,@sched_id  
end

RETURN
END

GO
GRANT EXECUTE ON  [dbo].[fs_clear_schedule] TO [public]
GO
