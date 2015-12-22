SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 2000 Epicor Software, Inc. All Rights Reserved.
CREATE PROCEDURE [dbo].[fs_prod_operation_supply]
	(
	@sched_process_id       INT
	)
AS
BEGIN

SELECT  dbo.sched_operation.operation_step,
	dbo.sched_item.part_no,
	dbo.sched_item.source_flag,   
        dbo.sched_item.done_datetime,
        dbo.sched_purchase.po_no,   
	dbo.sched_process.prod_no,
	dbo.sched_process.prod_ext,
	dbo.sched_transfer.location 
FROM    dbo.sched_operation
        join dbo.sched_operation_item (nolock) on (dbo.sched_operation.sched_operation_id = dbo.sched_operation_item.sched_operation_id )
	join dbo.sched_item (nolock) on (dbo.sched_item.sched_item_id = dbo.sched_operation_item.sched_item_id )
	left outer join dbo.sched_process (nolock) on (dbo.sched_item.sched_id = dbo.sched_process.sched_id ) and
		(dbo.sched_item.sched_process_id = dbo.sched_process.sched_process_id)
	left outer join dbo.sched_purchase (nolock) on (dbo.sched_item.sched_item_id = dbo.sched_purchase.sched_item_id) 
	left outer join dbo.sched_transfer (nolock) on (dbo.sched_item.sched_transfer_id = dbo.sched_transfer.sched_transfer_id)
WHERE   (dbo.sched_operation.sched_process_id = @sched_process_id)
	
RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_prod_operation_supply] TO [public]
GO
