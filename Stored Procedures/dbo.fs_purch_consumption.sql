SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 2000 Epicor Software, Inc. All Rights Reserved.
CREATE PROCEDURE [dbo].[fs_purch_consumption]
	(
	@sched_item_id          INT
	)
AS
BEGIN

SELECT  dbo.sched_item.part_no,
	isnull(dbo.sched_item.uom_qty,dbo.sched_process.process_unit),		-- mls 6/12/02 SCR 29063
	dbo.sched_item.uom,
	isnull(dbo.sched_item.done_datetime,dbo.sched_operation.done_datetime),	-- mls 6/12/02 SCR 29063
	dbo.sched_process.prod_no,
	dbo.sched_process.prod_ext,
	dbo.sched_operation.operation_step,
	dbo.sched_operation_item.demand_datetime,
	dbo.sched_operation.work_datetime
FROM    dbo.sched_operation_item
join	dbo.sched_operation (nolock) on (dbo.sched_operation.sched_operation_id = dbo.sched_operation_item.sched_operation_id)
join	dbo.sched_process (nolock) on (dbo.sched_process.sched_process_id = dbo.sched_operation.sched_process_id) 
left outer join dbo.sched_item (nolock) on (dbo.sched_item.sched_process_id = dbo.sched_process.sched_process_id)	-- mls 6/12/02 SCR 29063
WHERE   (dbo.sched_operation_item.sched_item_id = @sched_item_id) 

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_purch_consumption] TO [public]
GO
