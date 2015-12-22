SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_uncommit_sched_item]
	(
	@sched_item_id	INT
	)
AS
BEGIN



declare @count int

select @count = 0

DELETE	sched_order_item
WHERE	sched_item_id = @sched_item_id

select @count = @@rowcount

DELETE	sched_operation_item
WHERE	sched_item_id = @sched_item_id

select @count = @count + @@rowcount

DELETE	sched_transfer_item
WHERE	sched_item_id = @sched_item_id

select @count = @count + @@rowcount

RETURN @count
END

GO
GRANT EXECUTE ON  [dbo].[fs_uncommit_sched_item] TO [public]
GO
