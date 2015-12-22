SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_release_sched_order]
	(
	@sched_order_id	INT,
	@who		VARCHAR(20)=NULL
	)
WITH ENCRYPTION
AS
BEGIN

DECLARE	@sched_item_id		INT,
	@sched_process_id	INT,
	@prod_no		INT,
	@prod_ext		INT,
	@source_flag		CHAR(1),
        @scheduler_purch_repl   CHAR(10)

-- Set indicator as to whether this installation is replenishing (releasing) purchases from Scheduler
SELECT	@scheduler_purch_repl = CG.value_str FROM dbo.config CG WHERE CG.flag = 'PUR_INV_REPL'

IF @scheduler_purch_repl = 'NO'
    SELECT @scheduler_purch_repl = 'N'
ELSE
    SELECT @scheduler_purch_repl = 'Y'

-- ===========================================================
-- Build list of things to release
-- ===========================================================

CREATE TABLE #rso_sched_process
	(
	sched_process_id	INT
	)

CREATE TABLE #rso_sched_purchase
	(
	sched_item_id	INT,
	status		CHAR(1)	NULL
	)

CREATE TABLE #rso_sched_item
	(
	sched_item_id		INT,
	source_flag		CHAR(1),
	sched_process_id	INT	NULL
	)

-- Determine the type of order
SELECT	@source_flag=SO.source_flag,
	@prod_no = SO.prod_no,
	@prod_ext = SO.prod_ext
FROM	dbo.sched_order SO
WHERE	SO.sched_order_id = @sched_order_id

-- Load first level
IF @source_flag <> 'J'
        BEGIN
        -- If using scheduling to replenish purchases, include planned purchases, else exclude them.
        IF @scheduler_purch_repl = 'Y'
	    INSERT INTO #rso_sched_item(sched_item_id,source_flag,sched_process_id)
	    SELECT	DISTINCT SI.sched_item_id,SI.source_flag,SI.sched_process_id
	    FROM	dbo.sched_order_item SOI,
		    dbo.sched_item SI
	    WHERE	SOI.sched_order_id = @sched_order_id
	    AND	SI.sched_item_id = SOI.sched_item_id
	    AND	SI.source_flag IN ('P','M')
        ELSE
	    INSERT INTO #rso_sched_item(sched_item_id,source_flag,sched_process_id)
	    SELECT	DISTINCT SI.sched_item_id,SI.source_flag,SI.sched_process_id
	    FROM	dbo.sched_order_item SOI,
		    dbo.sched_item SI
	    WHERE	SOI.sched_order_id = @sched_order_id
	    AND	SI.sched_item_id = SOI.sched_item_id
	    AND	SI.source_flag = 'M'
        END
ELSE
	BEGIN
	-- Which process is it?
	SELECT	@sched_process_id=SP.sched_process_id
	FROM	dbo.sched_process SP
	WHERE	SP.prod_no = @prod_no
	AND	SP.prod_ext = @prod_ext

	IF @@rowcount = 0
		BEGIN
		RaisError 69240 'Job has not brought into schedule. Cannot release order dependencies.'
		RETURN
		END
        IF @scheduler_purch_repl = 'Y'
	    INSERT INTO #rso_sched_item(sched_item_id,source_flag,sched_process_id)
	    SELECT	DISTINCT SI.sched_item_id,SI.source_flag,SI.sched_process_id
	    FROM	dbo.sched_operation SO,
	        	dbo.sched_operation_item SOI,
		    dbo.sched_item SI
	    WHERE	SO.sched_process_id = @sched_process_id
	    AND	SOI.sched_operation_id = SO.sched_operation_id
	    AND	SI.sched_item_id = SOI.sched_item_id
	    AND	SI.source_flag IN ('P','M')
        ELSE
	    INSERT INTO #rso_sched_item(sched_item_id,source_flag,sched_process_id)
	    SELECT	DISTINCT SI.sched_item_id,SI.source_flag,SI.sched_process_id
	    FROM	dbo.sched_operation SO,
	        	dbo.sched_operation_item SOI,
		    dbo.sched_item SI
	    WHERE	SO.sched_process_id = @sched_process_id
	    AND	SOI.sched_operation_id = SO.sched_operation_id
	    AND	SI.sched_item_id = SOI.sched_item_id
	    AND	SI.source_flag = 'M'
	END

-- While we continue to get more subprocesses, keep adding
WHILE EXISTS (SELECT * FROM #rso_sched_item)
	BEGIN
	-- Capture all of the items which are purchases
	INSERT	#rso_sched_purchase(sched_item_id)
	SELECT	DISTINCT SI.sched_item_id
	FROM	#rso_sched_item SI
	WHERE	SI.source_flag = 'P'

	-- Grab the process of anything that is made
	INSERT	#rso_sched_process(sched_process_id)
	SELECT	DISTINCT SI.sched_process_id
	FROM	#rso_sched_item SI
	WHERE	SI.source_flag = 'M'
	AND	SI.sched_process_id IS NOT NULL

	-- Add next level to the list	
  
        IF @scheduler_purch_repl = 'Y'
            INSERT INTO #rso_sched_item(sched_item_id,source_flag,sched_process_id)
	    SELECT	DISTINCT SI.sched_item_id,SI.source_flag,SI.sched_process_id
	    FROM	#rso_sched_item TSI,
		    dbo.sched_operation SO,
        	    dbo.sched_operation_item SOI,
	            dbo.sched_item SI
        	WHERE	TSI.source_flag = 'M'
    	        AND	TSI.sched_process_id IS NOT NULL
	        AND	SO.sched_process_id = TSI.sched_process_id
	        AND	SOI.sched_operation_id = SO.sched_operation_id
	        AND	SI.sched_item_id = SOI.sched_item_id
	        AND	SI.source_flag IN ('P','M')
        ELSE
            INSERT INTO #rso_sched_item(sched_item_id,source_flag,sched_process_id)
	    SELECT	DISTINCT SI.sched_item_id,SI.source_flag,SI.sched_process_id
	    FROM	#rso_sched_item TSI,
		    dbo.sched_operation SO,
        	    dbo.sched_operation_item SOI,
	            dbo.sched_item SI
        	WHERE	TSI.source_flag = 'M'
	        AND	TSI.sched_process_id IS NOT NULL
	        AND	SO.sched_process_id = TSI.sched_process_id
	        AND	SOI.sched_operation_id = SO.sched_operation_id
	        AND	SI.sched_item_id = SOI.sched_item_id
	        AND	SI.source_flag = 'M'


	-- Remove all duplicates
	DELETE	#rso_sched_item
	FROM	#rso_sched_item SI
	WHERE	EXISTS (SELECT	*
			FROM	#rso_sched_purchase SP
			WHERE	SP.sched_item_id = SI.sched_item_id)
	OR	EXISTS (SELECT	*
			FROM	#rso_sched_process SP
			WHERE	SP.sched_process_id = SI.sched_process_id)
	END

-- Determine the status for the purchase items
UPDATE	#rso_sched_purchase
SET	status = IM.status
FROM	#rso_sched_purchase SP,
	dbo.sched_item SI,
	dbo.inv_master IM
WHERE	SI.sched_item_id = SP.sched_item_id
AND	IM.part_no = SI.part_no

-- ===========================================================
-- Release all purchase items that need releasing
-- ===========================================================

-- Get first purchase item to release
SELECT	@sched_item_id=MIN(SP.sched_item_id)
FROM	#rso_sched_purchase SP
WHERE	SP.status = 'P'

WHILE @sched_item_id IS NOT NULL
	BEGIN
	-- Determine the current status
	SELECT	@source_flag=SI.source_flag
	FROM	dbo.sched_item SI
	WHERE	SI.sched_item_id = @sched_item_id

	-- If the purchase has not been released, release it
	IF @source_flag = 'P'
		EXECUTE fs_release_sched_purchase @sched_item_id=@sched_item_id,@who=@who

	-- Get next purchase item to release
	SELECT	@sched_item_id=MIN(SP.sched_item_id)
	FROM	#rso_sched_purchase SP
	WHERE	SP.status = 'P'
	AND	SP.sched_item_id > @sched_item_id
	END

-- ===========================================================
-- Release all outsource items that need releasing
-- ===========================================================

-- Get first outsource item to release
SELECT	@sched_item_id=MIN(SP.sched_item_id)
FROM	#rso_sched_purchase SP
WHERE	SP.status = 'Q'

WHILE @sched_item_id IS NOT NULL
	BEGIN
	-- Determine the current status
	SELECT	@source_flag=SI.source_flag
	FROM	dbo.sched_item SI
	WHERE	SI.sched_item_id = @sched_item_id

	-- If the purchase has not been released, release it
	IF @source_flag = 'P'
		EXECUTE fs_release_sched_outsource @sched_item_id=@sched_item_id,@who=@who

	-- Get next outsource item to release
	SELECT	@sched_item_id=MIN(SP.sched_item_id)
	FROM	#rso_sched_purchase SP
	WHERE	SP.status = 'Q'
	AND	SP.sched_item_id > @sched_item_id
	END

-- ===========================================================
-- Release all processes items that need releasing
-- ===========================================================

-- Get first process to release
SELECT	@sched_process_id=MIN(SP.sched_process_id)
FROM	#rso_sched_process SP

WHILE @sched_process_id IS NOT NULL
	BEGIN
	-- Determine the current status
	SELECT	@source_flag=SP.source_flag
	FROM	dbo.sched_process SP
	WHERE	SP.sched_process_id = @sched_process_id

	-- If the process has not been released, release it
	IF @source_flag = 'P'
		EXECUTE fs_release_sched_process @sched_process_id=@sched_process_id,@prod_no=@prod_no OUT,@prod_ext=@prod_ext OUT,@who=@who

	-- Get next process to release
	SELECT	@sched_process_id=MIN(SP.sched_process_id)
	FROM	#rso_sched_process SP
	WHERE	SP.sched_process_id > @sched_process_id
	END

-- ===========================================================
-- If we got here... then all is well
-- ===========================================================

-- Clean up some of the tables
DROP TABLE #rso_sched_item
DROP TABLE #rso_sched_purchase
DROP TABLE #rso_sched_process

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_release_sched_order] TO [public]
GO
