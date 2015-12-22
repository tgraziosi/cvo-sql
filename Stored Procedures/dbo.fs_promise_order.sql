SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_promise_order]
	(
	@sched_id	INT = NULL,
	@order_no	INT,
	@order_ext	INT,
	@debug_mode	CHAR(1) = 'N'
	)
WITH ENCRYPTION
AS
BEGIN
DECLARE	@order_priority_id	INT,

	@sched_item_id		INT,
	@sched_resource_id	INT,
	@sched_operation_id	INT,
	@calendar_id		INT,

	@uom_qty		FLOAT,

	@ave_time		FLOAT,
	@run_time		FLOAT,

	@demand_id		INT,
	@demand_order_id	INT,
	@demand_process_id	INT,
	@demand_operation_id	INT,
	@demand_datetime	DATETIME,
	@demand_location	VARCHAR(10),
	@demand_part_no		VARCHAR(30),
	@demand_uom_qty		FLOAT,
	@demand_uom		CHAR(2),
	@demand_status		CHAR(1),

	@supply_item_id		INT,
	@supply_datetime	DATETIME,
	@surplus_uom_qty	FLOAT,

	@process_unit		FLOAT,
	@process_unit_orig	FLOAT,		-- rev 1
	@ave_pool_qty		FLOAT,

	@operation_step		INT,
	@operation_type		CHAR(1),
	@bcal_datetime		DATETIME,
	@ecal_datetime		DATETIME,
	@beg_datetime		DATETIME,
	@end_datetime		DATETIME,
	@oper_datetime		DATETIME,
	@work_datetime		DATETIME,
	@done_datetime		DATETIME,
	@stop_datetime		DATETIME,
	@plan_operation_id	INT,
	@plan_resource_id	INT,
	@plan_location		VARCHAR(10),
	@plan_seq_no		VARCHAR(4),
	@plan_part_no		VARCHAR(30),
	@plan_uom_qty		FLOAT,
	@message		VARCHAR(255)

IF @debug_mode='Y'
	BEGIN
	SELECT	@message='Parameters: @sched_id='+IsNull(ltrim(str(@sched_id)),'(NULL)')+',@order_no='+ltrim(str(@order_no))+',@order_ext='+ltrim(str(@order_ext))+',@debug_mode='+IsNull(@debug_mode,'(NULL)')
	PRINT	@message
	END

SELECT	@bcal_datetime=getdate(),
	@ecal_datetime=dateadd(day,365,getdate())

-- =================================================
-- If the schedule identifer has not passed, find it
-- =================================================

IF @sched_id IS NULL
	BEGIN
	SELECT	@sched_id=SM.sched_id
	FROM	dbo.config C,
		dbo.sched_model SM
	WHERE	C.flag = 'SCHEDULE_CTP_ID'
	AND	SM.sched_name = C.value_str

	IF @@rowcount <> 1
		BEGIN
		RaisError 60000 'Default schedule scenario is not defined for capable to promise'
		RETURN
		END
	END

-- =================================================
-- Make sure that the order is in scheduling
-- =================================================

-- Determine the order priority
SELECT	@order_priority_id=OP.order_priority_id
FROM	dbo.order_priority OP
WHERE	OP.usage_flag = 'D'

IF @@rowcount <> 1
	BEGIN
	RaisError 64049 'Unable to determine default order priority'
	RETURN
	END

-- Delete parts of the order that have been removed
DELETE	dbo.sched_order
FROM	dbo.sched_order SO
WHERE	SO.sched_id = @sched_id
AND	SO.order_no = @order_no
AND	SO.order_ext = @order_ext
AND	SO.source_flag = 'C'
AND NOT EXISTS(	SELECT	*
		FROM	dbo.ord_list OL
		WHERE	OL.order_no = @order_no
		AND	OL.order_ext = @order_ext
		AND	OL.line_no = SO.order_line
		AND	OL.status = 'N' )

-- Update order line items that have been changed
UPDATE	dbo.sched_order
SET	done_datetime = O.sch_ship_date,
	part_no = OL.part_no,
	uom_qty = (OL.ordered - OL.shipped) * OL.conv_factor,
	uom = IM.uom
FROM	dbo.sched_order SO,
	dbo.orders_all O,
	dbo.ord_list OL,
	dbo.inv_master IM
WHERE	SO.sched_id = @sched_id
AND	SO.source_flag = 'C'
AND	SO.order_no = @order_no
AND	SO.order_ext = @order_ext
AND	O.order_no = @order_no
AND	O.ext = @order_ext
AND	O.status = 'N'
AND	OL.order_no = @order_no
AND	OL.order_ext = @order_ext
AND	OL.line_no = SO.order_line
AND	IM.part_no = SO.part_no
AND	IM.part_no = OL.part_no
AND	(	SO.done_datetime <> O.sch_ship_date
	OR	SO.part_no <> OL.part_no
	OR	SO.uom_qty <> (OL.ordered - OL.shipped) * OL.conv_factor
	OR	SO.uom <> IM.uom
	)
	
-- Insert any new line items
INSERT	dbo.sched_order
	(
	sched_id,
	location,
	done_datetime,
	part_no,
	uom_qty,
	uom,
	order_priority_id,
	source_flag,
	order_no,
	order_ext,
	order_line
	)
SELECT	@sched_id,
	OL.location,
	IsNull(O.sch_ship_date,O.req_ship_date),
	OL.part_no,
	(OL.ordered - OL.shipped) * OL.conv_factor,
	IM.uom,
	@order_priority_id,
	'C',
	OL.order_no,
	OL.order_ext,
	OL.line_no
FROM	dbo.sched_location SL,
	dbo.orders_all O,
	dbo.ord_list OL,
	dbo.inv_master IM
WHERE	SL.sched_id = @sched_id
AND	O.order_no = @order_no
AND	O.ext = @order_ext
AND	O.status = 'N'
AND	OL.order_no = @order_no
AND	OL.order_ext = @order_ext
AND	OL.location = SL.location
AND	OL.status = 'N'
AND	OL.ordered > OL.shipped
AND	IM.part_no = OL.part_no
AND	NOT EXISTS (	SELECT	*
			FROM	dbo.sched_order SO
			WHERE	SO.sched_id = @sched_id
			AND	SO.source_flag = 'C'
			AND	SO.order_no = @order_no
			AND	SO.order_ext = @order_ext
			AND	SO.order_line = OL.line_no )

IF @debug_mode = 'Y'
	SELECT	*
	FROM	dbo.sched_order SO
	WHERE	SO.order_no = @order_no
	AND	SO.order_ext = @order_ext

-- =================================================
-- Gap analysis of order to schedule
-- =================================================

-- The follwoing table list the current demands required to deliver this order
-- Each demand will got to fill the order or and operation required in the
-- chain of build plans to make this item. If sched_operation_id is not NULL
-- then this demand is for a process in the chain. If sched_operation is NULL
-- then this is the top most order demand. The sched_process_id is the id of
-- a process that was used to attempt to make this item

CREATE TABLE #demand
	(
	demand_id		INT	IDENTITY,
	sched_order_id		INT,		-- The requesting demand order
	work_datetime		DATETIME,
	location		VARCHAR(10),
	part_no			VARCHAR(30),
	uom_qty			FLOAT,
	uom			VARCHAR(2),
	sched_process_id	INT		NULL,
	sched_operation_id	INT		NULL
	)

-- Determine what is not scheduled
CREATE TABLE #supply
	(
	sched_item_id		INT,
	done_datetime		DATETIME,
	uom_qty			FLOAT,
	uom			VARCHAR(2)
	)

CREATE TABLE #resource
	(
	sched_resource_id	INT,
	ave_flat_qty		FLOAT,
	ave_unit_qty		FLOAT,
	ave_pool_qty		FLOAT
	)

-- List of resource for which we have calendars
CREATE TABLE #resource_list
	(
	sched_resource_id	INT
	)

CREATE TABLE #calendar
	(
	sched_resource_id	INT,
	beg_datetime		DATETIME,
	end_datetime		DATETIME,
	pool_qty		FLOAT
	)
	
INSERT	#demand
	(
	sched_order_id,
	work_datetime,
	location,
	part_no,
	uom_qty,
	uom
	)
SELECT	SO.sched_order_id,
	getdate(),
	SO.location,
	SO.part_no,
	SO.uom_qty-IsNull((SELECT SUM(SOI.uom_qty) FROM dbo.sched_order_item SOI WHERE SOI.sched_order_id = SO.sched_order_id),0.0),
	SO.uom
FROM	dbo.sched_order SO
WHERE	SO.sched_id = @sched_id
AND	SO.source_flag = 'C'
AND	SO.order_no = @order_no
AND	SO.order_ext = @order_ext

-- Remove fullfilled demands
DELETE	#demand
WHERE	uom_qty <= 0.0

-- =================================================
-- Fill the gap between order and schedule
-- =================================================

-- Get deepest demand
SELECT	@demand_id = MAX(D.demand_id)
FROM	#demand D

-- While there still are demands
WHILE @demand_id IS NOT NULL
	BEGIN
	IF @debug_mode = 'Y'
		SELECT	*
		FROM	#demand

	-- Get demand specifics
	SELECT	@demand_order_id=D.sched_order_id,
		@demand_location=D.location,
		@demand_part_no=D.part_no,
		@demand_uom_qty=D.uom_qty,
		@demand_uom=D.uom,
		@demand_process_id=D.sched_process_id,
		@demand_operation_id=D.sched_operation_id
	FROM	#demand D
	WHERE	D.demand_id = @demand_id

	-- We have either been to this item before and have attempted to build
	-- it OR this is the first time.  If this is the second time we have
	-- been here, then check to make sure that we were able to get all of
	-- the materials. If we did not get all of the materials, we have
	-- failed to produce. If we did get all of the materials, try and
	-- schedule the resources for a time starting AFTER the last material
        -- was ready. If we can't schedule the resources, we have failed to
	-- produce. If we fail to produce for any reason, remove the processes
	-- and pass the failure up the line. If this is the first time that we
	-- have been here, attempt to build. If no build plan exists, attempt
	-- to purchase. If we successfully acquire inventory from either
	-- production or purchasing then satisfy the demand that pulled it.

	-- If we have not already attempted to build this...
	IF @demand_process_id IS NULL
		BEGIN
		-- Search for existing inventory
		SELECT	@uom_qty=@demand_uom_qty

		SELECT	@uom_qty=@uom_qty-IsNull(SUM(SI.uom_qty),0.0)
		FROM	dbo.sched_item SI
		WHERE	SI.sched_id = @sched_id
		AND	SI.location = @demand_location
		AND	SI.part_no = @demand_part_no
		AND	SI.done_datetime < getdate()

		SELECT	@uom_qty=@uom_qty+IsNull(SUM(SOI.uom_qty),0.0)
		FROM	dbo.sched_item SI,
			dbo.sched_order_item SOI
		WHERE	SI.sched_id = @sched_id
		AND	SI.location = @demand_location
		AND	SI.part_no = @demand_part_no
		AND	SI.done_datetime < getdate()
		AND	SOI.sched_item_id = SI.sched_item_id

		SELECT	@uom_qty=@uom_qty+IsNull(SUM(SOI.uom_qty),0.0)
		FROM	dbo.sched_item SI,
			dbo.sched_operation_item SOI
		WHERE	SI.sched_id = @sched_id
		AND	SI.location = @demand_location
		AND	SI.part_no = @demand_part_no
		AND	SI.done_datetime < getdate()
		AND	SOI.sched_item_id = SI.sched_item_id

		SELECT	@uom_qty=@uom_qty+IsNull(SUM(STI.uom_qty),0.0)
		FROM	dbo.sched_item SI,
			dbo.sched_transfer_item STI
		WHERE	SI.sched_id = @sched_id
		AND	SI.location = @demand_location
		AND	SI.part_no = @demand_part_no
		AND	SI.done_datetime < getdate()
		AND	STI.sched_item_id = SI.sched_item_id

		-- If we need to make/purchase something
		IF @uom_qty > 0.0
			BEGIN
			-- ...attempt to create a production
			EXECUTE fs_build_process_plan_atp @sched_id=@sched_id, @location=@demand_location, @asm_no=@demand_part_no, @asm_qty=@uom_qty, @sched_process_id=@demand_process_id OUT

			-- If there was a build plan...
			IF @demand_process_id IS NOT NULL
				BEGIN
				IF @debug_mode = 'Y'
					PRINT 'Created a process'

				-- ...mark the demand with the hopeful production
				UPDATE	#demand
				SET	sched_process_id = @demand_process_id
				FROM	#demand D
				WHERE	D.demand_id = @demand_id

				-- Place the process demands onto the stack
				INSERT	#demand
					(
					sched_order_id,
					work_datetime,
					location,
					part_no,
					uom_qty,
					uom,
					sched_operation_id
					)
				SELECT	@demand_order_id,
					getdate(),
					SO.location,
					SOP.part_no,
					SOP.ave_flat_qty
					+ ( SOP.ave_unit_qty
					  * @demand_uom_qty),
					SOP.uom,
					SO.sched_operation_id
				FROM	dbo.sched_operation SO,
					dbo.sched_operation_plan SOP
				WHERE	SO.sched_process_id = @demand_process_id
				AND	SOP.sched_operation_id = SO.sched_operation_id
				AND	SOP.status = 'P'
				AND	SOP.ave_unit_qty * @demand_uom_qty > 0.0
				END

			-- If there was not a build plan...
			ELSE	BEGIN
				IF @debug_mode = 'Y'
					PRINT 'Creating a purchase'

				-- ... detemine the item status and ...
				SELECT	@demand_status = IM.status
				FROM	dbo.inv_master IM
				WHERE	IM.part_no = @demand_part_no

				-- ... calculate the lead time (if not outsourced) so we can ...
				IF @demand_status = 'Q'
					SELECT	@demand_datetime = getdate()
				ELSE
					SELECT	@demand_datetime = dateadd(day,IL.lead_time,getdate())
					FROM	dbo.inv_list IL
					WHERE	IL.location = @demand_location
					AND	IL.part_no = @demand_part_no

				-- ... attempt to purchase the item.
				INSERT	dbo.sched_item
					(
					sched_id,		-- INT
					location,		-- VARCHAR(10)
					part_no,		-- VARCHAR(30)
					done_datetime,		-- DATETIME
					uom_qty,		-- FLOAT
					uom,			-- CHAR(2)
					source_flag		-- CHAR(1)
					)
				VALUES	(
					@sched_id,		-- sched_id		INT
					@demand_location,	-- location		VARCHAR(10)
					@demand_part_no,	-- part_no		VARCHAR(30)
					@demand_datetime,	-- done_datetime	DATETIME
					@uom_qty,		-- uom_qty		FLOAT
					@demand_uom,		-- uom			CHAR(2)
					'P'			-- source_flag		CHAR(1)
					)

				-- Grab the time-phased inventory id
				SELECT	@sched_item_id=@@identity
		
				INSERT	dbo.sched_purchase
					(
					sched_item_id,		-- INT
					lead_datetime		-- DATETIME
					)
				VALUES	(
					@sched_item_id,		-- sched_item_id	INT
					getdate()		-- lead_datetime	DATETIME
					)
				END
			END
		ELSE	IF @debug_mode = 'Y'
				BEGIN
				SELECT	@message='Filling from inventory ('+ltrim(str(@uom_qty))+')'
				PRINT	@message
				END

		END

	-- If we have attempted to build this item...
	ELSE	BEGIN
		IF @debug_mode = 'Y'
			PRINT 'Attempting to complete production plan'

		-- ... get the important information on the process, and ...
		SELECT	@process_unit=SP.process_unit,
			@process_unit_orig=SP.process_unit_orig		-- rev 1
		FROM	dbo.sched_process SP
		WHERE	SP.sched_process_id = @demand_process_id

		-- ... if the process is still on the schedule...
		IF @@rowcount > 0
			BEGIN
			-- ... it is now time to schedule the resources

			-- Set operation start time
			SELECT	@oper_datetime = getdate()
			
			-- Get first operation step
			SELECT	@operation_step=MIN(SO.operation_step)
			FROM	dbo.sched_operation SO
			WHERE	SO.sched_process_id = @demand_process_id

			WHILE @operation_step IS NOT NULL
				BEGIN
				IF @debug_mode = 'Y'
					PRINT 'Scheduling operation'

				-- Get the operation information
				SELECT	@plan_operation_id=SO.sched_operation_id,
					@plan_location=SO.location,
					@ave_time=SO.ave_flat_time+@process_unit*SO.ave_unit_time,
					@operation_type=SO.operation_type
				FROM	dbo.sched_operation SO
				WHERE	SO.sched_process_id = @demand_process_id
				AND	SO.operation_step = @operation_step

				-- Determine material completion date
				SELECT	@done_datetime=IsNull(MAX(SI.done_datetime),getdate())
				FROM	dbo.sched_operation_item SOI,
					dbo.sched_item SI
				WHERE	SOI.sched_operation_id = @plan_operation_id
				AND	SI.sched_item_id = SOI.sched_item_id

				-- If the material completion time is later than
				-- the earliest date/time for the operation
				-- adjust the operation start date/time
				IF @done_datetime > @oper_datetime
					SELECT	@oper_datetime = @done_datetime

				-- Is this an manufacturing operation?
				IF @operation_type='M'
					BEGIN
					IF @debug_mode = 'Y'
						PRINT 'Manufactured operation'

					-- Build list of resources
					DELETE	#resource
					INSERT	#resource
						(
						sched_resource_id,
						ave_flat_qty,
						ave_unit_qty,
						ave_pool_qty
						)
					SELECT	SR.sched_resource_id,
						SUM(SOP.ave_flat_qty),
						SUM(SOP.ave_unit_qty),
						SUM(SOP.ave_pool_qty)
					FROM	dbo.sched_operation_plan SOP,
						dbo.resource R,
						dbo.sched_resource SR
					WHERE	SOP.sched_operation_id = @plan_operation_id
					AND	SOP.status = 'R'
					AND	R.location = @plan_location
					AND	R.resource_code = SOP.part_no
					AND	SR.sched_id = @sched_id
					AND	SR.resource_id = R.resource_id
					GROUP BY sched_resource_id

					-- If we could not find all of the resources, we have failed
					IF ((SELECT COUNT(*) FROM #resource) <> (SELECT COUNT(DISTINCT SOP.part_no) FROM dbo.sched_operation_plan SOP WHERE SOP.sched_operation_id = @plan_operation_id AND SOP.status = 'R'))
						-- We have failed to complete the process
						BREAK

					-- Make sure every resource has a calendar
					SELECT	@sched_resource_id=MIN(R.sched_resource_id)
					FROM	#resource R
					WHERE	NOT EXISTS (SELECT * FROM #resource_list RL WHERE RL.sched_resource_id = R.sched_resource_id)

					WHILE @sched_resource_id IS NOT NULL
						BEGIN
						-- Build resource calendar
						INSERT	#calendar(sched_resource_id,beg_datetime,end_datetime,pool_qty)
						EXECUTE fs_build_resource_calendar @sched_resource_id=@sched_resource_id,@beg_date=@bcal_datetime,@end_date=@ecal_datetime

						-- Calendar is built, add to the list
						INSERT	#resource_list(sched_resource_id)
						VALUES	(@sched_resource_id)

						-- Next calendar needed
						SELECT	@sched_resource_id=MIN(R.sched_resource_id)
						FROM	#resource R
						WHERE	NOT EXISTS (SELECT * FROM #resource_list RL WHERE RL.sched_resource_id = R.sched_resource_id)
						END

					SELECT	@work_datetime=@oper_datetime

					-- Now, move through every available period and find a time when
					-- all of the resource are available with the appropriate pool
					-- size.

					-- While we have not moved to the end of the schedule
					WHILE @work_datetime IS NOT NULL
						BEGIN
						-- We have a potential candidate... 
						-- Test for full availability for all resources on this date
						SELECT	@sched_resource_id=MIN(R.sched_resource_id)
						FROM	#resource R
						WHERE	NOT EXISTS (	SELECT	*
									FROM	#calendar C
									WHERE	C.sched_resource_id = R.sched_resource_id
									AND	C.beg_datetime <= @work_datetime
									AND	C.end_datetime > @work_datetime
									AND	C.pool_qty >= R.ave_pool_qty )

						-- If we found one that fails...
						IF @sched_resource_id IS NOT NULL
							BEGIN
							-- Find the next time that this one will be ok...
							SELECT	@work_datetime=MIN(C.beg_datetime)
							FROM	#resource R,
								#calendar C
							WHERE	R.sched_resource_id = @sched_resource_id
							AND	C.sched_resource_id = @sched_resource_id
							AND	C.beg_datetime > @work_datetime
							AND	C.end_datetime > @work_datetime
							AND	C.pool_qty >= R.ave_pool_qty

							-- If we found a spot, test it
							CONTINUE
							END

						-- Determine when availability will end
						SELECT	@stop_datetime=MIN(C.beg_datetime)
						FROM	#resource R,
							#calendar C
						WHERE	C.sched_resource_id = R.sched_resource_id
						AND	C.beg_datetime > @work_datetime
						AND	C.pool_qty < R.ave_pool_qty

						-- Check each resource to see if they have enough time
						-- we will also determine the common start time

						-- Prime to find the best start time
						SELECT	@done_datetime = @work_datetime

						SELECT	@sched_resource_id=MIN(R.sched_resource_id)
						FROM	#resource R

						WHILE @sched_resource_id IS NOT NULL
							BEGIN
							-- Determine when this span starts
							SELECT	@beg_datetime=C.beg_datetime,
								@run_time=@ave_time+datediff(minute,C.beg_datetime,@work_datetime) / 60.0
							FROM	#calendar C
							WHERE	C.sched_resource_id = @sched_resource_id
							AND	C.beg_datetime <= @work_datetime
							AND	C.end_datetime > @work_datetime

							IF @@rowcount <> 1
								RaisError 69999 'Error processing calendars'

							-- While there is time to pass...
							WHILE @run_time > 0.0
								BEGIN
								-- Get the end time
								SELECT  @end_datetime = C.end_datetime
								FROM    #calendar C
								WHERE   C.beg_datetime = @beg_datetime

								-- Calculate the time spent here
								SELECT  @run_time = @run_time - datediff(minute,@beg_datetime,@end_datetime) / 60.0

								-- Get the next start time
								SELECT  @beg_datetime=MIN(C.beg_datetime)
								FROM    #calendar C
								WHERE   C.beg_datetime > @end_datetime

								-- If we are at the end, this is not the best place to stop
								IF @beg_datetime >= @stop_datetime
									BREAK
								END

							-- Did we finish prematurely?
							IF @run_time > 0.0
								BREAK

							-- Correct for over-calculation
							IF @run_time < 0.0
								SELECT  @end_datetime = dateadd(minute,@run_time * 60,@end_datetime)

							-- Capture official commencement/completion time
							IF @work_datetime > @oper_datetime
								SELECT	@oper_datetime=@work_datetime
							IF @done_datetime < @end_datetime
								SELECT	@done_datetime = @end_datetime

							-- Get next resource to check
							SELECT	@sched_resource_id=MIN(R.sched_resource_id)
							FROM	#resource R
							WHERE	R.sched_resource_id > @sched_resource_id
							END

						-- If we got here but still have a valid @sched_resource_id,
						-- then we exitted the routine because we found something that
						-- we did not like... there we must continue the search
						IF @sched_resource_id IS NOT NULL
							BEGIN
							SELECT	@work_datetime=@stop_datetime
							CONTINUE
							END

						-- We have a good one
						BREAK
						END

					-- Did the proceeding search succeed?
					IF @work_datetime IS NULL
						-- NO!!! We failed... stop scheduling this process
						BREAK

					-- Mark the operation as scheduled 
					UPDATE	dbo.sched_operation
					SET	operation_status = 'S',
						work_datetime = @work_datetime,
						done_datetime = @done_datetime
					FROM	dbo.sched_operation SO
					WHERE	SO.sched_process_id = @demand_process_id
					AND	SO.operation_step = @operation_step

					-- Remove availability from calendar
					SELECT	@sched_resource_id=MIN(R.sched_resource_id)
					FROM	#resource R

					WHILE @sched_resource_id IS NOT NULL
						BEGIN
						-- Get the pool quantity
						SELECT	@ave_pool_qty=R.ave_pool_qty
						FROM	#resource R
						WHERE	R.sched_resource_id = @sched_resource_id

						-- Assign the resources
						INSERT	dbo.sched_operation_resource(sched_operation_id,sched_resource_id,setup_datetime,pool_qty)
						VALUES	(@plan_operation_id,@sched_resource_id,@work_datetime,@ave_pool_qty)

						-- Break up the start span into included and excluded
						INSERT	#calendar(sched_resource_id,beg_datetime,end_datetime,pool_qty)
						SELECT	C.sched_resource_id,C.beg_datetime,@work_datetime,C.pool_qty
						FROM	#calendar C
						WHERE	C.sched_resource_id = @sched_resource_id
						AND	C.beg_datetime < @work_datetime
						AND	C.end_datetime > @work_datetime

						INSERT	#calendar(sched_resource_id,beg_datetime,end_datetime,pool_qty)
						SELECT	C.sched_resource_id,@work_datetime,C.end_datetime,C.pool_qty
						FROM	#calendar C
						WHERE	C.sched_resource_id = @sched_resource_id
						AND	C.beg_datetime < @work_datetime
						AND	C.end_datetime > @work_datetime

						DELETE	#calendar
						FROM	#calendar C
						WHERE	C.sched_resource_id = @sched_resource_id
						AND	C.beg_datetime < @work_datetime
						AND	C.end_datetime > @work_datetime

						-- Break up the finish span into included and excluded
						INSERT	#calendar(sched_resource_id,beg_datetime,end_datetime,pool_qty)
						SELECT	C.sched_resource_id,C.beg_datetime,@done_datetime,C.pool_qty
						FROM	#calendar C
						WHERE	C.sched_resource_id = @sched_resource_id
						AND	C.beg_datetime < @done_datetime
						AND	C.end_datetime > @done_datetime

						INSERT	#calendar(sched_resource_id,beg_datetime,end_datetime,pool_qty)
						SELECT	C.sched_resource_id,@done_datetime,C.end_datetime,C.pool_qty
						FROM	#calendar C
						WHERE	C.sched_resource_id = @sched_resource_id
						AND	C.beg_datetime < @done_datetime
						AND	C.end_datetime > @done_datetime

						DELETE	#calendar
						FROM	#calendar C
						WHERE	C.sched_resource_id = @sched_resource_id
						AND	C.beg_datetime < @done_datetime
						AND	C.end_datetime > @done_datetime

						-- Subtract out all pool quantity
						UPDATE	#calendar
						SET	pool_qty = pool_qty - @ave_pool_qty
						FROM	#calendar C
						WHERE	C.sched_resource_id = @sched_resource_id
						AND	C.end_datetime > @work_datetime
						AND	C.beg_datetime < @done_datetime

						-- Get next resource to check
						SELECT	@sched_resource_id=MIN(R.sched_resource_id)
						FROM	#resource R
						WHERE	R.sched_resource_id > @sched_resource_id
						END
					
					END

				-- OR is this an outsourcing operation
				ELSE IF @operation_type = 'O'
					BEGIN
					IF @debug_mode = 'Y'
						PRINT 'Outsourced operation'

					-- Determine operation date/time




					SELECT	@done_datetime = dateadd(hour,@ave_time,@oper_datetime)

					-- Mark the operation as scheduled
					UPDATE	dbo.sched_operation
					SET	operation_status = 'S',
						work_datetime = @oper_datetime,
						done_datetime = @done_datetime
					FROM	dbo.sched_operation SO
					WHERE	SO.sched_process_id = @demand_process_id
					AND	SO.operation_step = @operation_step
					END

				-- Calculate the earliest start time of the next operation
-- (PCL) Need to develop algorithm for optimal start time
				SELECT	@oper_datetime = @done_datetime

				-- Get next operation step
				SELECT	@operation_step=MIN(SO.operation_step)
				FROM	dbo.sched_operation SO
				WHERE	SO.sched_process_id = @demand_process_id
				AND	SO.operation_step > @operation_step
				END

			-- Double check... did we schedule all operations?
			IF @operation_step IS NULL
				BEGIN
				-- NOTE: We now have the materials and the resources scheduled.

				-- Create the products for this process
				INSERT	dbo.sched_item
					(
					sched_id,		-- INT
					location,		-- VARCHAR(10)
					part_no,		-- VARCHAR(30)
					done_datetime,		-- DATETIME
					uom_qty,		-- FLOAT
					uom,			-- CHAR(2)
					source_flag,		-- CHAR(1)
					sched_process_id	-- INT		NULL
					)
				SELECT	@sched_id,		-- sched_id		INT
					SPP.location,		-- location		VARCHAR(10)
					SPP.part_no,		-- part_no		VARCHAR(30)
					@done_datetime,		-- done_datetime	DATETIME
					SPP.uom_qty		-- uom_qty		FLOAT
					* @process_unit_orig,					-- rev 1
					SPP.uom,		-- uom			CHAR(2)
					'M',			-- source_flag		CHAR(1)
					@demand_process_id	-- sched_process_id	INT		NULL
				FROM	dbo.sched_process_product SPP
				WHERE	SPP.sched_process_id = @demand_process_id

				-- One of the products had a demand... get the demanded item
				SELECT	@sched_item_id=SI.sched_item_id
				FROM	dbo.sched_item SI
				WHERE	SI.sched_id = @sched_id
				AND	SI.location = @demand_location
				AND	SI.part_no = @demand_part_no
				AND	SI.sched_process_id = @demand_process_id
				END

			-- If we attempted and failed to schedule all resources, then ...
			-- ... this demand could not be met. Pass on problem
			ELSE	EXECUTE fs_release_inventory @sched_process_id=@demand_process_id
			END

		-- If we attempted and failed to get all of the materials, then ...
		-- ... this demand could not be met. Pass on problem
		ELSE	EXECUTE fs_release_inventory @sched_process_id=@demand_process_id
		END

	-- Are there any new dependencies on this demand?
	IF NOT EXISTS(SELECT * FROM #demand D WHERE D.demand_id > @demand_id)
		BEGIN
		IF @debug_mode = 'Y'
			PRINT 'Assigning materials'

		-- Get supply
		INSERT	#supply
			(
			sched_item_id,
			done_datetime,
			uom_qty,
			uom
			)
		SELECT	SI.sched_item_id,
			SI.done_datetime,
			SI.uom_qty,
			SI.uom
		FROM	dbo.sched_item SI
		WHERE	SI.sched_id = @sched_id
		AND	SI.location = @demand_location
		AND	SI.part_no = @demand_part_no

		-- Remove existing order demand
		UPDATE	#supply
		SET	uom_qty = S.uom_qty - IsNull((	SELECT	SUM(SOI.uom_qty)
							FROM	dbo.sched_order_item SOI
							WHERE	SOI.sched_item_id = S.sched_item_id),0.0)
		FROM	#supply S

		-- Remove existing operation consumation
		UPDATE	#supply
		SET	uom_qty = S.uom_qty - IsNull((	SELECT	SUM(SOI.uom_qty)
							FROM	dbo.sched_operation_item SOI
							WHERE	SOI.sched_item_id = S.sched_item_id),0.0)
		FROM	#supply S

		-- Remove existing transfer assignments
		UPDATE	#supply
		SET	uom_qty = S.uom_qty - IsNull((	SELECT	SUM(STI.uom_qty)
							FROM	dbo.sched_transfer_item STI
							WHERE	STI.sched_item_id = S.sched_item_id),0.0)
		FROM	#supply S

		-- Remove all supply that is not in surplus
		DELETE	#supply
		FROM	#supply S
		WHERE	S.uom_qty <= 0.0

		-- Determine how much we are in excess
		SELECT	@surplus_uom_qty=SUM(S.uom_qty)-@demand_uom_qty
		FROM	#supply S

		-- If we have too much, release it
		WHILE @surplus_uom_qty > 0.0
			BEGIN
			IF @debug_mode='Y'
				PRINT 'Letting material go'

			-- Detemine the latest date
			SELECT	@supply_datetime=MAX(S.done_datetime)
			FROM	#supply S

			-- Uniquely select a supply at the latest date
			SELECT	@supply_item_id=MAX(S.sched_item_id)
			FROM	#supply S
			WHERE	S.done_datetime = @supply_datetime

			-- Calculate the surplus less this item
			SELECT	@surplus_uom_qty=@surplus_uom_qty-S.uom_qty
			FROM	#supply S
			WHERE	S.sched_item_id = @supply_item_id

			-- If this item fits in our mouth, then ...
			IF @surplus_uom_qty >= 0.0
				BEGIN
				-- ... eat whole item...
				DELETE	#supply
				FROM	#supply S
				WHERE	S.sched_item_id = @supply_item_id
				END
			ELSE
				BEGIN
				-- ... otherwise, just take a nibble out of it...
				UPDATE	#supply
				SET	uom_qty = -@surplus_uom_qty
				FROM	#supply S
				WHERE	S.sched_item_id = @supply_item_id

				-- ... and end a perfect meal with a full stomach
				SELECT	@surplus_uom_qty = 0.0
				END
			END

		-- Assign supply to demand order
		IF @demand_operation_id IS NULL
			BEGIN
			IF @debug_mode='Y' PRINT 'Assigning items to the order'

			INSERT	dbo.sched_order_item(sched_order_id,sched_item_id,uom_qty,uom)
			SELECT	@demand_order_id,S.sched_item_id,S.uom_qty,S.uom
			FROM	#supply S
			END
		-- OR assign supply to demand operation
		ELSE IF @surplus_uom_qty >= 0.0
			BEGIN
			IF @debug_mode='Y' PRINT 'Assigning items to the operation'

			INSERT	dbo.sched_operation_item(sched_operation_id,sched_item_id,uom_qty,uom)
			SELECT	@demand_operation_id,S.sched_item_id,S.uom_qty,S.uom
			FROM	#supply S
			END
		-- OR if there was not enough, delete the process
		ELSE	BEGIN
			IF @debug_mode='Y' PRINT 'Not enough materials... rolling back'

			-- Release all conntected processes
			IF @demand_process_id IS NOT NULL
				EXECUTE	fs_release_inventory @sched_process_id=@demand_process_id

			-- Remove all material (non-production) demands
			DELETE	#demand
			FROM	#demand D
			WHERE	D.sched_order_id = @demand_order_id
			AND	D.sched_process_id IS NULL

			-- Get first process connected to this order
			SELECT	@demand_process_id=MIN(D.sched_process_id)
			FROM	#demand D
			WHERE	D.sched_order_id = @demand_order_id

			WHILE @demand_process_id IS NOT NULL
				BEGIN
				-- Remove demand from list
				DELETE	#demand
				FROM	#demand D
				WHERE	D.sched_order_id = @demand_order_id
				AND	D.sched_process_id = @demand_process_id

				-- Remove all production found connected to this order
				EXECUTE	fs_release_inventory @sched_process_id=@demand_process_id

				-- Get next process connected to this order
				SELECT	@demand_process_id=MIN(D.sched_process_id)
				FROM	#demand D
				WHERE	D.sched_order_id = @demand_order_id
				END
			END

		-- Remove this demand
		DELETE	#demand
		FROM	#demand D
		WHERE	D.demand_id = @demand_id

		IF NOT EXISTS(SELECT * FROM #supply S WHERE S.sched_item_id = @sched_item_id)
			EXECUTE	fs_release_inventory @sched_item_id=@sched_item_id

		-- Clear supply table for the next generation
		DELETE	#supply
		END

	-- Get deepest demand
	SELECT	@demand_id = MAX(D.demand_id)
	FROM	#demand D
	END

-- =================================================
-- Return scheduled capable-to-promise
-- =================================================

SELECT	SO.order_no,
	SO.order_ext,
	SO.order_line,
	SO.part_no,
	IM.description,
	SI.done_datetime,
	SOI.uom_qty,
	SO.uom_qty,
	SOI.uom
FROM	dbo.sched_order SO,
	dbo.sched_order_item SOI,
	dbo.sched_item SI,
	dbo.inv_master IM
WHERE	SO.sched_id = @sched_id
AND	SO.order_no = @order_no
AND	SO.order_ext = @order_ext
AND	SO.source_flag = 'C'
AND	SOI.sched_order_id = SO.sched_order_id
AND	SI.sched_id = @sched_id
AND	SI.sched_item_id = SOI.sched_item_id
AND	IM.part_no = SO.part_no

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_promise_order] TO [public]
GO
