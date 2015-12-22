SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_analyze_schedule_purchase]
	(
	@sched_id	INT,
	@option		VARCHAR(36) = NULL
	)
WITH ENCRYPTION
AS
BEGIN

-- DESCRIPTION: This procedure analyzes the purchases in a scenario
-- the output format of this procedure MUST match the columns
-- used in the INSERT-EXECUTE into the #analysis table in the
-- procedure fs_analyze_schedule

IF @option IS NULL
	SELECT @option='DE'

-- Find all late purchases
IF CHARINDEX('D',@option) > 0
	SELECT  'D',			-- source_flag
		'PO#'+SP.po_no+' for '+SI.part_no+' is past due', -- summary
		SI.sched_item_id	-- sched_item_id
	FROM    dbo.sched_item SI,
		dbo.sched_purchase SP
	WHERE   SI.sched_id = @sched_id
	AND     SI.source_flag = 'O'
	AND     SI.done_datetime < getdate()
	AND	SP.sched_item_id = SI.sched_item_id

-- Find all purchase orders past due for submission, if used
IF CHARINDEX('E',@option) > 0
	SELECT  'E',			-- source_flag
		'PO#'+SP.po_no+' for '+SI.part_no+' is late for ordering',	-- summary
		SI.sched_item_id	-- sched_item_id
	FROM    dbo.sched_model SM,
		dbo.sched_item SI,
		dbo.sched_purchase SP
	WHERE   SM.sched_id = @sched_id
	AND     SM.purchase_lead_flag IN ('S','W')
	AND     SI.sched_id = SM.sched_id
	AND     SI.source_flag = 'P'
	AND     SP.sched_item_id = SI.sched_item_id
	AND     SP.lead_datetime < getdate()

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_analyze_schedule_purchase] TO [public]
GO
