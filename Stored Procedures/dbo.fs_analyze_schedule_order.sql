SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_analyze_schedule_order]
	(
	@sched_id	INT,
	@option		VARCHAR(36) = NULL
	)
WITH ENCRYPTION
AS
BEGIN

-- DESCRIPTION: This procedure analyzes the orders in a scenario
-- the output format of this procedure MUST match the columns
-- used in the INSERT-EXECUTE into the #analysis table in the
-- procedure fs_analyze_schedule

IF @option IS NULL
	SELECT @option='ABC'

-- Build order list
CREATE TABLE #order
	(
	sched_order_id  INT,
	sched_desc      VARCHAR(64),
	req_datetime    DATETIME,
	req_quantity    FLOAT,
	act_datetime    DATETIME	NULL,	-- Actual planned ship date
	act_quantity    FLOAT		NULL,	-- Actual planned quantity
	ava_quantity    FLOAT		NULL,	-- Available quantity by date
	prod_no		INT		NULL,	-- Production number and extension
	prod_ext	INT		NULL	--	if demand is a job
	)

-- Get the planned numbers
INSERT	#order
	(
	sched_order_id,
	sched_desc,
	req_datetime,
	req_quantity,
	act_datetime,
	act_quantity,
	ava_quantity,
	prod_no,
	prod_ext
	)
SELECT  SO.sched_order_id,				-- sched_order_id
	CASE SO.source_flag
	WHEN 'C' THEN 'Customer Order #'+CONVERT(VARCHAR(8),SO.order_no)+'-'+CONVERT(VARCHAR(8),SO.order_ext)+','+CONVERT(VARCHAR(8),SO.order_line)
	WHEN 'A' THEN 'Auto Order for ['+SO.part_no+'] on '+CONVERT(VARCHAR(32),SO.done_datetime)
	WHEN 'F' THEN 'Firm Order for ['+SO.part_no+'] on '+CONVERT(VARCHAR(32),SO.done_datetime)
	WHEN 'J' THEN 'Job #'+LTrim(Str(SO.prod_no))+IsNull('-'+LTrim(Str(SO.prod_no)),'')
	ELSE          'Order'
	END,
	SO.done_datetime,				-- req_datetime
	SO.uom_qty,					-- req_quantity
	(       SELECT  MAX(SI.done_datetime)		-- act_datetime
		FROM    dbo.sched_item SI,
			dbo.sched_order_item SOI
		WHERE   SOI.sched_order_id = SO.sched_order_id
		AND     SI.sched_item_id = SOI.sched_item_id ),
	(       SELECT  SUM(SI.uom_qty)			-- act_quantity
		FROM    dbo.sched_item SI,
			dbo.sched_order_item SOI
		WHERE   SOI.sched_order_id = SO.sched_order_id
		AND     SI.sched_item_id = SOI.sched_item_id ),
	(       SELECT  SUM(SI.uom_qty)			-- ava_quantity
		FROM    dbo.sched_item SI,
			dbo.sched_order_item SOI
		WHERE   SOI.sched_order_id = SO.sched_order_id
		AND     SI.sched_item_id = SOI.sched_item_id
		AND     SI.done_datetime <= SO.done_datetime ),
	SO.prod_no,					-- prod_no,
	SO.prod_ext					-- prod_ext
FROM    dbo.sched_order SO
WHERE   SO.sched_id = @sched_id

-- Find all unscheduled orders
IF CHARINDEX('A',@option) > 0
	BEGIN
	-- Typical customer orders
	SELECT  'A',			-- source_flag		CHAR(1)
		O.sched_desc		-- summary		VARCHAR(80)
		+ ' has no inventory commited to it',
		O.sched_order_id	-- sched_order_id	INT		NULL
	FROM    #order O (NOLOCK)
	WHERE   O.act_quantity IS NULL
	AND	(	O.prod_no IS NULL
		OR	O.prod_ext IS NULL)

	-- Customer jobs
	SELECT  'A',			-- source_flag		CHAR(1)
		O.sched_desc		-- summary		VARCHAR(80)
		+ ' has not been scheduled',
		O.sched_order_id	-- sched_order_id	INT		NULL
	FROM    #order O (NOLOCK)
	WHERE   O.act_quantity IS NULL
	AND	O.prod_no IS NOT NULL
	AND	O.prod_ext IS NOT NULL
	AND NOT EXISTS (SELECT	*
			FROM	dbo.sched_process SP
			WHERE	SP.sched_id = @sched_id
			AND	SP.source_flag = 'R'
			AND	SP.prod_no = O.prod_no
			AND	SP.prod_ext = O.prod_ext)
	END


IF CHARINDEX('B',@option) > 0
	SELECT  'B',			-- source_flag		CHAR(1)
		O.sched_desc		-- summary		VARCHAR(80)
		+ ' is under-committed (' + CONVERT(VARCHAR(4),Round(100*O.act_quantity/O.req_quantity,0))+'% of order quantity)',
		O.sched_order_id	-- sched_order_id	INT		NULL
	FROM    #order O (NOLOCK)
	WHERE   O.act_quantity < O.req_quantity


IF CHARINDEX('C',@option) > 0
	SELECT  'C',			-- source_flag		CHAR(1)
		O.sched_desc		-- summary		VARCHAR(80)
		+ ' will be late ('+ CONVERT(VARCHAR(4),Round(100*IsNull(O.ava_quantity,0.0)/O.req_quantity,0)) + '% fulfilled by due date)',
		O.sched_order_id	-- sched_order_id	INT		NULL
	FROM    #order O (NOLOCK)
	WHERE   O.act_datetime > O.req_datetime

DROP TABLE #order

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_analyze_schedule_order] TO [public]
GO
