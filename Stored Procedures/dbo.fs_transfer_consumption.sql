SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 2000 Epicor Software, Inc. All Rights Reserved.
CREATE PROCEDURE [dbo].[fs_transfer_consumption]
	(
	@sched_transfer_id       INT
	)
WITH ENCRYPTION
AS
BEGIN

SELECT  dbo.sched_item.part_no,
	dbo.sched_item.uom_qty,
	dbo.sched_item.uom,
	dbo.sched_item.done_datetime,
	dbo.sched_transfer.location,
	dbo.sched_process.prod_no,
	dbo.sched_process.prod_ext,
	dbo.sched_operation.operation_step,
	dbo.sched_operation_item.demand_datetime,
	dbo.sched_operation.work_datetime
FROM    dbo.sched_item,
	dbo.sched_operation,   
        dbo.sched_operation_item,
	dbo.sched_transfer,
	dbo.sched_process
WHERE   (dbo.sched_item.sched_transfer_id = @sched_transfer_id) AND
	(dbo.sched_item.sched_transfer_id = dbo.sched_transfer.sched_transfer_id) AND
	(dbo.sched_item.sched_item_id = dbo.sched_operation_item.sched_item_id) AND
	(dbo.sched_operation.sched_operation_id = dbo.sched_operation_item.sched_operation_id) AND
	(dbo.sched_process.sched_process_id = dbo.sched_operation.sched_process_id)


RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_transfer_consumption] TO [public]
GO
