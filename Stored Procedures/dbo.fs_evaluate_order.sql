SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1998 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_evaluate_order]
	(
	@sched_id INT = NULL,
	@order_no INT = NULL,
	@order_ext INT = NULL,
	@sched_order_id	INT = NULL,
	@output_mode CHAR(1) = 'B'
	)

AS
BEGIN

-- =====================================================================
-- This procedure collects the dependencies of a particular order and
-- determines the status and problems which may be holding an order up.
-- =====================================================================

DECLARE	@location		VARCHAR(10),
	@part_no		VARCHAR(30),
	@source_flag		CHAR(1),
	@prod_no		INT,
	@prod_ext		INT,
	@demand_qty		FLOAT,
	@assign_qty		FLOAT,
	@ontime_qty		FLOAT,
	@order_id		INT,
	@sched_process_id	INT,
	@sched_operation_id	INT,
	@sched_resource_id	INT,
	@operation_step		INT,
	@item_datetime		DATETIME,
	@work_datetime		DATETIME,
	@done_datetime		DATETIME,
	@setup_datetime		DATETIME,
	@def_pool_qty		FLOAT,
	@use_pool_qty		FLOAT,
	@tot_pool_qty		FLOAT,
	@max_pool_qty		FLOAT,
	@work_date		DATETIME,
	@calendar_id		INT,
	@resource_id		INT

-- Create list of orders to process

CREATE TABLE #order
	(
	sched_order_id INT
	)

-- Build list by processing parameters

IF @sched_order_id IS NOT NULL
	BEGIN

	-- Add order to the list

	INSERT #order(sched_order_id)
	SELECT	SO.sched_order_id
	FROM	dbo.sched_order SO
	WHERE	SO.sched_order_id = @sched_order_id

	END
ELSE IF @sched_id IS NULL
	BEGIN
	RaisError 69010 'No schedule scenario specified'
	RETURN
	END
ELSE IF @order_no IS NULL
	BEGIN
	INSERT	#order(sched_order_id)
	SELECT	SO.sched_order_id
	FROM	dbo.sched_order SO
	WHERE	SO.sched_id = @sched_id
	END
ELSE IF @order_ext IS NULL
	BEGIN
	INSERT	#order(sched_order_id)
	SELECT	SO.sched_order_id
	FROM	dbo.sched_order SO
	WHERE	SO.sched_id = @sched_id
	AND	SO.order_no = @order_no
	END
ELSE
	BEGIN
	INSERT	#order(sched_order_id)
	SELECT	SO.sched_order_id
	FROM	dbo.sched_order SO
	WHERE	SO.sched_id = @sched_id
	AND	SO.order_no = @order_no
	AND	SO.order_ext = @order_ext
	END

-- Did any orders match the criteria???

IF NOT EXISTS(SELECT * FROM #order)
	BEGIN
	RaisError 69210 'No order(s) match specified criteria'
	RETURN
	END

-- NOTE: From this point forward, all parameters are used 
-- as variables EXCEPT @output_mode

-- =====================================================================
-- Prepare to collect results
-- =====================================================================

-- Create results table

CREATE TABLE #result
	(
	sched_order_id	INT,
	note		VARCHAR(255)
	)

CREATE TABLE #item
	(
	sched_item_id	INT,
	uom_qty		FLOAT,
	done_datetime	DATETIME,
	source_flag	CHAR(1)
	)

CREATE TABLE #process
	(
	order_id		INT IDENTITY,
	sched_process_id	INT
	)

-- =====================================================================
-- Process list of orders
-- =====================================================================

-- Get first order to analyze

SELECT	@sched_order_id=MIN(O.sched_order_id)
FROM	#order O

WHILE	@sched_order_id IS NOT NULL
	BEGIN

	-- Retrieve order information

	SELECT	@location=SO.location,
		@done_datetime=SO.done_datetime,
		@part_no=SO.part_no,
		@demand_qty=SO.uom_qty,
		@source_flag=SO.source_flag,
		@prod_no=SO.prod_no,
		@prod_ext=SO.prod_ext
	FROM	dbo.sched_order SO
	WHERE	SO.sched_order_id = @sched_order_id

	-- What type of order is this???

	IF @source_flag = 'J'
		BEGIN

		-- Job order... we seek processes

		INSERT INTO #process(sched_process_id)
		SELECT	DISTINCT
			SP.sched_process_id
		FROM	dbo.sched_process SP
		WHERE	SP.prod_no = @prod_no
		AND	SP.prod_ext = @prod_ext
		END
	ELSE
		BEGIN

		-- Normal order... we seek materials

		INSERT	#item(sched_item_id,uom_qty,done_datetime,source_flag)
		SELECT	SOI.sched_item_id,SOI.uom_qty,SI.done_datetime,SI.source_flag
		FROM	dbo.sched_order_item SOI,
			dbo.sched_item SI
		WHERE	SOI.sched_order_id = @sched_order_id
		AND	SI.sched_item_id = SOI.sched_item_id

		-- Determine amount that is assigned

		SELECT	@assign_qty=IsNull(SUM(I.uom_qty),0.0)
		FROM	#item I

		-- Determine amount ready by ship date

		SELECT	@ontime_qty=IsNull(SUM(I.uom_qty),0.0)
		FROM	#item I
		WHERE	I.done_datetime <= @done_datetime
		OR	source_flag = 'I'

		-- If any will be done in time, notify the user

		IF @ontime_qty > 0.0
			INSERT	#result(sched_order_id,note)
			VALUES	(@sched_order_id,str(100.0*@ontime_qty/@demand_qty,3)+'% available on time')

		-- Remove on-time and inventory amounts

		DELETE	#item
		WHERE	done_datetime <= @done_datetime
		OR	source_flag = 'I'

		-- If a portion is simply not scheduled, notify the user

		IF @assign_qty <= 0.0
			INSERT	#result(sched_order_id,note)
			VALUES	(@sched_order_id,'Order has not been scheduled')
		ELSE IF @assign_qty < @demand_qty
			INSERT	#result(sched_order_id,note)
			VALUES	(@sched_order_id,str(100.0*(@demand_qty-@assign_qty)/@demand_qty,3)+'% has not been scheduled')

		-- If we are not shipping all of them, find out why

		IF @ontime_qty < @assign_qty
			INSERT	#result(sched_order_id,note)
			VALUES	(@sched_order_id,str(100.0*(@assign_qty-@ontime_qty)/@demand_qty,3)+'% will be late')

		-- If any of items are purchases/transfers... then the purchase/transfers is holding us up

		INSERT	#result(sched_order_id,note)
		SELECT	@sched_order_id,
			'Waiting on '+
			CASE I.source_flag
			WHEN 'P' THEN 'PLANNED purchase'
			WHEN 'R' THEN 'RELEASED purchase'
			WHEN 'O' THEN 'PO# '+SP.po_no
			WHEN 'T' THEN 'transfer #'+ltrim(str(SP.xfer_no))
			WHEN 'X' THEN 'transfer #'+ltrim(str(ST.xfer_no))
			ELSE 'UNKNOWN source ('''+I.source_flag+''')'
			END +' for '+SI.part_no+' ('+ltrim(str(I.uom_qty))+'/'+ltrim(str(SI.uom_qty))+' '+SI.uom+')'
		FROM	#item I
		join	dbo.sched_item SI (nolock) on SI.sched_item_id = I.sched_item_id
		left outer join dbo.sched_transfer ST (nolock) on ST.sched_transfer_id = SI.sched_transfer_id
		left outer join dbo.sched_purchase SP (nolock) on SP.sched_item_id = I.sched_item_id
		WHERE	I.source_flag <> 'M'

		-- Add the processes to the mix

		INSERT INTO #process(sched_process_id)
		SELECT	DISTINCT
			SI.sched_process_id
		FROM	#item I,
			dbo.sched_item SI
		WHERE	I.source_flag = 'M'
		AND	SI.sched_item_id = I.sched_item_id
		AND	SI.sched_process_id IS NOT NULL

		-- Clear item list... until next time

		DELETE	#item
		END

	-- Recurse through processes
	-- Find first process to examine

	SELECT	@order_id=MIN(P.order_id)
	FROM	#process P

	WHILE @order_id IS NOT NULL
		BEGIN

		-- Get the process listed

		SELECT	@sched_process_id=P.sched_process_id
		FROM	#process P
		WHERE	P.order_id = @order_id

		-- Evaluate the process operations, find first

		SELECT	@operation_step=MAX(SO.operation_step)
		FROM	dbo.sched_operation SO
		WHERE	SO.sched_process_id = @sched_process_id

		-- Get the operation information

		SELECT	@sched_operation_id=SO.sched_operation_id,
			@work_datetime=SO.work_datetime
		FROM	dbo.sched_operation SO
		WHERE	SO.sched_process_id = @sched_process_id
		AND	SO.operation_step = @operation_step

		WHILE @operation_step IS NOT NULL
			BEGIN

			-- Evaluate the operation materials, collect all materials
			-- needed. Exclude all purchases or transfers which arrive more
			-- than 24 hours in advance
			
			INSERT	#item(sched_item_id,uom_qty,done_datetime,source_flag)
			SELECT	SOI.sched_item_id,SOI.uom_qty,SI.done_datetime,SI.source_flag
			FROM	dbo.sched_operation_item SOI,
				dbo.sched_item SI
			WHERE	SOI.sched_operation_id = @sched_operation_id
			AND	SI.sched_item_id = SOI.sched_item_id
			AND	SI.source_flag <> 'I'
			AND	(	SI.source_flag = 'M'
				OR	SI.done_datetime > dateadd(day,-2,@work_datetime))

			-- Determine any non-make items that could be holding this process up

			INSERT	#result(sched_order_id,note)
			SELECT	@sched_order_id,
				'Waiting on '+
				CASE I.source_flag
				WHEN 'P' THEN 'PLANNED purchase'
				WHEN 'R' THEN 'RELEASED purchase'
				END +' for '+SI.part_no+' ('+ltrim(str(I.uom_qty))+'/'+ltrim(str(SI.uom_qty))+' '+SI.uom+')'
			FROM	#item I
			join	dbo.sched_item SI (nolock) on SI.sched_item_id = I.sched_item_id
			left outer join dbo.sched_transfer ST (nolock) on ST.sched_transfer_id = SI.sched_transfer_id
			join	dbo.sched_purchase SP (nolock) on SP.sched_item_id = I.sched_item_id and SP.lead_datetime < getdate()
			WHERE	I.source_flag IN ('P','R')

			INSERT	#result(sched_order_id,note)
			SELECT	@sched_order_id,
				'Waiting on '+
				CASE I.source_flag
				WHEN 'O' THEN 'PO# '+SP.po_no
				WHEN 'T' THEN 'transfer #'+ltrim(str(SP.xfer_no))
				WHEN 'X' THEN 'transfer #'+ltrim(str(ST.xfer_no))
				ELSE 'unknown source ('''+I.source_flag+''')'
				END +' for '+SI.part_no+' ('+ltrim(str(I.uom_qty))+'/'+ltrim(str(SI.uom_qty))+' '+SI.uom+')'
			FROM	#item I
			join	dbo.sched_item SI (nolock) on SI.sched_item_id = I.sched_item_id
			left outer join dbo.sched_transfer ST (nolock) on ST.sched_transfer_id = SI.sched_transfer_id
			left outer join dbo.sched_purchase SP (nolock) on SP.sched_item_id = I.sched_item_id
			WHERE	I.source_flag NOT IN ('M','P','R')

			-- Determine the earliest that this operation could have run

			SELECT	@item_datetime=IsNull(MAX(I.done_datetime),getdate())
			FROM	#item I

			-- Determine preceding processes

			INSERT	#process(sched_process_id)
			SELECT	DISTINCT SI.sched_process_id
			FROM	#item I,
				dbo.sched_item SI
			WHERE	I.source_flag = 'M'
			AND	SI.sched_item_id = I.sched_item_id
			AND	SI.sched_process_id IS NOT NULL
			AND NOT EXISTS (SELECT	*
					FROM	#process P
					WHERE	P.sched_process_id = SI.sched_process_id)

			-- Clear out materials for next pass

			DELETE #item

			-- Get previous operation

			SELECT	@operation_step=MAX(SO.operation_step)
			FROM	dbo.sched_operation SO
			WHERE	SO.sched_process_id = @sched_process_id
			AND	SO.operation_step < @operation_step

			-- If there is not a previous step,
			-- then assume today is the earliest the job could run,
			-- otherwise when did the previous step finish

			IF @operation_step IS NULL
				SELECT	@done_datetime = getdate()
			ELSE
				SELECT	@done_datetime=SO.done_datetime
				FROM	dbo.sched_operation SO
				WHERE	SO.sched_process_id = @sched_process_id
				AND	SO.operation_step = @operation_step

			-- If the previous operation ended later,
			-- adjust the stop datetime

			IF @done_datetime < @item_datetime
				SELECT @done_datetime = @item_datetime

			-- Check resource schedules, could this operation been run earlier

			IF @done_datetime < @work_datetime
				BEGIN
				-- Get first resource

				SELECT	@sched_resource_id=MIN(SOR.sched_resource_id)
				FROM	dbo.sched_operation_resource SOR
				WHERE	SOR.sched_operation_id = @sched_operation_id

				WHILE @sched_resource_id IS NOT NULL
					BEGIN

					-- Retrieve resource information

					SELECT	@resource_id=SR.resource_id,
						@calendar_id=IsNull(SR.calendar_id,R.calendar_id),
						@def_pool_qty=R.pool_qty
					FROM	dbo.sched_resource SR,
						dbo.resource R
					WHERE	SR.sched_resource_id = @sched_resource_id
					AND	R.resource_id = SR.resource_id

					-- Retrieve the operation setup time

					SELECT	@setup_datetime = SOR.setup_datetime,
						@use_pool_qty = SOR.pool_qty
					FROM	dbo.sched_operation_resource SOR
					WHERE	SOR.sched_operation_id = @sched_operation_id
					AND	SOR.sched_resource_id = @sched_resource_id

					-- Determine total pool allocation at process start time

					SELECT	@tot_pool_qty = IsNull(SUM(SOR.pool_qty),0.0)
					FROM	dbo.sched_operation_resource SOR,
						dbo.sched_operation SO
					WHERE	SOR.sched_resource_id = @sched_resource_id
					AND	SO.sched_operation_id = SOR.sched_operation_id
					AND	SOR.setup_datetime < @setup_datetime
					AND	SO.done_datetime >= @setup_datetime

					-- Calculate the work date

					SELECT	@work_date = datename(year,@setup_datetime)+'-'+datename(month,@setup_datetime)+'-'+datename(day,@setup_datetime),
						@max_pool_qty = 0.0

					-- Determine total pool available

					SELECT	@max_pool_qty=IsNull(RP.pool_qty,@def_pool_qty)
					FROM	dbo.resource_pool RP,
						dbo.calendar_worktime CW
					WHERE	RP.resource_id = @resource_id
					AND	CW.calendar_id = @calendar_id
					AND	CW.calendar_worktime_id = RP.calendar_worktime_id
					AND	CW.eff_date <= @work_date
					AND	CW.exp_date >= @work_date
					AND	dateadd(minute,CW.beg_time * 60,@work_date) <= @setup_datetime
					AND	dateadd(minute,CW.end_time * 60,@work_date) > @setup_datetime
					AND	(	CW.weekday_mask IS NULL
						OR	CW.weekday_mask & power(2,datepart(weekday,@work_date) - 1) <> 0)
					AND	(	CW.week_multiple IS NULL
						OR	datediff(week,CW.eff_date,@work_date) % CW.week_multiple = 0)
					AND	(	CW.month_multiple IS NULL
						OR	datediff(month,CW.eff_date,@work_date) % CW.month_multiple = 0)
					AND	(	CW.monthweek IS NULL
						OR	(datepart(day,@work_date) - 1) / 7 = CW.monthweek - 1)
					AND	(	CW.monthday IS NULL
						OR	datepart(day,@work_date) = CW.monthday)

					-- Determine if this resource was restricted

					IF @use_pool_qty + @tot_pool_qty >= @max_pool_qty
						INSERT	#result(sched_order_id,note)
						SELECT	@sched_order_id,'Waiting on resource '+R.resource_code+' on '+Convert(VARCHAR(32),@setup_datetime)
						FROM	dbo.sched_resource SR,
							dbo.resource R
						WHERE	SR.sched_resource_id = @sched_resource_id
						AND	R.resource_id = SR.resource_id

					-- Get next resource

					SELECT	@sched_resource_id=MIN(SOR.sched_resource_id)
					FROM	dbo.sched_operation_resource SOR
					WHERE	SOR.sched_operation_id = @sched_operation_id
					AND	SOR.sched_resource_id > @sched_resource_id
					END

				-- Force us out of this loop

				SELECT	@operation_step=NULL

				END

			-- Move previous operation information into current

			IF @operation_step IS NOT NULL
				SELECT	@sched_operation_id=SO.sched_operation_id,
					@work_datetime=SO.work_datetime
				FROM	dbo.sched_operation SO
				WHERE	SO.sched_process_id = @sched_process_id
				AND	SO.operation_step = @operation_step
			END

		-- Find next process to be examined

		SELECT	@order_id=MIN(P.order_id)
		FROM	#process P
		WHERE	P.order_id > @order_id
		END

	-- Clear material tables

	DELETE	#item
	DELETE	#process

	-- Get next order to analyze

	SELECT	@sched_order_id=MIN(O.sched_order_id)
	FROM	#order O
	WHERE	O.sched_order_id > @sched_order_id
	END

-- =====================================================================
-- Report results
-- =====================================================================

SELECT	SO.sched_order_id,
	SO.source_flag,
	SO.order_no,
	SO.order_ext,
	SO.order_line,
	SO.order_line_kit,
	SO.part_no,
	IM.description,
	R.note
FROM	#result R,
	dbo.sched_order SO,
	dbo.inv_master IM
WHERE	SO.sched_order_id = R.sched_order_id
AND	IM.part_no = SO.part_no

-- Temporary table clean up

DROP TABLE #item
DROP TABLE #result
DROP TABLE #order

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_evaluate_order] TO [public]
GO
