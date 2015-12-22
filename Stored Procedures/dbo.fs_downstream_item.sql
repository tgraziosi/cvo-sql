SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_downstream_item]
	(
	@sched_item_id		INT=NULL,
	@sched_process_id	INT=NULL,
	@output_mode		CHAR(1)='O'
	)
AS
BEGIN

-- ========================================================================
-- Description: This procedure recurses back through the chain of
--    production to find the ultimate order item and optionally order
--    information for a particular purchase or wip item; or production
--    job.
-- Output Options:
--    'O' - Finish good item and basic order information
--    'C' - Finish good item, enhanced order and customer information
-- ========================================================================

SET NOCOUNT ON

DECLARE	@rowcount		INT,
	@sched_id		INT,
	@hierarchy_level	INT

-- Initialize row count
SELECT	@rowcount=0,
	@hierarchy_level=1

-- Create the results table */
CREATE TABLE #item
	(
	sched_item_id	INT,
	hierarchy_level	INT
	)

CREATE TABLE #order
	(
	sched_order_id	INT
	)

-- Load first level
IF @sched_item_id IS NOT NULL
	BEGIN
	SELECT	@sched_id=SI.sched_id
	FROM	dbo.sched_item SI
	WHERE	SI.sched_item_id = @sched_item_id

	INSERT	#item(sched_item_id,hierarchy_level)
	VALUES(@sched_item_id,@hierarchy_level)

	-- Capture intial row count
	SELECT	@rowcount=@@rowcount
	END
ELSE IF @sched_process_id IS NOT NULL
	BEGIN
	SELECT	@sched_id=SP.sched_id
	FROM	dbo.sched_process SP 
	WHERE	SP.sched_process_id = @sched_process_id

	INSERT	#item(sched_item_id,hierarchy_level)
	SELECT	SI.sched_item_id,@hierarchy_level
	FROM	dbo.sched_item SI 
	WHERE	SI.sched_id = @sched_id
	AND	SI.source_flag = 'M'
	AND	SI.sched_process_id = @sched_process_id

	-- Capture intial row count
	SELECT	@rowcount=@@rowcount
	END

-- While we continue to get more subprocesses, keep adding
WHILE @rowcount > 0
	BEGIN
	-- Assume no more will be added
	SELECT	@rowcount = 0

	-- Grab an item to process
	SELECT	@sched_item_id=MIN(I.sched_item_id)
	FROM	#item I
	WHERE	I.hierarchy_level = @hierarchy_level

	WHILE @sched_item_id IS NOT NULL
		BEGIN
		-- Insert children of items
		INSERT	#item
			(
			sched_item_id,
			hierarchy_level
			)
		SELECT	DISTINCT
			SI.sched_item_id,
			@hierarchy_level+1
		FROM	dbo.sched_operation_item SOI ,
			dbo.sched_operation SO ,
			dbo.sched_item SI 
		WHERE	SOI.sched_item_id = @sched_item_id
		AND	SO.sched_operation_id = SOI.sched_operation_id
		AND	SI.sched_id = @sched_id
		AND	SI.source_flag = 'M'
		AND	SI.sched_process_id = SO.sched_process_id
		AND	SI.sched_process_id IS NOT NULL
		AND NOT EXISTS (SELECT	*
				FROM	#item I2
				WHERE	I2.sched_item_id = SI.sched_item_id)

		-- Capture the number of rows added
		SELECT	@rowcount = @rowcount + @@rowcount

		-- Get next item to process
		SELECT	@sched_item_id=MIN(I.sched_item_id)
		FROM	#item I
		WHERE	I.hierarchy_level = @hierarchy_level
		AND	I.sched_item_id > @sched_item_id
		END

	-- Move to next level in the hierarchy
	SELECT	@hierarchy_level=@hierarchy_level+1
	END

IF @output_mode IN ('O','C')
	BEGIN
	INSERT	#order(sched_order_id)
	SELECT	DISTINCT SOI.sched_order_id
	FROM	#item I,
		dbo.sched_order_item SOI
	WHERE	SOI.sched_item_id = I.sched_item_id
	END

-- Return result set based on output_mode
IF @output_mode = 'O'
	BEGIN
	-- Return the order information
	SELECT	SO.sched_order_id,
		SO.location,
		SO.done_datetime,
		SO.part_no,
		IM.description,
		SO.uom_qty,
		SO.uom,
		SO.order_priority_id,
		SO.source_flag,
		SO.order_no,
		SO.order_ext,
		SO.order_line
	FROM	#order O,
		dbo.sched_order SO,
		dbo.inv_master IM
	WHERE	SO.sched_order_id = O.sched_order_id
	AND	SO.part_no = IM.part_no
	END
ELSE IF @output_mode = 'C'
	BEGIN
	-- Return the order information
	SELECT	SO.sched_order_id,
		SO.location,
		SO.done_datetime,
		SO.part_no,
		IM.description,
		SO.uom_qty,
		SO.uom,
		SO.order_priority_id,
		SO.source_flag,
		SO.order_no,
		SO.order_ext,
		SO.order_line,
		SO.order_line_kit,
		CO.cust_code,
		(SELECT C.customer_name FROM dbo.adm_cust_all C WHERE C.customer_code = CO.cust_code) customer_name
	FROM	#order O,
		dbo.sched_order SO,
		dbo.inv_master IM,
		dbo.orders_all CO
	WHERE	SO.sched_order_id = O.sched_order_id
	AND	SO.source_flag IN ('C','J')
	AND	IM.part_no = SO.part_no
	AND	CO.order_no = SO.order_no
	AND	CO.ext = SO.order_ext
	UNION
	SELECT	SO.sched_order_id,
		SO.location,
		SO.done_datetime,
		SO.part_no,
		IM.description,
		SO.uom_qty,
		SO.uom,
		SO.order_priority_id,
		SO.source_flag,
		SO.order_no,
		SO.order_ext,
		SO.order_line,
		NULL,
		NULL,
		NULL
	FROM	#order O,
		dbo.sched_order SO,
		dbo.inv_master IM
	WHERE	SO.sched_order_id = O.sched_order_id
	AND	SO.source_flag IN ('F','A','M','N')					-- mls 11/12/01 SCR 27837
	AND	IM.part_no = SO.part_no
	END


RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_downstream_item] TO [public]
GO
