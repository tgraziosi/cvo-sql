SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_analyze_schedule]
	(
	@sched_id	INT,
	@option		VARCHAR(36) = NULL
	)
WITH ENCRYPTION
AS
BEGIN

-- =================================================
-- Options Mask:
--   'A' - Unscheduled Orders
--   'B' - Short Orders
--   'C' - Late Orders
--   'D' - Late Purchase Orders
--   'E' - Late Purchase Releases
--   'F' - Recursive Build Plan
-- =================================================

IF @option IS NULL
	SELECT @option='ABCDEF'

-- =================================================
-- Create the results table
-- =================================================

CREATE TABLE #analysis
	(
	source_flag		CHAR(1),
	summary			VARCHAR(128),
	message			VARCHAR(255)	NULL,
	sched_item_id		INT		NULL,
	sched_order_id		INT		NULL,
	sched_transfer_id	INT		NULL,
	sched_process_id	INT		NULL,
	sched_operation_id	INT		NULL,
	sched_resource_id	INT		NULL
	)

-- Check Orders
IF CHARINDEX('A',@option) > 0 OR CHARINDEX('B',@option) > 0 OR CHARINDEX('C',@option) > 0
	INSERT	#analysis(source_flag,summary,sched_order_id)
	EXECUTE	fs_analyze_schedule_order @sched_id=@sched_id,@option=@option

-- Check Purchases
IF CHARINDEX('D',@option) > 0 OR CHARINDEX('E',@option) > 0
	INSERT	#analysis(source_flag,summary,sched_item_id)
	EXECUTE	fs_analyze_schedule_purchase @sched_id=@sched_id,@option=@option

-- Check for recursive build plans
IF CHARINDEX('F',@option) > 0
	INSERT	#analysis(source_flag,summary,message,sched_order_id)
	EXECUTE	fs_analyze_schedule_recursion @sched_id=@sched_id

-- Return the results
SELECT	source_flag,
	summary,
	message,	
	sched_item_id,
	sched_order_id,
	sched_transfer_id,
	sched_process_id,
	sched_operation_id,
	sched_resource_id
FROM	#analysis
ORDER BY source_flag

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_analyze_schedule] TO [public]
GO
